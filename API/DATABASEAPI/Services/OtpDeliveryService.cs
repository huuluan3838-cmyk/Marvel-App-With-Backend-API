using System.Net;
using System.Net.Mail;
using System.Text;
using System.Text.Json;

namespace DATABASEAPI.Services;

public interface IOtpDeliveryService
{
    Task SendEmailOtpAsync(string email, string otp, CancellationToken cancellationToken = default);
    Task SendSmsOtpAsync(string phone, string otp, CancellationToken cancellationToken = default);
}

public class OtpDeliveryService : IOtpDeliveryService
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<OtpDeliveryService> _logger;

    public OtpDeliveryService(IConfiguration configuration, IHttpClientFactory httpClientFactory, ILogger<OtpDeliveryService> logger)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    public async Task SendEmailOtpAsync(string email, string otp, CancellationToken cancellationToken = default)
    {
        var host = _configuration["Otp:Email:SmtpHost"];
        var port = int.TryParse(_configuration["Otp:Email:SmtpPort"], out var p) ? p : 587;
        var username = _configuration["Otp:Email:Username"];
        var password = _configuration["Otp:Email:Password"];
        var fromEmail = _configuration["Otp:Email:FromEmail"] ?? username;
        var fromName = _configuration["Otp:Email:FromName"] ?? "Marvel Travel";
        var enableSsl = bool.TryParse(_configuration["Otp:Email:EnableSsl"], out var ssl) ? ssl : true;

        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(fromEmail))
            throw new InvalidOperationException("Chưa cấu hình SMTP gửi email OTP. Vui lòng cấu hình Otp:Email trong appsettings.");

#pragma warning disable SYSLIB0014
        using var smtp = new SmtpClient(host, port)
        {
            EnableSsl = enableSsl,
            DeliveryMethod = SmtpDeliveryMethod.Network,
            UseDefaultCredentials = false,
            Credentials = string.IsNullOrWhiteSpace(username) ? CredentialCache.DefaultNetworkCredentials : new NetworkCredential(username, password)
        };
#pragma warning restore SYSLIB0014

        using var message = new MailMessage
        {
            From = new MailAddress(fromEmail, fromName, Encoding.UTF8),
            Subject = "Mã OTP xác thực Marvel Travel",
            SubjectEncoding = Encoding.UTF8,
            BodyEncoding = Encoding.UTF8,
            IsBodyHtml = true,
            Body = $@"
                <div style='font-family:Arial,sans-serif;line-height:1.6'>
                    <h2>Marvel Travel</h2>
                    <p>Mã OTP của bạn là:</p>
                    <p style='font-size:28px;font-weight:bold;letter-spacing:4px'>{WebUtility.HtmlEncode(otp)}</p>
                    <p>Mã có hiệu lực trong 5 phút. Không chia sẻ mã này cho bất kỳ ai.</p>
                </div>"
        };
        message.To.Add(email);
        await smtp.SendMailAsync(message, cancellationToken);
    }

    public async Task SendSmsOtpAsync(string phone, string otp, CancellationToken cancellationToken = default)
    {
        // Chuẩn hóa số điện thoại: 0... -> +84... cho Việt Nam
        var normalizedPhone = phone.Trim();
        if (normalizedPhone.StartsWith("0") && normalizedPhone.Length >= 10)
        {
            normalizedPhone = "+84" + normalizedPhone.Substring(1);
        }
        else if (!normalizedPhone.StartsWith("+"))
        {
            normalizedPhone = "+" + normalizedPhone;
        }

        var provider = (_configuration["Otp:Sms:Provider"] ?? "None").Trim();
        if (provider.Equals("Twilio", StringComparison.OrdinalIgnoreCase))
        {
            await SendTwilioSmsAsync(normalizedPhone, otp, cancellationToken);
            return;
        }
        if (provider.Equals("CustomHttp", StringComparison.OrdinalIgnoreCase))
        {
            await SendCustomHttpSmsAsync(normalizedPhone, otp, cancellationToken);
            return;
        }
        throw new InvalidOperationException("Chưa cấu hình nhà cung cấp SMS OTP. Dùng Otp:Sms:Provider = Twilio hoặc CustomHttp.");
    }

    private async Task SendTwilioSmsAsync(string phone, string otp, CancellationToken cancellationToken)
    {
        var accountSid = _configuration["Otp:Sms:Twilio:AccountSid"];
        var authToken = _configuration["Otp:Sms:Twilio:AuthToken"];
        var from = _configuration["Otp:Sms:Twilio:From"];
        if (string.IsNullOrWhiteSpace(accountSid) || string.IsNullOrWhiteSpace(authToken) || string.IsNullOrWhiteSpace(from))
            throw new InvalidOperationException("Chưa cấu hình Twilio AccountSid/AuthToken/From.");

        var client = _httpClientFactory.CreateClient();
        var auth = Convert.ToBase64String(Encoding.ASCII.GetBytes($"{accountSid}:{authToken}"));
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", auth);
        var content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["To"] = phone,
            ["From"] = from,
            ["Body"] = $"Marvel Travel: Ma OTP cua ban la {otp}. Ma co hieu luc trong 5 phut."
        });
        var response = await client.PostAsync($"https://api.twilio.com/2010-04-01/Accounts/{accountSid}/Messages.json", content, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"Twilio gửi SMS thất bại: {(int)response.StatusCode} {body}");
    }

    private async Task SendCustomHttpSmsAsync(string phone, string otp, CancellationToken cancellationToken)
    {
        var url = _configuration["Otp:Sms:CustomHttp:Url"];
        var apiKey = _configuration["Otp:Sms:CustomHttp:ApiKey"];
        if (string.IsNullOrWhiteSpace(url))
            throw new InvalidOperationException("Chưa cấu hình Otp:Sms:CustomHttp:Url.");
        var client = _httpClientFactory.CreateClient();
        if (!string.IsNullOrWhiteSpace(apiKey)) client.DefaultRequestHeaders.Add("X-API-Key", apiKey);
        var payload = JsonSerializer.Serialize(new { to = phone, message = $"Marvel Travel: Mã OTP của bạn là {otp}. Mã có hiệu lực trong 5 phút.", otp });
        var response = await client.PostAsync(url, new StringContent(payload, Encoding.UTF8, "application/json"), cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"Custom SMS API thất bại: {(int)response.StatusCode} {body}");
    }
}
