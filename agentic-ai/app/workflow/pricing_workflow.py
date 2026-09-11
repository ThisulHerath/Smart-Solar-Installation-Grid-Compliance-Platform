"""Explicit pricing graph. The backend owns persistence and all inventory mutations."""
from decimal import Decimal, ROUND_CEILING, ROUND_HALF_UP
from typing import TypedDict
from langgraph.graph import START, END, StateGraph
from app.schemas.pricing_schemas import PricingRequest, ExchangeRate, PriceLine, PricingResponse
from app.agents.equipment_pricing_agent import EquipmentPricingAgent
from app.tools.exchange_rate import get_usd_to_lkr_exchange_rate, validate_rate


def money(value: Decimal) -> Decimal:
    return value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


class PricingState(TypedDict, total=False):
    request: PricingRequest
    rate: ExchangeRate
    lines: list[PriceLine]
    logs: list[str]
    response: PricingResponse


def requirements(state: PricingState):
    request = state["request"]
    panels = [x for x in request.items if x.category == "PANEL"]
    inverters = [x for x in request.items if x.category == "INVERTER"]
    if len(panels) != 1 or len(inverters) != 1 or len({x.inventoryItemId for x in request.items}) != 2:
        raise ValueError("One panel line and one inverter line required")
    if panels[0].capacityWatts != 500 or panels[0].quantity != int((request.recommendedKw * 2).to_integral_value(rounding=ROUND_CEILING)):
        raise ValueError("Panel requirement does not match project policy")
    if inverters[0].quantity != 1 or inverters[0].capacityWatts < request.recommendedKw * 1000:
        raise ValueError("Inverter does not meet approved capacity")
    return {"logs": ["EquipmentRequirements: validated 500 W panel policy and inverter capacity"]}


def exchange(state: PricingState):
    rate = get_usd_to_lkr_exchange_rate()
    return {"rate": rate, "logs": state["logs"] + ["ExchangeRateTool: validated USD/LKR provider response"]}


def calculate(state: PricingState):
    lines = EquipmentPricingAgent().evaluate(state["request"], state["rate"])
    return {"lines": lines, "logs": state["logs"] + ["EquipmentPricingAgent: computed structured equipment estimate"]}


def validate(state: PricingState):
    rate = validate_rate(state["rate"])
    expected = {x.inventoryItemId: x for x in state["request"].items}
    if len(state["lines"]) != len(expected) or len({x.inventoryItemId for x in state["lines"]}) != len(expected):
        raise ValueError("Missing or duplicate pricing lines")
    for line in state["lines"]:
        item = expected.get(line.inventoryItemId)
        if item is None or line.quantity != item.quantity or line.category != item.category or line.unitPriceUsd != item.unitPriceUsd:
            raise ValueError("Pricing output differs from catalog")
        if line.unitPriceLkr != money(item.unitPriceUsd * rate.rate) or line.totalPriceLkr != money(line.unitPriceLkr * item.quantity):
            raise ValueError("Invalid pricing calculation")
    return {"logs": state["logs"] + ["PricingValidator: independently verified catalog and arithmetic"]}


def availability(state: PricingState):
    if any(x.quantity > x.availableQuantity for x in state["request"].items):
        raise ValueError("Insufficient stock")
    return {"logs": state["logs"] + ["InventoryAvailabilityValidator: snapshot sufficient; backend must recheck on reservation"]}


def output(state: PricingState):
    return {"response": PricingResponse(exchangeRate=state["rate"].rate, rateTimestamp=state["rate"].timestamp,
        totalPriceLkr=sum((x.totalPriceLkr for x in state["lines"]), Decimal(0)), lines=state["lines"],
        executionLogs=state["logs"] + ["FormatResult: return to backend for persistence and staff review"])}


graph = StateGraph(PricingState)
nodes = [("LoadEquipmentRequirements", requirements), ("ExchangeRateTool", exchange), ("EquipmentPricingAgent", calculate),
         ("PricingValidator", validate), ("InventoryAvailabilityValidator", availability), ("FormatResult", output)]
previous = START
for name, action in nodes:
    graph.add_node(name, action)
    graph.add_edge(previous, name)
    previous = name
graph.add_edge(previous, END)
pricing_graph = graph.compile()


def run_pricing_workflow(request: PricingRequest) -> PricingResponse:
    return pricing_graph.invoke({"request": request})["response"]
