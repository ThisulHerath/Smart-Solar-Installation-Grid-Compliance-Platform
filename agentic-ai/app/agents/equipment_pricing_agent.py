"""Equipment pricing specialist. It has no database or reservation capabilities."""
from decimal import Decimal, ROUND_HALF_UP
from app.schemas.pricing_schemas import PricingRequest, ExchangeRate, PriceLine

class EquipmentPricingAgent:
    def evaluate(self, request: PricingRequest, rate: ExchangeRate) -> list[PriceLine]:
        lines = []
        for item in request.items:
            unit = (item.unitPriceUsd * rate.rate).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
            lines.append(PriceLine(inventoryItemId=item.inventoryItemId, name=item.name, category=item.category,
                quantity=item.quantity, unitPriceUsd=item.unitPriceUsd, unitPriceLkr=unit, totalPriceLkr=unit * item.quantity))
        return lines

    def execute(self, state):
        # Legacy callers without validated catalog inputs must not receive invented prices.
        return {"tool_results": {**state.get("tool_results", {}), "equipment_pricing": {
            "status": "INPUT_REQUIRED", "message": "Use the validated equipment-pricing workflow with approved proposal and catalog inputs."}},
            "completed_steps": state.get("completed_steps", []),
            "execution_logs": state.get("execution_logs", []) + ["EquipmentPricingAgent: catalog input required"]}
