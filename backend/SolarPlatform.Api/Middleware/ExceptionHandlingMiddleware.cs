using System.Net;
using System.Text.Json;
using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace SolarPlatform.Api.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred during request execution: {Path}", context.Request.Path);
            if (context.Response.HasStarted) throw;
            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var statusCode = HttpStatusCode.InternalServerError;
        var message = "An internal server error occurred.";

        switch (exception)
        {
            case SolarPlatform.Api.Services.EmailDeliveryException:
                statusCode = HttpStatusCode.ServiceUnavailable;
                message = exception.Message;
                break;

            case SolarPlatform.Api.Services.OtpLimitException:
                statusCode = HttpStatusCode.TooManyRequests;
                message = exception.Message;
                context.Response.Headers.RetryAfter = "60";
                break;

            case Microsoft.EntityFrameworkCore.DbUpdateConcurrencyException:
                statusCode = HttpStatusCode.Conflict;
                message = "The inventory changed during this request. Refresh and retry.";
                break;

            case Microsoft.EntityFrameworkCore.DbUpdateException:
                statusCode = HttpStatusCode.Conflict;
                message = "The change conflicts with an existing record or stock constraint. Refresh and retry.";
                break;

            case Npgsql.PostgresException pg when pg.SqlState is "40001" or "40P01":
                statusCode = HttpStatusCode.Conflict;
                message = "A concurrent inventory update occurred. Refresh and retry.";
                break;

            case UnauthorizedAccessException:
                statusCode = HttpStatusCode.Unauthorized;
                message = exception.Message;
                break;

            case InvalidOperationException when exception.InnerException != null:
                // Infrastructure failures must not expose nested provider/configuration details.
                statusCode = HttpStatusCode.ServiceUnavailable;
                message = "A required service is temporarily unavailable. Please retry later.";
                break;

            case InvalidOperationException:
                statusCode = HttpStatusCode.BadRequest;
                message = exception.Message;
                break;

            case KeyNotFoundException:
                statusCode = HttpStatusCode.NotFound;
                message = exception.Message;
                break;
                
            case ArgumentException:
                statusCode = HttpStatusCode.BadRequest;
                message = exception.Message;
                break;
        }

        context.Response.ContentType = "application/problem+json";
        context.Response.StatusCode = (int)statusCode;

        var response = new ProblemDetails
        {
            Status = context.Response.StatusCode,
            Title = statusCode.ToString(),
            Detail = message,
            Type = "about:blank",
            Instance = context.Request.Path
        };
        // Preserve the existing clients' message field while providing a standard error contract.
        response.Extensions["message"] = message;
        response.Extensions["traceId"] = Activity.Current?.Id ?? context.TraceIdentifier;
        response.Extensions["timestamp"] = DateTime.UtcNow;

        var json = JsonSerializer.Serialize(response, new JsonSerializerOptions(JsonSerializerDefaults.Web));
        return context.Response.WriteAsync(json);
    }
}
