using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Authentication;

public interface IJwtTokenService
{
    (string Token, int ExpiresIn) GenerateToken(User user, IEnumerable<string> roles);
}

public class JwtTokenService : IJwtTokenService
{
    private readonly IConfiguration _configuration;

    public JwtTokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public (string Token, int ExpiresIn) GenerateToken(User user, IEnumerable<string> roles)
    {
        var secretKey = Environment.GetEnvironmentVariable("JWT_KEY")
            ?? _configuration["Jwt:Key"]
            ?? throw new InvalidOperationException("JWT_KEY must be configured.");
        var issuer = Environment.GetEnvironmentVariable("JWT_ISSUER")
            ?? _configuration["Jwt:Issuer"]
            ?? throw new InvalidOperationException("JWT_ISSUER must be configured.");
        var audience = Environment.GetEnvironmentVariable("JWT_AUDIENCE")
            ?? _configuration["Jwt:Audience"]
            ?? throw new InvalidOperationException("JWT_AUDIENCE must be configured.");
        
        var expiryMinutesStr = _configuration["Jwt:ExpireMinutes"] ?? "60";
        if (!int.TryParse(expiryMinutesStr, out var expiryMinutes))
        {
            expiryMinutes = 60;
        }

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new("sv", user.SecurityVersion.ToString()),
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.Email, user.Email)
        };

        foreach (var role in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var expires = DateTime.UtcNow.AddMinutes(expiryMinutes);

        var tokenDescriptor = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: expires,
            signingCredentials: creds
        );

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.WriteToken(tokenDescriptor);

        return (token, expiryMinutes * 60);
    }
}
