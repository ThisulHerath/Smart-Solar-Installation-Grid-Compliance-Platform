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

    [HttpGet("reverse")]
    [ProducesResponseType(typeof(LocationSearchResultDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Reverse(
        [FromQuery] decimal latitude,
        [FromQuery] decimal longitude,
        CancellationToken cancellationToken)
    {
        if (latitude is < -90 or > 90 || longitude is < -180 or > 180)
        {
            return BadRequest(new { message = "Choose a valid point on the map." });
        }

        try
        {
            var result = await _geocoding.ReverseAsync(latitude, longitude, cancellationToken);
            return result == null
                ? NotFound(new { message = "No street address was found for this map point." })
                : Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = ex.Message });
        }
    }
}
