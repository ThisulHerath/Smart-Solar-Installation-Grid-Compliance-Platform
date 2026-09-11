from datetime import datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class PricingItem(BaseModel):
    model_config = ConfigDict(extra="forbid")
    inventoryItemId: UUID
    name: str = Field(min_length=1, max_length=200)
    category: Literal["PANEL", "INVERTER"]
    quantity: int = Field(gt=0, le=20000)
    unitPriceUsd: Decimal = Field(gt=0, le=10000000)
    availableQuantity: int = Field(ge=0)
    capacityWatts: Decimal = Field(gt=0)


class PricingRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    proposalId: UUID
    recommendedKw: Decimal = Field(gt=0, le=10000)
    items: list[PricingItem] = Field(min_length=2, max_length=2)


class ExchangeRate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    baseCurrency: Literal["USD"] = "USD"
    targetCurrency: Literal["LKR"] = "LKR"
    rate: Decimal = Field(gt=0, le=1000000, allow_inf_nan=False)
    timestamp: datetime


class PriceLine(BaseModel):
    inventoryItemId: UUID
    name: str
    category: Literal["PANEL", "INVERTER"]
    quantity: int
    unitPriceUsd: Decimal
    unitPriceLkr: Decimal
    totalPriceLkr: Decimal


class PricingResponse(BaseModel):
    status: Literal["VALIDATED"] = "VALIDATED"
    exchangeRate: Decimal
    rateTimestamp: datetime
    baseCurrency: Literal["USD"] = "USD"
    targetCurrency: Literal["LKR"] = "LKR"
    totalPriceLkr: Decimal
    lines: list[PriceLine]
    executionLogs: list[str]
