using System.Text;
using System.Security.Claims;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using System.Text.Json.Serialization;
using DotNetEnv;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SolarPlatform.Api.Authentication;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Middleware;
using SolarPlatform.Api.Services;

var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsDevelopment())
{
    var envFilePath = Path.GetFullPath(Path.Combine(builder.Environment.ContentRootPath, "..", "..", ".env"));
    if (File.Exists(envFilePath))
    {
        Env.Load(envFilePath);
    }
}

// 1. Database Configuration (Neon Managed PostgreSQL)
var connectionString = Environment.GetEnvironmentVariable("DATABASE_CONNECTION_STRING")
    ?? builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<AppDbContext>(options =>
{
    if (!string.IsNullOrWhiteSpace(connectionString) && !connectionString.Contains("YOUR_NEON_PASSWORD"))
    {
        options.UseNpgsql(connectionString);
    }
    else
    {
        if (!builder.Environment.IsDevelopment() && !builder.Environment.IsEnvironment("Testing"))
            throw new InvalidOperationException("Configure PostgreSQL before starting a production API.");
        // Safe in-memory fallback for initial local development/testing when Neon credentials are not yet set in environment
        options.UseInMemoryDatabase("SmartSolarDevDb");
    }
});

// 2. Authentication & Authorization
var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")
    ?? builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("JWT_KEY must be configured.");
var jwtIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER")
    ?? builder.Configuration["Jwt:Issuer"]
    ?? throw new InvalidOperationException("JWT_ISSUER must be configured.");
var jwtAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE")
    ?? builder.Configuration["Jwt:Audience"]
    ?? throw new InvalidOperationException("JWT_AUDIENCE must be configured.");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false; // Allow local dev HTTP
    options.SaveToken = true;
    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async context =>
        {
            var id = context.Principal?.FindFirstValue(ClaimTypes.NameIdentifier);
            var version = context.Principal?.FindFirstValue("sv");
            var db = context.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
            if (!Guid.TryParse(id, out var userId) || !int.TryParse(version, out var securityVersion) ||
                !await db.Users.AsNoTracking().AnyAsync(u => u.Id == userId && u.IsActive && u.SecurityVersion == securityVersion))
                context.Fail("This session has ended. Please sign in again.");
        }
    };
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        ClockSkew = TimeSpan.FromMinutes(1)
    };
});

builder.Services.AddAuthorization();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("auth", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 20, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
});

// 3. Application Services
builder.Services.AddScoped<IPasswordHasher, PasswordHasher>();
builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddScoped<IOtpEmailSender, OtpEmailSender>();
builder.Services.AddScoped<EmailVerificationService>();
builder.Services.AddHostedService<EmailChallengeCleanup>();
builder.Services.AddScoped<ISurveyService, SurveyService>();
builder.Services.AddScoped<IFileStorageService, LocalFileStorageService>();
builder.Services.AddScoped<IFieldJobService, FieldJobService>();
builder.Services.AddScoped<IProposalService, ProposalService>();
builder.Services.AddScoped<InventoryService>();

// 4. Agentic AI Service Client
var agenticAiBaseUrl = Environment.GetEnvironmentVariable("AGENTIC_AI_BASE_URL")
    ?? builder.Configuration["AgenticAi:BaseUrl"]
    ?? "http://localhost:8000";
builder.Services.AddHttpClient<IEquipmentPricingClient, EquipmentPricingClient>(client =>
{
    client.BaseAddress = new Uri(agenticAiBaseUrl);
    client.Timeout = TimeSpan.FromSeconds(20);
});

builder.Services.AddHttpClient<IAgenticAiService, AgenticAiService>(client =>
{
    client.BaseAddress = new Uri(agenticAiBaseUrl);
    client.Timeout = TimeSpan.FromSeconds(15);
});

// 5. CORS Configuration (React Web App and Mobile Client support)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
          var configuredOrigins = (Environment.GetEnvironmentVariable("CORS_ALLOWED_ORIGINS") ?? "")
              .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
          policy.SetIsOriginAllowed(origin => configuredOrigins.Contains(origin, StringComparer.OrdinalIgnoreCase)
              || (builder.Environment.IsDevelopment() &&
              Uri.TryCreate(origin, UriKind.Absolute, out var uri)
              && (uri.Host == "localhost" || uri.Host == "127.0.0.1")))
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// 6. Controllers & Swagger/OpenAPI
builder.Services.AddControllers()
    .AddJsonOptions(options =>
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Smart Solar Platform API",
        Version = "v1",
        Description = "Authoritative REST API for the Smart Solar Installation & Grid Compliance Platform (SE3090 Assignment 1)"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Paste the JWT token without quotes.",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// Seed In-Memory Database if in fallback mode
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    if (context.Database.IsInMemory())
    {
        context.Database.EnsureCreated();
    }
}

// Pipeline Configuration
app.UseMiddleware<ExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment() || Environment.GetEnvironmentVariable("ENABLE_SWAGGER") == "true")
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Smart Solar Platform API v1");
        c.RoutePrefix = "swagger";
    });
}

app.UseCors("AllowAll");
app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.MapControllers();

app.Run();

// Make Program visible for integration tests
public partial class Program { }
