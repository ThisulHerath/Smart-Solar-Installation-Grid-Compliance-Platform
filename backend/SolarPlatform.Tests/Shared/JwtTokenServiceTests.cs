using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.Extensions.Configuration;
using SolarPlatform.Api.Authentication;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Tests;

public class JwtTokenServiceTests
{
    private readonly JwtTokenService _tokenService;

    public JwtTokenServiceTests()
    {
        var configValues = new Dictionary<string, string?>
        {
            { "Jwt:Key", "TestSecretKeyForJwtTokenGenerationMustBeLongEnough123!" },
            { "Jwt:Issuer", "TestIssuer" },
            { "Jwt:Audience", "TestAudience" },
            { "Jwt:ExpireMinutes", "30" }
        };

        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(configValues)
            .Build();

        _tokenService = new JwtTokenService(configuration);
    }

    [Fact]
    public void GenerateToken_ReturnsValidJwtWithClaims()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "jwt@smartsolar.local",
            FullName = "JWT Test User"
        };
        var roles = new[] { RoleConstants.Administrator, RoleConstants.SeniorEngineer };

        var (token, expiresIn) = _tokenService.GenerateToken(user, roles);

        Assert.NotEmpty(token);
        Assert.Equal(1800, expiresIn);

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(token);

        Assert.Equal("TestIssuer", jwt.Issuer);
        Assert.Contains("TestAudience", jwt.Audiences);
        
        var emailClaim = jwt.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Email)?.Value;
        Assert.Equal("jwt@smartsolar.local", emailClaim);

        var roleClaims = jwt.Claims.Where(c => c.Type == ClaimTypes.Role).Select(c => c.Value).ToList();
        Assert.Contains(RoleConstants.Administrator, roleClaims);
        Assert.Contains(RoleConstants.SeniorEngineer, roleClaims);
    }
}
