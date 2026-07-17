using DATABASEAPI.Entities;

using DATABASEAPI.Services;

using Microsoft.AspNetCore.Authorization;

using Microsoft.AspNetCore.Mvc;

using Microsoft.EntityFrameworkCore;

namespace MarvelTravelAPI.Controllers

{

    [Route("api/[controller]")]

    [ApiController]

    public class AuthController : ControllerBase

    {

        private readonly MarvelTravelDbContext _context;

        private readonly IAuthService _authService;

        private readonly IOtpDeliveryService _otpDeliveryService;

        public AuthController(MarvelTravelDbContext context, IAuthService authService, IOtpDeliveryService otpDeliveryService)

        {

            _context = context;

            _authService = authService;

            _otpDeliveryService = otpDeliveryService;

        }

        // POST: api/auth/login

        [HttpPost("login")]

        [AllowAnonymous]

        public async Task<IActionResult> Login([FromBody] LoginRequest request)

        {

            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))

                return BadRequest(new { message = "Vui lòng nhập email/số điện thoại và mật khẩu." });

            // Tìm theo Email hoặc Số điện thoại

            var user = await _context.NguoiDungs.FirstOrDefaultAsync(u => u.Email == request.Email || u.SoDienThoai == request.Email);

            

            if (user == null || !_authService.VerifyPassword(user, request.Password))

                return Unauthorized(new { message = "Thông tin đăng nhập không chính xác!" });

            // Nâng cấp tài khoản mẫu đang lưu plaintext sang hash sau lần đăng nhập thành công.

            if (user.MatKhau == request.Password)

            {

                user.MatKhau = _authService.HashPassword(user, request.Password);

                await _context.SaveChangesAsync();

            }

