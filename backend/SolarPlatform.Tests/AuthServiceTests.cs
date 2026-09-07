using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using SolarPlatform.Api.Authentication;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Tests;

public class AuthServiceTests
{
    private readonly AppDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;
    private readonly Mock<IJwtTokenService> _jwtTokenServiceMock;
    private readonly Mock<ILogger<AuthService>> _loggerMock;
    private readonly AuthService _authService;

    public AuthServiceTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _dbContext = new AppDbContext(options);
        _passwordHasher = new PasswordHasher();
        _jwtTokenServiceMock = new Mock<IJwtTokenService>();
        _loggerMock = new Mock<ILogger<AuthService>>();

        _jwtTokenServiceMock
            .Setup(j => j.GenerateToken(It.IsAny<User>(), It.IsAny<IEnumerable<string>>()))
            .Returns(("mock.jwt.token", 3600));

        _authService = new AuthService(_dbContext, _passwordHasher, _jwtTokenServiceMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task RegisterAsync_ValidRequest_CreatesUserAndReturnsToken()
    {
        var request = new RegisterRequestDto
        {
            Email = "newuser@smartsolar.local",
            Password = "SecurePassword@123",
            FullName = "New User",
            Role = RoleConstants.Homeowner
        };

        var result = await _authService.RegisterAsync(request);

        Assert.NotNull(result);
        Assert.Equal("mock.jwt.token", result.Token);
        Assert.Equal("newuser@smartsolar.local", result.User.Email);
        Assert.Contains(RoleConstants.Homeowner, result.User.Roles);

        var savedUser = await _dbContext.Users.FirstOrDefaultAsync(u => u.Email == "newuser@smartsolar.local");
        Assert.NotNull(savedUser);
        Assert.True(_passwordHasher.VerifyPassword("SecurePassword@123", savedUser.PasswordHash));
    }

    [Fact]
    public async Task RegisterAsync_DuplicateEmail_ThrowsInvalidOperationException()
    {
        var request = new RegisterRequestDto
        {
            Email = "dup@smartsolar.local",
            Password = "Password@123",
            FullName = "Duplicate Test",
            Role = RoleConstants.Homeowner
        };

        await _authService.RegisterAsync(request);

        await Assert.ThrowsAsync<InvalidOperationException>(() => _authService.RegisterAsync(request));
    }

    [Fact]
    public async Task LoginAsync_ValidCredentials_ReturnsTokenAndUserInfo()
    {
        var registerRequest = new RegisterRequestDto
        {
            Email = "loginuser@smartsolar.local",
            Password = "ValidPassword@123",
            FullName = "Login User",
            Role = RoleConstants.SeniorEngineer
        };
        await _authService.RegisterAsync(registerRequest);

        var loginRequest = new LoginRequestDto
        {
            Email = "loginuser@smartsolar.local",
            Password = "ValidPassword@123"
        };

        var result = await _authService.LoginAsync(loginRequest);

        Assert.NotNull(result);
        Assert.Equal("mock.jwt.token", result.Token);
        Assert.Equal("loginuser@smartsolar.local", result.User.Email);
    }

    [Fact]
    public async Task LoginAsync_InvalidPassword_ThrowsUnauthorizedAccessException()
    {
        var registerRequest = new RegisterRequestDto
        {
            Email = "user2@smartsolar.local",
            Password = "CorrectPassword@123",
            FullName = "User Two",
            Role = RoleConstants.FieldTechnician
        };
        await _authService.RegisterAsync(registerRequest);

        var loginRequest = new LoginRequestDto
        {
            Email = "user2@smartsolar.local",
            Password = "WrongPassword@123"
        };

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() => _authService.LoginAsync(loginRequest));
    }
}
