import os
from fastapi import FastAPI, Header, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from app.schemas.state import WorkflowExecutionRequest, WorkflowExecutionResponse, SolarSizingResponse
from app.schemas.compliance_schemas import ComplianceEvaluationResponse
from app.schemas.guardrail_schemas import GuardrailWorkflowResult
from app.workflow.graph import run_solar_workflow
from app.workflow.solar_sizing import run_solar_sizing
from app.workflow.compliance_workflow import run_compliance_evaluation
from app.workflow.proposal_workflow import run_guardrail_workflow

load_dotenv()

app = FastAPI(
    title="Smart Solar Agentic AI Service",
    description="Internal LangGraph multi-agent service for Solar Planning and Grid Compliance",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

INTERNAL_KEY = os.getenv("AGENTIC_AI_INTERNAL_KEY")

@app.get("/health", tags=["Health"])
def health_check():
    return {
        "status": "healthy",
        "service": "agentic-ai",
        "agents": [
            "PlannerAgent",
            "GridComplianceAgent",
            "EquipmentPricingAgent",
            "SafetyGuardrailAgent"
        ]
    }

@app.post("/workflow/test", response_model=WorkflowExecutionResponse, tags=["Workflow"])
def test_workflow(
    request: WorkflowExecutionRequest,
    x_internal_key: str = Header(None, alias="X-Internal-Key")
):
    # Optional security check for internal communication
    if INTERNAL_KEY and x_internal_key != INTERNAL_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid internal authorization key."
        )

    try:
        raw_result = run_solar_workflow(
            objective=request.objective,
            customer_id=request.customer_id,
            input_data=request.input_data
        )

        return WorkflowExecutionResponse(
            workflow_id=raw_result.get("workflow_id", ""),
            customer_id=raw_result.get("customer_id"),
            objective=raw_result.get("objective", request.objective),
            plan=raw_result.get("plan", []),
            current_step=raw_result.get("current_step", "completed"),
            completed_steps=raw_result.get("completed_steps", []),
            tool_results=raw_result.get("tool_results", {}),
            validation_results=raw_result.get("validation_results", {}),
            errors=raw_result.get("errors", []),
            approval_status=raw_result.get("approval_status", "pending_engineer_review"),
            final_outcome=raw_result.get("final_outcome", ""),
            execution_logs=raw_result.get("execution_logs", [])
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Agentic workflow execution failed."
        )

@app.post("/workflow/solar-sizing", response_model=SolarSizingResponse, tags=["Workflow"])
def solar_sizing_workflow(request: dict, x_internal_key: str = Header(None, alias="X-Internal-Key")):
    if INTERNAL_KEY and x_internal_key != INTERNAL_KEY:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid internal authorization key.")
    return run_solar_sizing(request)

@app.post("/workflow/compliance", response_model=ComplianceEvaluationResponse, tags=["Workflow"])
@app.post("/api/v1/compliance/evaluate", response_model=ComplianceEvaluationResponse, tags=["Workflow"])
def compliance_evaluation_workflow(request: dict, x_internal_key: str = Header(None, alias="X-Internal-Key")):
    if INTERNAL_KEY and x_internal_key != INTERNAL_KEY:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid internal authorization key.")
    return run_compliance_evaluation(request)

@app.post("/workflow/guardrail", response_model=GuardrailWorkflowResult, tags=["Workflow"])
def guardrail_workflow(request: dict, x_internal_key: str = Header(None, alias="X-Internal-Key")):
    """
    Phase 4: SafetyGuardrailAgent + DeterministicProposalValidator pipeline.
    Called by ASP.NET Core when creating an engineering proposal.
    AI CANNOT approve a proposal — only the deterministic validator + human engineer can.
    """
    if INTERNAL_KEY and x_internal_key != INTERNAL_KEY:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid internal authorization key.")
    return run_guardrail_workflow(request)
