using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using SolarPlatform.Api.Data;
using SolarPlatform.Api.DTOs;
using SolarPlatform.Api.Integrations;
using SolarPlatform.Api.Models;
using SolarPlatform.Api.Services;

namespace SolarPlatform.Tests;

public class FieldJobServiceTests
{
    private readonly AppDbContext _db;
    private readonly Mock<IAgenticAiService> _aiMock = new();
    private readonly Mock<IFileStorageService> _fileStorageMock = new();
    private readonly Mock<ILogger<FieldJobService>> _loggerMock = new();

    private readonly Guid _techId = Guid.NewGuid();
    private readonly Guid _otherTechId = Guid.NewGuid();
    private readonly Guid _customerId = Guid.NewGuid();
    private readonly Guid _surveyId = Guid.NewGuid();

    public FieldJobServiceTests()
    {
        _db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

        // Seed users & survey
        var tech = new User
        {
            Id = _techId,
            Email = "tech@smartsolar.local",
            FullName = "Technician One",
            PasswordHash = "hash"
        };
        var otherTech = new User
        {
            Id = _otherTechId,
            Email = "othertech@smartsolar.local",
            FullName = "Technician Two",
            PasswordHash = "hash"
        };
        var customer = new User
        {
            Id = _customerId,
            Email = "cust@smartsolar.local",
            FullName = "Customer Name",
            PasswordHash = "hash",
            CustomerProfile = new CustomerProfile
            {
                Id = Guid.NewGuid(),
                UserId = _customerId,
                FullName = "Customer Name",
                PhoneNumber = "+94770000000"
            }
        };

        var survey = new SolarSurvey
        {
            Id = _surveyId,
            CustomerId = customer.CustomerProfile.Id,
            MonthlyKwh = 1200,
            RoofAreaSqm = 80,
            GridType = GridType.SinglePhase,
            PropertyAddress = "45 Lake Road, Colombo"
        };

        var technicianRole = new Role { Name = RoleConstants.FieldTechnician };
        tech.UserRoles.Add(new UserRole { UserId = tech.Id, Role = technicianRole });
        otherTech.UserRoles.Add(new UserRole { UserId = otherTech.Id, Role = technicianRole });
        _db.Users.AddRange(tech, otherTech, customer);
        _db.SolarSurveys.Add(survey);
        _db.SaveChanges();

        // Setup file storage mock
        _fileStorageMock
            .Setup(x => x.SaveFileAsync(It.IsAny<Stream>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync("/uploads/site-photos/sample.jpg");

        // Setup default AI compliance mock
        _aiMock
            .Setup(x => x.ExecuteComplianceEvaluationAsync(It.IsAny<object>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new EvaluateComplianceResponseDto(
                WorkflowId: "wf-comp-test",
                GridCompliant: true,
                ComplianceStatus: "COMPLIANT",
                RiskLevel: "LOW",
                Violations: new List<string>(),
                Recommendations: new List<string> { "Grid voltage stable" },
                ValidationStatus: "PASSED",
                Notes: "Passed all checks",
                ExecutionLogs: new List<ComplianceExecutionLogDto>
                {
                    new("GridComplianceAgent", "evaluation", "completed", "Compliant", null, 1)
                }
            ));
    }

    [Fact]
    public async Task TechnicianOptions_ExcludeInactiveAndNonTechnicians_AndAssignmentRejectsThem()
    {
        var inactive = await _db.Users.FindAsync(_otherTechId);
        inactive!.IsActive = false;
        await _db.SaveChangesAsync();
        var service = CreateService();
        var options = await service.GetAvailableTechniciansAsync();
        Assert.Equal(_techId, Assert.Single(options).Id);
        await Assert.ThrowsAsync<ArgumentException>(() => service.CreateOrAssignJobAsync(new(_surveyId, _customerId, null)));
        await Assert.ThrowsAsync<ArgumentException>(() => service.CreateOrAssignJobAsync(new(_surveyId, _otherTechId, null)));
        Assert.Empty(_db.FieldJobs);
        var job = await service.CreateOrAssignJobAsync(new(_surveyId, _techId, null));
        await Assert.ThrowsAsync<ArgumentException>(() => service.AssignJobAsync(job.Id, new(_customerId, null)));
        Assert.Equal(_techId, (await service.GetJobByIdAsync(job.Id))!.TechnicianId);
    }

    private FieldJobService CreateService() =>
        new(_db, _aiMock.Object, _fileStorageMock.Object, _loggerMock.Object);

    [Fact]
    public async Task CreateJob_NotifiesAssignedTechnician()
    {
        var notifications = new NotificationService(_db);
        var service = new FieldJobService(_db, _aiMock.Object, _fileStorageMock.Object, _loggerMock.Object, notifications);

        var job = await service.CreateOrAssignJobAsync(new CreateFieldJobDto(_surveyId, _techId, null));

        var item = Assert.Single(await notifications.GetForUserAsync(_techId));
        Assert.Equal("FIELD_JOB_ASSIGNED", item.Type);
        Assert.Equal(job.Id, item.EntityId);
        Assert.False(item.IsRead);
    }

    [Fact]
    public async Task VisitLifecycle_NotifiesCustomerAtEachImportantStage()
    {
        var notifications = new NotificationService(_db);
        var service = new FieldJobService(
            _db, _aiMock.Object, _fileStorageMock.Object, _loggerMock.Object, notifications);
        var scheduledAt = DateTime.UtcNow.AddDays(1);

        var job = await service.CreateOrAssignJobAsync(
            new CreateFieldJobDto(_surveyId, _techId, scheduledAt));
        await service.UpdateJobStatusAsync(job.Id, _techId, FieldJobStatus.Accepted);
        await service.UpdateJobStatusAsync(job.Id, _techId, FieldJobStatus.InProgress);
        await service.CheckInAsync(job.Id, _techId, new CheckInDto(6.9271m, 79.8612m));
        await service.CheckInAsync(job.Id, _techId, new CheckInDto(6.9272m, 79.8613m));

        var customerNotifications = await notifications.GetForUserAsync(_customerId);
        Assert.Contains(customerNotifications, item =>
            item.Type == "FIELD_VISIT_SCHEDULED" &&
            item.Message.Contains("Technician One") &&
            item.Message.Contains("Sri Lanka time"));
        Assert.Contains(customerNotifications, item => item.Type == "VISIT_CONFIRMED");
        Assert.Contains(customerNotifications, item => item.Type == "TECHNICIAN_ON_THE_WAY");
        Assert.Single(customerNotifications.Where(item => item.Type == "TECHNICIAN_ARRIVED"));
    }

    [Fact]
    public async Task InspectionGallery_ReturnsUploadedPhotoOnlyForMatchingSurveyAndJob()
    {
        var service = CreateService();
        var job = await service.CreateOrAssignJobAsync(new(_surveyId, _techId, null));
        using var stream = new MemoryStream(new byte[] { 1, 2, 3 });
        await service.UploadPhotoAsync(job.Id, _techId, SitePhotoType.Roof, stream, "roof.jpg");
        var bySurvey = Assert.Single(await service.GetInspectionPhotosAsync(_surveyId, null));
        Assert.Equal("Roof", bySurvey.PhotoType);
        Assert.Equal("Technician One", bySurvey.TechnicianName);
        Assert.Equal(job.Id, bySurvey.FieldJobId);
        Assert.Equal(bySurvey.Id, Assert.Single(await service.GetInspectionPhotosAsync(null, job.Id)).Id);
        Assert.Empty(await service.GetInspectionPhotosAsync(Guid.NewGuid(), null));
        Assert.Empty(await service.GetInspectionPhotosAsync(null, Guid.NewGuid()));
        await Assert.ThrowsAsync<ArgumentException>(() => service.GetInspectionPhotosAsync(null, null));
    }

    [Fact]
    public async Task CreateOrAssignJob_CreatesJobWithAssignedStatus()
    {
        var service = CreateService();
        var dto = new CreateFieldJobDto(
            SolarSurveyId: _surveyId,
            TechnicianId: _techId,
            ScheduledAt: DateTime.UtcNow.AddDays(1),
            Priority: FieldJobPriority.High
        );

        var job = await service.CreateOrAssignJobAsync(dto);

        Assert.NotNull(job);
        Assert.Equal(FieldJobStatus.Assigned, job.Status);
        Assert.Equal(_techId, job.TechnicianId);
        Assert.Equal(FieldJobPriority.High, job.Priority);
    }

    [Fact]
    public async Task CheckIn_SetsCoordinatesAndMovesJobToInProgress()
    {
        var service = CreateService();
        var job = await service.CreateOrAssignJobAsync(new CreateFieldJobDto(_surveyId, _techId, null));

        var inspection = await service.CheckInAsync(job.Id, _techId, new CheckInDto(6.9271m, 79.8612m));

        Assert.NotNull(inspection);
        Assert.Equal(6.9271m, inspection.CheckInLatitude);
        Assert.Equal(79.8612m, inspection.CheckInLongitude);

        var updatedJob = await service.GetJobByIdAsync(job.Id);
        Assert.Equal(FieldJobStatus.InProgress, updatedJob!.Status);
    }

    [Fact]
    public async Task SaveInspectionDraftAndTelemetry_PersistsCorrectly()
    {
        var service = CreateService();
        var job = await service.CreateOrAssignJobAsync(new CreateFieldJobDto(_surveyId, _techId, null));
        await service.CheckInAsync(job.Id, _techId, new CheckInDto(6.9271m, 79.8612m));

        var draftDto = new SaveSiteInspectionDto(
            RoofAreaMeasuredSqm: 82.5m,
            RoofOrientation: RoofOrientation.South,
            RoofTilt: 15.0m,
            GridTypeObserved: GridType.SinglePhase,
            PhaseCount: 1,
            MainBreakerRating: 40.0m,
            InverterLocationSuitable: true,
            SafetyNotes: "Clear ladder access",
            TechnicianNotes: "Service meter is easily accessible"
        );

        var inspection = await service.SaveInspectionDraftAsync(job.Id, _techId, draftDto);
        Assert.NotNull(inspection);
        Assert.Equal(82.5m, inspection.RoofAreaMeasuredSqm);
        Assert.True(inspection.InverterLocationSuitable);

        var telemetry = await service.RecordTelemetryAsync(job.Id, _techId, new RecordTelemetryDto(MeasurementType.GridVoltage, 230.5m, "V"));
        Assert.NotNull(telemetry);
        Assert.Equal(230.5m, telemetry.MeasurementValue);

        var reloadedJob = await service.GetJobByIdAsync(job.Id, _techId);
        Assert.NotNull(reloadedJob!.Inspection);
        Assert.Equal(82.5m, reloadedJob.Inspection.RoofAreaMeasuredSqm);
        Assert.Equal(15.0m, reloadedJob.Inspection.RoofTilt);
        Assert.Equal(40.0m, reloadedJob.Inspection.MainBreakerRating);
        Assert.Equal("Clear ladder access", reloadedJob.Inspection.SafetyNotes);
        Assert.Contains(reloadedJob.Inspection.Telemetry,
            reading => reading.MeasurementType == MeasurementType.GridVoltage &&
                       reading.MeasurementValue == 230.5m);
    }

    [Fact]
    public async Task PhotoUpload_UsesFileStorageAndSavesPhotoEntity()
    {
        var service = CreateService();
        var job = await service.CreateOrAssignJobAsync(new CreateFieldJobDto(_surveyId, _techId, null));

        using var ms = new MemoryStream(new byte[] { 1, 2, 3 });
        var photo = await service.UploadPhotoAsync(job.Id, _techId, SitePhotoType.Roof, ms, "roof.jpg");

        Assert.NotNull(photo);
        Assert.Equal("/uploads/site-photos/sample.jpg", photo.FileUrl);
        Assert.Equal(SitePhotoType.Roof, photo.PhotoType);
    }

    [Fact]
    public async Task SubmitInspection_TriggersComplianceEvaluation_AndCompletesJob()
    {
        var service = CreateService();
        var job = await service.CreateOrAssignJobAsync(new CreateFieldJobDto(_surveyId, _techId, null));
        await service.CheckInAsync(job.Id, _techId, new CheckInDto(6.9271m, 79.8612m));
        await service.RecordTelemetryAsync(job.Id, _techId, new RecordTelemetryDto(MeasurementType.GridVoltage, 230m, "V"));
        await service.RecordTelemetryAsync(job.Id, _techId, new RecordTelemetryDto(MeasurementType.GridFrequency, 50m, "Hz"));

        var result = await service.SubmitInspectionAsync(job.Id, _techId);

        Assert.NotNull(result);
        Assert.Equal(InspectionStatus.Submitted, result.InspectionStatus);

        _aiMock.Verify(x => x.ExecuteComplianceEvaluationAsync(It.IsAny<object>(), It.IsAny<CancellationToken>()), Times.Once);

        var finalJob = await service.GetJobByIdAsync(job.Id);
        Assert.Equal(FieldJobStatus.ComplianceComplete, finalJob!.Status);
        Assert.NotNull(finalJob.Compliance);
        Assert.True(finalJob.Compliance.GridCompliant);
    }

    [Fact]
    public async Task ComplianceCompleteJob_LocksInspectionEvidenceAndReadings()
    {
        var service = CreateService();
        var job = await service.CreateOrAssignJobAsync(
            new CreateFieldJobDto(_surveyId, _techId, null));
        await service.CheckInAsync(job.Id, _techId,
            new CheckInDto(6.9271m, 79.8612m));
        await service.SubmitInspectionAsync(job.Id, _techId);

        var draft = new SaveSiteInspectionDto(
            80, RoofOrientation.South, 15, GridType.SinglePhase,
            1, 40, true, "Safe", "Complete");
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.SaveInspectionDraftAsync(job.Id, _techId, draft));
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.RecordTelemetryAsync(job.Id, _techId,
                new RecordTelemetryDto(MeasurementType.GridVoltage, 230, "V")));
        await using var photo = new MemoryStream(new byte[] { 1, 2, 3 });
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.UploadPhotoAsync(job.Id, _techId,
                SitePhotoType.Roof, photo, "roof.jpg"));
    }

