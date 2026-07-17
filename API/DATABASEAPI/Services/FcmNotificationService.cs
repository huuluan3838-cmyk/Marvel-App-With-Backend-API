using FirebaseAdmin.Messaging;

namespace DATABASEAPI.Services;

public interface IFcmNotificationService
{
    Task SendToTokensAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        Dictionary<string, string>? data = null);
}

public class FcmNotificationService : IFcmNotificationService
{
    public async Task SendToTokensAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        var tokenList = tokens
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct()
            .ToList();

        if (tokenList.Count == 0) return;

        var message = new MulticastMessage
        {
            Tokens = tokenList,
            Notification = new Notification
            {
                Title = title,
                Body = body,
            },
            Data = data ?? new Dictionary<string, string>(),
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification
                {
                    ChannelId = "marvel_travel_channel",
                    Sound = "default",
                }
            }
        };

        if (FirebaseAdmin.FirebaseApp.DefaultInstance == null)
        {
            // Firebase chưa được cấu hình, bỏ qua việc gửi thông báo để tránh crash app
            Console.WriteLine("Warning: FirebaseAdmin is not initialized. Notification skipped.");
            return;
        }

        await FirebaseMessaging.DefaultInstance.SendEachForMulticastAsync(message);
    }
}
