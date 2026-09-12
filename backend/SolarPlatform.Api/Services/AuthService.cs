using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Authentication;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

public interface IAuthService
{
    Task<AuthResponseDto> RegisterAsync(RegisterRequestDto request);
    Task<AuthResponseDto> LoginAsync(LoginRequestDto request);
    Task<UserDto?> GetCurrentUserAsync(Guid userId);
}

public class AuthService : IAuthService
{
    private readonly AppDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        AppDbContext dbContext,
        IPasswordHasher passwordHasher,
        IJwtTokenService jwtTokenService,
        ILogger<AuthService> logger)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
        _jwtTokenService = jwtTokenService;
        _logger = logger;
    }

    public async Task<AuthResponseDto> RegisterAsync(RegisterRequestDto request)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        var existingUser = await _dbContext.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail);
        if (existingUser)
        {
            throw new InvalidOperationException("A user with this email already exists.");
        }

        // Public registration is homeowner-only. Privileged role assignment is administrative.
        var role = await _dbContext.Roles.FirstOrDefaultAsync(r => r.Name == RoleConstants.Homeowner);
        if (role == null)
        {
            role = await _dbContext.Roles.FirstOrDefaultAsync(r => r.Name == RoleConstants.Homeowner);
            if (role == null)
            {
                role = new Role { Name = RoleConstants.Homeowner, Description = "Default Homeowner Role" };
                _dbContext.Roles.Add(role);
                await _dbContext.SaveChangesAsync();
            }
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = normalizedEmail,
            FullName = request.FullName.Trim(),
            PhoneNumber = request.PhoneNumber?.Trim(),
            PasswordHash = _passwordHasher.HashPassword(request.Password),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        user.UserRoles.Add(new UserRole
        {
            UserId = user.Id,
            RoleId = role.Id
        });

        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();

        var roles = new List<string> { role.Name };
        var (token, expiresIn) = _jwtTokenService.GenerateToken(user, roles);

        _logger.LogInformation("New user registered: {Email} with role {Role}", user.Email, role.Name);

        return new AuthResponseDto
        {
            Token = token,
            ExpiresIn = expiresIn,
            User = new UserDto
            {
                Id = user.Id,
                Email = user.Email,
                FullName = user.FullName,
                PhoneNumber = user.PhoneNumber,
                Roles = roles,
                CreatedAt = user.CreatedAt
            }
        };
    }

    public async Task<AuthResponseDto> LoginAsync(LoginRequestDto request)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        var user = await _dbContext.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail);

        if (user == null || !_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            _logger.LogWarning("Failed login attempt for email: {Email}", request.Email);
            throw new UnauthorizedAccessException("Invalid email or password.");
        }

        if (!user.IsActive)
        {
            _logger.LogWarning("Inactive user attempted login: {Email}", request.Email);
            throw new UnauthorizedAccessException("User account is inactive.");
        }

        var roles = user.UserRoles.Select(ur => ur.Role.Name).ToList();
        var (token, expiresIn) = _jwtTokenService.GenerateToken(user, roles);

        _logger.LogInformation("User logged in successfully: {Email}", user.Email);

        return new AuthResponseDto
        {
            Token = token,
            ExpiresIn = expiresIn,
            User = new UserDto
            {
                Id = user.Id,
                Email = user.Email,
                FullName = user.FullName,
                PhoneNumber = user.PhoneNumber,
                Roles = roles,
                CreatedAt = user.CreatedAt
            }
        };
    }

    public async Task<UserDto?> GetCurrentUserAsync(Guid userId)
    {
        var user = await _dbContext.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.Id == userId && u.IsActive);

        if (user == null)
            return null;

        return new UserDto
        {
            Id = user.Id,
            Email = user.Email,
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            Roles = user.UserRoles.Select(ur => ur.Role.Name).ToList(),
            CreatedAt = user.CreatedAt
        };
    }
}
