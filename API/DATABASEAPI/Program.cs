using System.Text;
using DATABASEAPI.Entities;
using DATABASEAPI.Services;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// --- Firebase Admin SDK Setup ---
var firebaseKeyPath = Path.Combine(builder.Environment.ContentRootPath, "firebase-service-account.json");
if (File.Exists(firebaseKeyPath))
{
    FirebaseApp.Create(new AppOptions
    {
        Credential = GoogleCredential.FromFile(firebaseKeyPath)
    });
    Console.WriteLine("Firebase Admin SDK initialized successfully.");
}
else
{
    Console.WriteLine("Warning: firebase-service-account.json not found. Firebase features will be disabled.");
}
// --------------------------------

builder.Services.AddControllers();

builder.Services.AddHttpClient();

builder.Services.AddDbContext<MarvelTravelDbContext>(option =>
   option.UseSqlServer(builder.Configuration.GetConnectionString("ApiDemo")));

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IFcmNotificationService, FcmNotificationService>();
builder.Services.AddScoped<IOtpDeliveryService, OtpDeliveryService>();

var jwtKey = builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("Missing Jwt:Key config.");
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "MarvelTravelAPI";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "MarvelTravelApp";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ClockSkew = TimeSpan.FromMinutes(2)
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("ContentModerator", policy => policy.RequireRole("Admin", "Moderator"));
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Nhập JWT theo dạng: Bearer {token}"
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
