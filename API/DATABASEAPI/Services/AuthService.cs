using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using DATABASEAPI.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;

namespace DATABASEAPI.Services;

public interface IAuthService
{
    string HashPassword(NguoiDung user, string password);
    bool VerifyPassword(NguoiDung user, string password);
    string GenerateJwtToken(NguoiDung user);
}

public class AuthService : IAuthService
{
    private readonly IConfiguration _configuration;
    private readonly PasswordHasher<NguoiDung> _passwordHasher = new();

    public AuthService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string HashPassword(NguoiDung user, string password)
    {
        return _passwordHasher.HashPassword(user, password);
    }

    public bool VerifyPassword(NguoiDung user, string password)
    {
        // Cho phép đăng nhập tài khoản mẫu cũ đang lưu plaintext, sau đó controller sẽ nâng cấp sang hash.
        if (!string.IsNullOrWhiteSpace(user.MatKhau) && user.MatKhau == password)
            return true;

        var result = _passwordHasher.VerifyHashedPassword(user, user.MatKhau, password);
        return result == PasswordVerificationResult.Success || result == PasswordVerificationResult.SuccessRehashNeeded;
    }

    public string GenerateJwtToken(NguoiDung user)
    {
        var jwt = _configuration.GetSection("Jwt");
        var key = jwt["Key"] ?? throw new InvalidOperationException("Missing Jwt:Key config.");
        var issuer = jwt["Issuer"] ?? "MarvelTravelAPI";
        var audience = jwt["Audience"] ?? "MarvelTravelApp";
        var expireMinutes = int.TryParse(jwt["ExpireMinutes"], out var minutes) ? minutes : 1440;

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.MaNguoiDung.ToString()),
            new(ClaimTypes.NameIdentifier, user.MaNguoiDung.ToString()),
            new(ClaimTypes.Email, user.Email),
            new(ClaimTypes.Name, user.HoTen),
            new(ClaimTypes.Role, user.VaiTro ?? "User"),
            new("role", user.VaiTro ?? "User")
        };

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var credentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expireMinutes),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
