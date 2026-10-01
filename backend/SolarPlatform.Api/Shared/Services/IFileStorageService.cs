namespace SolarPlatform.Api.Services;

public interface IFileStorageService
{
    Task<string> SaveFileAsync(Stream fileStream, string originalFileName, string subDirectory, CancellationToken cancellationToken = default);
    Task<Stream?> GetFileAsync(string fileUrl, CancellationToken cancellationToken = default);
    Task<bool> DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default);
}
