using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging.Abstractions;
using SolarPlatform.Api.Middleware;

namespace SolarPlatform.Tests;

public class ExceptionHandlingMiddlewareTests
{
    [Fact]
    public async Task Unexpected_errors_return_problem_details_without_secrets()
    {
        var context = new DefaultHttpContext { TraceIdentifier = "test-trace" };
        context.Response.Body = new MemoryStream();
        var middleware = new ExceptionHandlingMiddleware(_ => throw new Exception("password=SECRET"), NullLogger<ExceptionHandlingMiddleware>.Instance);
        await middleware.InvokeAsync(context);
        context.Response.Body.Position = 0;
        var body = await new StreamReader(context.Response.Body).ReadToEndAsync();
        var result = JsonDocument.Parse(body).RootElement;
        Assert.Equal(500, context.Response.StatusCode);
        Assert.Equal("application/problem+json", context.Response.ContentType);
        Assert.Equal("test-trace", result.GetProperty("traceId").GetString());
        Assert.Equal(result.GetProperty("detail").GetString(), result.GetProperty("message").GetString());
        Assert.DoesNotContain("SECRET", body);
    }

    [Fact]
    public async Task Wrapped_database_failure_is_not_reported_as_bad_user_input()
    {
        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();
        var middleware = new ExceptionHandlingMiddleware(_ => throw new InvalidOperationException("connection string SECRET", new Exception("provider detail")), NullLogger<ExceptionHandlingMiddleware>.Instance);
        await middleware.InvokeAsync(context);
        Assert.Equal(503, context.Response.StatusCode);
        context.Response.Body.Position = 0;
        var body = await new StreamReader(context.Response.Body).ReadToEndAsync();
        Assert.DoesNotContain("SECRET", body);
        Assert.DoesNotContain("provider detail", body);
    }
}