    [Fact]
    public async Task NonCompliantTelemetry_TransitionsJobToFailed()
    {
        _aiMock
            .Setup(x => x.ExecuteComplianceEvaluationAsync(It.IsAny<object>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new EvaluateComplianceResponseDto(
                WorkflowId: "wf-comp-fail",
                GridCompliant: false,
                ComplianceStatus: "NON_COMPLIANT",
                RiskLevel: "HIGH",
                Violations: new List<string> { "Grid voltage 260V exceeds threshold" },
                Recommendations: new List<string> { "Install AVR" },
                ValidationStatus: "PASSED",
                Notes: "Voltage violation",
                ExecutionLogs: new List<ComplianceExecutionLogDto>
                {
                    new("GridComplianceAgent", "evaluation", "completed", "Non-compliant", null, 1)
                }
            ));

        var service = CreateService();
        var job = await service.CreateOrAssignJobAsync(new CreateFieldJobDto(_surveyId, _techId, null));
        await service.CheckInAsync(job.Id, _techId, new CheckInDto(6.9271m, 79.8612m));

        await service.SubmitInspectionAsync(job.Id, _techId);

        var finalJob = await service.GetJobByIdAsync(job.Id);
        Assert.Equal(FieldJobStatus.Failed, finalJob!.Status);
        Assert.NotNull(finalJob.Compliance);
        Assert.False(finalJob.Compliance.GridCompliant);
    }

    [Fact]
    public async Task ComplianceAgentUnavailable_FailsWithoutCreatingLocalAssessment()
    {
        _aiMock
            .Setup(x => x.ExecuteComplianceEvaluationAsync(It.IsAny<object>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((EvaluateComplianceResponseDto?)null);

        var service = CreateService();
        var job = await service.CreateOrAssignJobAsync(new CreateFieldJobDto(_surveyId, _techId, null));
        await service.CheckInAsync(job.Id, _techId, new CheckInDto(6.9271m, 79.8612m));

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.SubmitInspectionAsync(job.Id, _techId));

        Assert.Contains("GridComplianceAgent", error.Message);
        Assert.Empty(await _db.ComplianceAssessments.ToListAsync());
        Assert.Equal(FieldJobStatus.Failed, (await _db.FieldJobs.FindAsync(job.Id))!.Status);
    }

    [Fact]
    public async Task FailedComplianceSubmission_CanBeRetriedWhenAgentRecovers()
    {
        _aiMock
            .SetupSequence(x => x.ExecuteComplianceEvaluationAsync(
                It.IsAny<object>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((EvaluateComplianceResponseDto?)null)
            .ReturnsAsync(new EvaluateComplianceResponseDto(
                WorkflowId: "wf-comp-retry",
                GridCompliant: true,
                ComplianceStatus: "COMPLIANT",
                RiskLevel: "LOW",
                Violations: new List<string>(),
                Recommendations: new List<string> { "Retry completed" },
                ValidationStatus: "PASSED",
                Notes: "Agent recovered",
                ExecutionLogs: new List<ComplianceExecutionLogDto>
                {
                    new("GridComplianceAgent", "evaluation", "completed", "Compliant", null, 1)
                }
            ));

        var service = CreateService();
        var job = await service.CreateOrAssignJobAsync(new CreateFieldJobDto(_surveyId, _techId, null));
        await service.CheckInAsync(job.Id, _techId, new CheckInDto(6.9271m, 79.8612m));

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.SubmitInspectionAsync(job.Id, _techId));
        Assert.Equal(FieldJobStatus.Failed, (await _db.FieldJobs.FindAsync(job.Id))!.Status);

        var result = await service.SubmitInspectionAsync(job.Id, _techId);

        Assert.NotNull(result);
        var completedJob = await service.GetJobByIdAsync(job.Id);
        Assert.Equal(FieldJobStatus.ComplianceComplete, completedJob!.Status);
        Assert.Equal("wf-comp-retry", completedJob.Compliance!.WorkflowId);
        _aiMock.Verify(x => x.ExecuteComplianceEvaluationAsync(
            It.IsAny<object>(), It.IsAny<CancellationToken>()), Times.Exactly(2));
    }
}
