# Customer Survey Design

Phase 2 adds `CustomerProfile`, `SolarSurvey`, `SolarSurveyImage`, and `AgentWorkflow` to the existing User model. Surveys belong to a customer profile and workflows belong to surveys. Image rows store provider-neutral metadata, not binary content. EF Core migration `AddCustomerSurveyPhase2` is additive and must be applied to Neon through the deployment process.

Survey status is controlled by the backend: Draft -> Submitted -> Processing -> AnalysisComplete, with Processing -> Failed on an AI or validation error.
