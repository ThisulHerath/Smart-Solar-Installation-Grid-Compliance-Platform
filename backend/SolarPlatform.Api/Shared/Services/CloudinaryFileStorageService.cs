using System.Text.RegularExpressions;
using CloudinaryDotNet;
using CloudinaryDotNet.Actions;

namespace SolarPlatform.Api.Services;

public sealed partial class CloudinaryFileStorageService : IFileStorageService
{
    private readonly Cloudinary _cloudinary;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<CloudinaryFileStorageService> _logger;
    private readonly string _cloudName;
    private readonly string _rootFolder;

    public CloudinaryFileStorageService(
        CloudinaryStorageOptions options,
        IHttpClientFactory httpClientFactory,
        ILogger<CloudinaryFileStorageService> logger)
    {
        _cloudName = options.CloudName;
        _rootFolder = NormalizeFolder(options.RootFolder);
        _httpClientFactory = httpClientFactory;
        _logger = logger;
        _cloudinary = new Cloudinary(new Account(options.CloudName, options.ApiKey, options.ApiSecret))
        {
            Api = { Secure = true }
        };
    }

    public async Task<string> SaveFileAsync(
        Stream fileStream,
        string originalFileName,
        string subDirectory,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(fileStream);

        var folder = $"{_rootFolder}/{NormalizeFolder(subDirectory)}";
        var publicId = Guid.NewGuid().ToString("N");
        var upload = await _cloudinary.UploadAsync(new ImageUploadParams
        {
            File = new FileDescription(Path.GetFileName(originalFileName), fileStream),
            Folder = folder,
            PublicId = publicId,
            Overwrite = false,
            UniqueFilename = false,
            UseFilename = false
        }, cancellationToken);

        if (upload.Error is not null || upload.SecureUrl is null)
        {
            var reason = upload.Error?.Message ?? "Cloudinary did not return a secure image URL.";
            _logger.LogError("Cloudinary upload failed: {Reason}", reason);
            throw new InvalidOperationException("The image could not be stored. Please try again.");
        }

        return upload.SecureUrl.AbsoluteUri;
    }

    public async Task<Stream?> GetFileAsync(string fileUrl, CancellationToken cancellationToken = default)
    {
        if (!IsOwnedCloudinaryUrl(fileUrl, out var uri)) return null;

        var client = _httpClientFactory.CreateClient(nameof(CloudinaryFileStorageService));
        try
        {
            return await client.GetStreamAsync(uri, cancellationToken);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(ex, "Unable to read a Cloudinary image.");
            return null;
        }
    }

    public async Task<bool> DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default)
    {
        // Existing local URLs may remain in Neon during a gradual migration.
        // They are deliberately ignored by the cloud provider rather than causing profile updates to fail.
        if (!TryGetPublicId(fileUrl, out var publicId)) return true;

        cancellationToken.ThrowIfCancellationRequested();
        var deletion = await _cloudinary.DestroyAsync(new DeletionParams(publicId)
        {
            ResourceType = ResourceType.Image,
            Invalidate = true
        });
        cancellationToken.ThrowIfCancellationRequested();

        if (deletion.Error is not null)
        {
            _logger.LogError("Cloudinary deletion failed for {PublicId}: {Reason}", publicId, deletion.Error.Message);
            return false;
        }

        return deletion.Result is "ok" or "not found";
    }

    private bool TryGetPublicId(string fileUrl, out string publicId)
    {
        publicId = string.Empty;
        if (!IsOwnedCloudinaryUrl(fileUrl, out var uri)) return false;

        var segments = uri.AbsolutePath.Split('/', StringSplitOptions.RemoveEmptyEntries);
        var uploadIndex = Array.FindIndex(segments, value => value.Equals("upload", StringComparison.OrdinalIgnoreCase));
        if (uploadIndex < 0 || uploadIndex + 1 >= segments.Length) return false;

        var assetSegments = segments[(uploadIndex + 1)..];
        if (assetSegments.Length > 0 && VersionSegmentRegex().IsMatch(assetSegments[0]))
            assetSegments = assetSegments[1..];
        if (assetSegments.Length == 0) return false;

        assetSegments[^1] = Path.GetFileNameWithoutExtension(Uri.UnescapeDataString(assetSegments[^1]));
        publicId = string.Join('/', assetSegments.Select(Uri.UnescapeDataString));
        return publicId.StartsWith($"{_rootFolder}/", StringComparison.Ordinal);
    }

    private bool IsOwnedCloudinaryUrl(string fileUrl, out Uri uri)
    {
        if (!Uri.TryCreate(fileUrl, UriKind.Absolute, out uri!)) return false;
        if (!uri.Scheme.Equals(Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase)) return false;
        if (!uri.Host.Equals("res.cloudinary.com", StringComparison.OrdinalIgnoreCase)) return false;

        var firstSegment = uri.AbsolutePath.Split('/', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault();
        return firstSegment?.Equals(_cloudName, StringComparison.Ordinal) == true;
    }

    private static string NormalizeFolder(string folder)
    {
        var segments = folder.Replace('\\', '/').Split('/', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (segments.Length == 0 || segments.Any(segment => !SafeFolderSegmentRegex().IsMatch(segment)))
            throw new InvalidOperationException("The configured image storage folder is invalid.");
        return string.Join('/', segments);
    }

    [GeneratedRegex("^v[0-9]+$", RegexOptions.CultureInvariant)]
    private static partial Regex VersionSegmentRegex();

    [GeneratedRegex("^[A-Za-z0-9_-]+$", RegexOptions.CultureInvariant)]
    private static partial Regex SafeFolderSegmentRegex();
}
