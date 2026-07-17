using System.Security.Claims;

namespace DATABASEAPI.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int? GetUserId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub");
        return int.TryParse(value, out var id) ? id : null;
    }

    public static bool IsAdmin(this ClaimsPrincipal user)
    {
        return user.IsInRole("Admin");
    }
}