            return Ok(CreateAuthResponse(user));

        }

        // POST: api/auth/send-otp
        [HttpPost("send-otp")]
        [AllowAnonymous]
        public async Task<IActionResult> SendOtp([FromBody] OtpRequest request)
        {
            var contact = request.Phone ?? request.Email;
            if (string.IsNullOrWhiteSpace(contact))
                return BadRequest(new { message = "Vui lòng nhập số điện thoại hoặc email." });

            var user = await _context.NguoiDungs.FirstOrDefaultAsync(u => u.SoDienThoai == contact || u.Email == contact);
            if (user == null)
                return NotFound(new { message = "Thông tin liên hệ chưa được đăng ký!" });

            string otpCode = new Random().Next(100000, 999999).ToString();
            user.OtpCode = otpCode;
            user.OtpExpiry = DateTime.Now.AddMinutes(5);
            await _context.SaveChangesAsync();

            try
            {
                if (!string.IsNullOrWhiteSpace(user.SoDienThoai) && contact == user.SoDienThoai)
                {
                    await _otpDeliveryService.SendSmsOtpAsync(user.SoDienThoai, otpCode, HttpContext.RequestAborted);
                }
                else if (!string.IsNullOrWhiteSpace(user.Email) && contact == user.Email)
                {
                    await _otpDeliveryService.SendEmailOtpAsync(user.Email, otpCode, HttpContext.RequestAborted);
                }
                return Ok(new { message = "Mã OTP đã được gửi thành công!" });
            }
            catch (Exception ex)
            {
                // Vẫn giữ lại OTP trong body cho mục đích debug nhưng thông báo rõ lỗi
                return BadRequest(new { message = "Gửi OTP thất bại: " + ex.Message, otp = otpCode });
            }
        }

        // POST: api/auth/login-otp

        [HttpPost("login-otp")]

        [AllowAnonymous]

        public async Task<IActionResult> LoginWithOtp([FromBody] OtpLoginRequest request)

        {

            if (string.IsNullOrWhiteSpace(request.Phone) || string.IsNullOrWhiteSpace(request.Otp))

                return BadRequest(new { message = "Vui lòng nhập số điện thoại và mã OTP." });

            var user = await _context.NguoiDungs.FirstOrDefaultAsync(u => u.SoDienThoai == request.Phone);

            

            if (user == null || user.OtpCode != request.Otp || user.OtpExpiry < DateTime.Now)

                return Unauthorized(new { message = "Mã OTP không chính xác hoặc đã hết hạn!" });

            // Xóa OTP sau khi dùng

            user.OtpCode = null;

            user.OtpExpiry = null;

            await _context.SaveChangesAsync();

            return Ok(CreateAuthResponse(user));

        }

        // POST: api/auth/register

        [HttpPost("register")]

        [AllowAnonymous]

        public async Task<IActionResult> Register([FromBody] RegisterRequest request)

        {

            if (string.IsNullOrWhiteSpace(request.HoTen) || string.IsNullOrWhiteSpace(request.Password) ||
                (string.IsNullOrWhiteSpace(request.Email) && string.IsNullOrWhiteSpace(request.SoDienThoai)))

                return BadRequest(new { message = "Vui lòng nhập họ tên, mật khẩu và email hoặc số điện thoại." });

            // Xóa người dùng cũ nếu trùng email hoặc số điện thoại nhưng chưa bao giờ đăng nhập thành công (hoặc xóa để đăng ký mới)
            var existingUnverifiedUser = await _context.NguoiDungs.FirstOrDefaultAsync(u => u.Email == request.Email || (!string.IsNullOrEmpty(request.SoDienThoai) && u.SoDienThoai == request.SoDienThoai));
            if (existingUnverifiedUser != null)
            {
                // Nếu bạn muốn cho phép đăng ký đè lên bản ghi cũ chưa xác thực:
                _context.NguoiDungs.Remove(existingUnverifiedUser);
                await _context.SaveChangesAsync();
            }

            var newUser = new NguoiDung
            {
                HoTen = request.HoTen,
                Email = string.IsNullOrWhiteSpace(request.Email) ? $"phone_{request.SoDienThoai}@marvel.local" : request.Email,
                SoDienThoai = request.SoDienThoai,
                VaiTro = "User",
                AnhDaiDien = request.AnhDaiDien,
                NgayTao = DateTime.Now,
                MatKhau = string.Empty
            };

            newUser.MatKhau = _authService.HashPassword(newUser, request.Password);

            newUser.OtpCode = new Random().Next(100000, 999999).ToString();

            newUser.OtpExpiry = DateTime.Now.AddMinutes(5);

            _context.NguoiDungs.Add(newUser);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException dbEx)
            {
                return BadRequest(new { message = "Lỗi lưu Database: " + (dbEx.InnerException?.Message ?? dbEx.Message) });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Lỗi không xác định khi lưu: " + ex.Message });
            }

            var otpChannel = request.OtpChannel ?? (!string.IsNullOrWhiteSpace(request.Email) ? "email" : "phone");
            var otpContact = otpChannel.Equals("phone", StringComparison.OrdinalIgnoreCase) ? request.SoDienThoai : request.Email;
            if (string.IsNullOrWhiteSpace(otpContact))
                return BadRequest(new { message = "Phương thức nhận OTP không hợp lệ." });

            try
            {
                if (otpChannel.Equals("phone", StringComparison.OrdinalIgnoreCase))
                    await _otpDeliveryService.SendSmsOtpAsync(otpContact, newUser.OtpCode, HttpContext.RequestAborted);
                else
                    await _otpDeliveryService.SendEmailOtpAsync(otpContact, newUser.OtpCode, HttpContext.RequestAborted);

                return Ok(new { message = "Đăng ký thành công, vui lòng kiểm tra OTP để xác thực!", otpChannel, auth = CreateAuthResponse(newUser) });
            }
            catch (Exception ex)
            {
                return Ok(new { 
                    message = "Đăng ký thành công (Gửi OTP thất bại: " + ex.Message + ")", 
                    otp = newUser.OtpCode,
                    otpChannel, 
                    auth = CreateAuthResponse(newUser) 
                });
            }
        }

        // POST: api/auth/google-login

        [HttpPost("google-login")]

        [AllowAnonymous]

        public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginRequest request)

        {

            if (string.IsNullOrWhiteSpace(request.Email))

                return BadRequest(new { message = "Email từ Google không hợp lệ!" });

            var existingUser = await _context.NguoiDungs.FirstOrDefaultAsync(u => u.Email == request.Email);

            if (existingUser != null)

                return Ok(CreateAuthResponse(existingUser));

            var newUser = new NguoiDung

            {

                Email = request.Email,

                HoTen = string.IsNullOrWhiteSpace(request.Name) ? "Google User" : request.Name,

                AnhDaiDien = request.PhotoUrl,

                VaiTro = "User",

                NgayTao = DateTime.Now,

                MatKhau = string.Empty

            };

            newUser.MatKhau = _authService.HashPassword(newUser, Guid.NewGuid().ToString("N"));

            _context.NguoiDungs.Add(newUser);

            await _context.SaveChangesAsync();

            return Ok(CreateAuthResponse(newUser));

        }


        [HttpPost("verify-otp")]

        [AllowAnonymous]

        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest request)

        {
            var contact = request.Contact;
            if (string.IsNullOrWhiteSpace(contact) || string.IsNullOrWhiteSpace(request.Otp))
                return BadRequest(new { message = "Vui lòng nhập thông tin liên hệ và OTP." });

            var user = await _context.NguoiDungs.FirstOrDefaultAsync(u => u.Email == contact || u.SoDienThoai == contact);
            if (user == null || user.OtpCode != request.Otp || user.OtpExpiry < DateTime.Now)
                return Unauthorized(new { message = "Mã OTP không chính xác hoặc đã hết hạn!" });

            user.OtpCode = null;
            user.OtpExpiry = null;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Xác thực OTP thành công!", auth = CreateAuthResponse(user) });
        }

        [HttpPost("reset-password")]

        [AllowAnonymous]

        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)

        {
            if (string.IsNullOrWhiteSpace(request.Contact) || string.IsNullOrWhiteSpace(request.Otp) || string.IsNullOrWhiteSpace(request.NewPassword))
                return BadRequest(new { message = "Vui lòng nhập đầy đủ thông tin." });
            var user = await _context.NguoiDungs.FirstOrDefaultAsync(u => u.Email == request.Contact || u.SoDienThoai == request.Contact);
            if (user == null || user.OtpCode != request.Otp || user.OtpExpiry < DateTime.Now)
                return Unauthorized(new { message = "Mã OTP không chính xác hoặc đã hết hạn!" });
            user.MatKhau = _authService.HashPassword(user, request.NewPassword);
            user.OtpCode = null;
            user.OtpExpiry = null;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đặt lại mật khẩu thành công!" });
        }

        private AuthResponse CreateAuthResponse(NguoiDung user)

        {

            return new AuthResponse

            {

                Token = _authService.GenerateJwtToken(user),

                User = new UserDto

                {

                    MaNguoiDung = user.MaNguoiDung,

                    HoTen = user.HoTen,

                    Email = user.Email,

                    SoDienThoai = user.SoDienThoai,

                    VaiTro = user.VaiTro ?? "User",

                    AnhDaiDien = user.AnhDaiDien,

                    NgayTao = user.NgayTao

                }

            };

        }

    }

    public class LoginRequest

    {

        public string? Email { get; set; }

        public string? Password { get; set; }

    }

    public class OtpRequest

    {

        public string? Phone { get; set; }

        public string? Email { get; set; }

    }

    public class OtpLoginRequest

    {

        public string? Phone { get; set; }

        public string? Otp { get; set; }

    }

    public class RegisterRequest

    {

        public string? HoTen { get; set; }

        public string? Email { get; set; }

        public string? SoDienThoai { get; set; }

        public string? Password { get; set; }

        public string? AnhDaiDien { get; set; }

        public string? OtpChannel { get; set; }

    }

    public class GoogleLoginRequest

    {

        public string? Email { get; set; }

        public string? Name { get; set; }

        public string? PhotoUrl { get; set; }

    }

    public class VerifyOtpRequest
    {
        public string? Contact { get; set; }
        public string? Otp { get; set; }
    }

    public class ResetPasswordRequest
    {
        public string? Contact { get; set; }
        public string? Otp { get; set; }
        public string? NewPassword { get; set; }
    }

    public class AuthResponse

    {

        public string Token { get; set; } = string.Empty;

        public UserDto User { get; set; } = new();

    }

    public class UserDto

    {

        public int MaNguoiDung { get; set; }

        public string HoTen { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string? SoDienThoai { get; set; }

        public string VaiTro { get; set; } = "User";

        public string? AnhDaiDien { get; set; }

        public DateTime? NgayTao { get; set; }

    }

}

