using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Authentication;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Services;

public class EmailVerificationService(AppDbContext db, IPasswordHasher hasher, IJwtTokenService tokens,
    IOtpEmailSender sender, IConfiguration config, TimeProvider clock)
{
    public const string Registration = "registration", PasswordChange = "password change", Deletion = "account deletion";
    private DateTime Now => clock.GetUtcNow().UtcDateTime;

    public async Task<EmailChallengeResponse> RequestRegistrationAsync(RegisterRequestDto request)
    {
        ValidatePassword(request.Password);
        var email = request.Email.Trim().ToLowerInvariant();
        if (await db.Users.AnyAsync(u => u.Email == email))
            throw new InvalidOperationException("This email is already registered. Please sign in.");
        if (string.IsNullOrWhiteSpace(request.FullName) || request.FullName.Trim().Length > 255 || email.Length > 254 || request.PhoneNumber?.Length > 50)
            throw new ArgumentException("Check your name, email and phone number.");
        return await IssueAsync(new EmailChallenge { Email = email, Purpose = Registration,
            PasswordHash = hasher.HashPassword(request.Password), FullName = request.FullName.Trim(), PhoneNumber = request.PhoneNumber?.Trim() });
    }

    public async Task<EmailChallengeResponse> RequestAccountActionAsync(Guid userId, string purpose, string? newPassword = null)
    {
        var user = await ActiveUserAsync(userId);
        if (purpose != PasswordChange && purpose != Deletion) throw new ArgumentException("Invalid action.");
        if (purpose == PasswordChange) ValidatePassword(newPassword ?? "");
        return await IssueAsync(new EmailChallenge { Email = user.Email, Purpose = purpose, UserId = user.Id,
            UserVersion = user.SecurityVersion, PasswordHash = purpose == PasswordChange ? hasher.HashPassword(newPassword!) : null });
    }

    private async Task<EmailChallengeResponse> IssueAsync(EmailChallenge challenge)
    {
        await using var transaction = db.Database.IsRelational()
            ? await db.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable) : null;
        var now = Now;
        var recent = await db.EmailChallenges.Where(c => c.Email == challenge.Email && c.CreatedAt > now.AddHours(-1)).ToListAsync();
        if (recent.Any(c => c.CreatedAt > now.AddSeconds(-60)) || recent.Count >= 5) throw new OtpLimitException();
        // Erase expired pending credentials on each request; consumed records retain only throttling metadata.
        var expired = await db.EmailChallenges.Where(c => c.ExpiresAt < now && c.PasswordHash != null).Take(500).ToListAsync();
        foreach (var item in expired) ClearPayload(item);
        foreach (var item in recent.Where(c => c.Purpose == challenge.Purpose && c.ConsumedAt == null)) Consume(item);
        var code = RandomNumberGenerator.GetInt32(1_000_000).ToString("D6");
        challenge.CreatedAt = now;
        challenge.ExpiresAt = now.AddMinutes(10);
        challenge.CodeHash = Hash(challenge, code);
        db.EmailChallenges.Add(challenge);
        await db.SaveChangesAsync();
        if (transaction != null) await transaction.CommitAsync();
        try { await sender.SendAsync(challenge.Email, code, challenge.Purpose); }
        catch
        {
            if (transaction != null) await transaction.DisposeAsync();
            Consume(challenge);
            await db.SaveChangesAsync();
            throw;
        }
        var at = challenge.Email.IndexOf('@');
        return new(challenge.Id, challenge.Email[..1] + "•••" + challenge.Email[at..], challenge.ExpiresAt);
    }

    public async Task<AuthResponseDto> VerifyRegistrationAsync(VerifyEmailCodeDto request)
    {
        var challenge = await VerifyAsync(request, Registration, null);
        if (await db.Users.AnyAsync(u => u.Email == challenge.Email)) throw new InvalidOperationException("This email is already registered. Please sign in.");
        var role = await db.Roles.SingleAsync(r => r.Name == RoleConstants.Homeowner);
        var user = new User { Email = challenge.Email, FullName = challenge.FullName!, PhoneNumber = challenge.PhoneNumber,
            PasswordHash = challenge.PasswordHash!, EmailVerifiedAt = Now };
        user.UserRoles.Add(new UserRole { UserId = user.Id, RoleId = role.Id });
        db.Users.Add(user);
        Consume(challenge);
        // Challenge consumption and user creation commit together. Revision prevents code replay races.
        await SaveConfirmationAsync();
        var (token, expiry) = tokens.GenerateToken(user, [role.Name]);
        return new AuthResponseDto { Token = token, ExpiresIn = expiry, User = new UserDto { Id = user.Id, Email = user.Email,
            FullName = user.FullName, PhoneNumber = user.PhoneNumber, Roles = [role.Name], CreatedAt = user.CreatedAt } };
    }

    public async Task ConfirmAccountActionAsync(Guid userId, string purpose, VerifyEmailCodeDto request)
    {
        var challenge = await VerifyAsync(request, purpose, userId);
        var user = await ActiveUserAsync(userId);
        if (challenge.UserVersion != user.SecurityVersion) throw new InvalidOperationException("This code is no longer valid. Request a new code.");
        if (purpose == PasswordChange) user.PasswordHash = challenge.PasswordHash!;
        else if (purpose == Deletion)
        {
            user.IsActive = false;
            user.Email = $"deleted-{user.Id:N}@account.invalid";
            user.FullName = "Deleted account";
            user.PhoneNumber = null;
            user.PasswordHash = hasher.HashPassword(Convert.ToHexString(RandomNumberGenerator.GetBytes(24)));
            var profile = await db.CustomerProfiles.SingleOrDefaultAsync(p => p.UserId == userId);
            if (profile != null) { profile.FullName = "Deleted account"; profile.PhoneNumber = null; profile.Address = null; profile.UpdatedAt = Now; }
        }
        else throw new ArgumentException("Invalid action.");
        user.SecurityVersion++;
        user.UpdatedAt = Now;
        user.EmailVerifiedAt = Now;
        var pending = await db.EmailChallenges.Where(c => c.Email == challenge.Email && c.ConsumedAt == null).ToListAsync();
        foreach (var item in pending) Consume(item);
        await SaveConfirmationAsync();
    }

    private async Task<EmailChallenge> VerifyAsync(VerifyEmailCodeDto request, string purpose, Guid? userId)
    {
        var challenge = await db.EmailChallenges.SingleOrDefaultAsync(c => c.Id == request.ChallengeId);
        if (challenge == null || challenge.Purpose != purpose || challenge.UserId != userId || challenge.ConsumedAt != null || challenge.ExpiresAt <= Now || challenge.Attempts >= 5)
            throw new InvalidOperationException("This code has expired or is unavailable. Request a new code.");
        if (request.Code.Length != 6 || !request.Code.All(char.IsAsciiDigit) ||
            !CryptographicOperations.FixedTimeEquals(Convert.FromHexString(challenge.CodeHash), Convert.FromHexString(Hash(challenge, request.Code))))
        {
            challenge.Attempts++;
            challenge.Revision = Guid.NewGuid();
            if (challenge.Attempts >= 5) Consume(challenge);
            await SaveConfirmationAsync();
            throw new InvalidOperationException("The verification code is incorrect. Check your email and try again.");
        }
        return challenge;
    }

    private string Hash(EmailChallenge challenge, string code)
    {
        var key = Environment.GetEnvironmentVariable("OTP_HASH_KEY") ?? config["OTP_HASH_KEY"]
            ?? Environment.GetEnvironmentVariable("JWT_KEY") ?? config["Jwt:Key"] ?? throw new InvalidOperationException("OTP signing key is missing.");
        return Convert.ToHexString(HMACSHA256.HashData(Encoding.UTF8.GetBytes(key), Encoding.UTF8.GetBytes($"{challenge.Id}|{challenge.Email}|{challenge.Purpose}|{code}")));
    }
    private static void ValidatePassword(string password)
    {
        if (password.Length < 12 || password.Length > 64 || Encoding.UTF8.GetByteCount(password) > 72 || string.IsNullOrWhiteSpace(password))
            throw new ArgumentException("Use a password of 12–64 characters (at most 72 UTF-8 bytes).");
    }
    private async Task<User> ActiveUserAsync(Guid id) => await db.Users.SingleOrDefaultAsync(u => u.Id == id && u.IsActive)
        ?? throw new UnauthorizedAccessException("Please sign in again.");
    private static void ClearPayload(EmailChallenge challenge) { challenge.PasswordHash = null; challenge.FullName = null; challenge.PhoneNumber = null; challenge.Revision = Guid.NewGuid(); }
    private void Consume(EmailChallenge challenge) { challenge.ConsumedAt = Now; challenge.CodeHash = ""; ClearPayload(challenge); }
    private async Task SaveConfirmationAsync()
    {
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateConcurrencyException) { throw new InvalidOperationException("This verification was already used or changed. Request a new code."); }
    }
}
