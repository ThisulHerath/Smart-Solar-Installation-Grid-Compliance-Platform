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
        var secretKey = _configuration["Jwt:Key"] 
            ?? Environment.GetEnvironmentVariable("JWT_KEY") 
            ?? "SmartSolarSuperSecretKeyForDevelopmentAndJwtAuthentication2026!";
        var issuer = _configuration["Jwt:Issuer"] 
            ?? Environment.GetEnvironmentVariable("JWT_ISSUER") 
            ?? "SmartSolarPlatform";
        var audience = _configuration["Jwt:Audience"] 
            ?? Environment.GetEnvironmentVariable("JWT_AUDIENCE") 
            ?? "SmartSolarClients";
        
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
