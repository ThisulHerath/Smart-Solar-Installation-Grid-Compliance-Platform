using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.Models;

namespace SolarPlatform.Api.Controllers;

[ApiController, Authorize(Roles = "ADMINISTRATOR,SENIOR_ENGINEER,INVENTORY_OFFICER"), Route("api/reports")]
public class ReportsController(AppDbContext db) : ControllerBase
{
    [HttpGet("overview")]
    public async Task<IActionResult> Overview(CancellationToken ct) => Ok(new {
        surveyCount = await db.SolarSurveys.CountAsync(ct),
        pendingApprovals = await db.EngineeringProposals.CountAsync(x => x.ProposalStatus == ProposalStatus.PendingApproval, ct),
        approvedProposals = await db.EngineeringProposals.CountAsync(x => x.ProposalStatus == ProposalStatus.Approved, ct),
        lowStockItems = await db.Set<InventoryItem>().CountAsync(x => x.Active && x.QuantityInStock - x.ReservedQuantity <= x.ReorderLevel, ct),
        reservedEquipmentValueLkr = await db.Set<InventoryReservation>().Where(x => x.Status == ReservationStatus.RESERVED).SumAsync(x => (decimal?)x.TotalPriceLkr, ct) ?? 0,
        proposalStatuses = await db.EngineeringProposals.GroupBy(x => x.ProposalStatus).Select(x => new { status = x.Key, count = x.Count() }).ToListAsync(ct),
        generatedAt = DateTime.UtcNow
    });
}
