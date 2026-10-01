using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;

namespace SolarPlatform.Api.Controllers;

[ApiController, Authorize]
[Route("api/locations")]
public class LocationsController : ControllerBase
{
    private readonly IGeocodingService _geocoding;

    public LocationsController(IGeocodingService geocoding) => _geocoding = geocoding;

    [HttpGet("search")]
    [ProducesResponseType(typeof(IReadOnlyList<LocationSearchResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Search([FromQuery] string query, CancellationToken cancellationToken)
    {
        var value = query?.Trim() ?? string.Empty;
        if (value.Length < 3 || value.Length > 200)
        {
            return BadRequest(new { message = "Enter between 3 and 200 characters to search for an address." });
        }

        try
        {
            return Ok(await _geocoding.SearchAsync(value, cancellationToken));
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = ex.Message });
        }
    }
}
