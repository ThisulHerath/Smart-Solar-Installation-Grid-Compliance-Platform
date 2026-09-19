"""Measured stage events. Metadata only: no request bodies, secrets or notes."""
from contextlib import contextmanager
from datetime import datetime, timezone
from time import perf_counter
from uuid import uuid4


@contextmanager
def trace_stage(logs: list, workflow_id: str, agent: str, step: str):
    event = {"trace_id": workflow_id, "span_id": uuid4().hex, "agent_name": agent,
             "step_name": step, "started_at": datetime.now(timezone.utc).isoformat(),
             "status": "completed", "retry_count": 0, "output_summary": f"{step} completed."}
    started = perf_counter()
    try:
        yield event
    except Exception:
        event.update(status="failed", output_summary=f"{step} failed.", error_message="Stage could not complete. Review server diagnostics.")
        raise
    finally:
        event["completed_at"] = datetime.now(timezone.utc).isoformat()
        event["duration_ms"] = round((perf_counter() - started) * 1000, 3)
        logs.append(event)


class StageFailure(Exception):
    def __init__(self, logs):
        super().__init__("Workflow stage failed.")
        self.logs = logs


def measured_node(agent, step, action):
    def run(state):
        logs = [dict(entry) for entry in state.get("execution_logs", []) if isinstance(entry, dict)]
        try:
            with trace_stage(logs, state["workflow_id"], agent, step) as event:
                result = action(state)
                if result.get("validation_results"):
                    event["validation_result"] = result["validation_results"]
                if result.get("current_step") == "FAILED":
                    event.update(status="failed", output_summary="Deterministic validation rejected the result.")
        except Exception as error:
            raise StageFailure(logs) from error
        return {**result, "execution_logs": logs}
    return run
