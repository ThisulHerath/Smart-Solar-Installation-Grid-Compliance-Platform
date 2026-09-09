namespace SolarPlatform.Api.Services;

public class LocalFileStorageService : IFileStorageService
{
    private readonly IWebHostEnvironment _env;

    public LocalFileStorageService(IWebHostEnvironment env)
    {
        _env = env;
    }

    public async Task<string> SaveFileAsync(Stream fileStream, string originalFileName, string subDirectory, CancellationToken cancellationToken = default)
    {
        var root = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
        var targetDir = Path.Combine(root, "uploads", subDirectory);
        Directory.CreateDirectory(targetDir);

        var extension = Path.GetExtension(originalFileName);
        var uniqueFileName = $"{Guid.NewGuid()}{extension}";
        var fullPath = Path.Combine(targetDir, uniqueFileName);

        using (var outputStream = new FileStream(fullPath, FileMode.Create, FileAccess.Write, FileShare.None, 4096, useAsync: true))
        {
            await fileStream.CopyToAsync(outputStream, cancellationToken);
        }

        return $"/uploads/{subDirectory}/{uniqueFileName}";
    }

    public Task<Stream?> GetFileAsync(string fileUrl, CancellationToken cancellationToken = default)
    {
        var root = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
        var relativePath = fileUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
        var fullPath = Path.Combine(root, relativePath);

        if (!File.Exists(fullPath))
        {
            return Task.FromResult<Stream?>(null);
        }

        Stream stream = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.Read, 4096, useAsync: true);
        return Task.FromResult<Stream?>(stream);
    }

    public Task<bool> DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default)
    {
        var root = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
        var relativePath = fileUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
        var fullPath = Path.Combine(root, relativePath);

        if (File.Exists(fullPath))
        {
            File.Delete(fullPath);
            return Task.FromResult(true);
        }

        return Task.FromResult(false);
    }
}
