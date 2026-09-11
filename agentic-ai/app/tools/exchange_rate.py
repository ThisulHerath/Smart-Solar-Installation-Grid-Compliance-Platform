"""One allow-listed public endpoint; no user data or arbitrary URLs are accepted."""
from datetime import datetime, timezone, timedelta
from decimal import Decimal
import threading
import httpx
from app.schemas.pricing_schemas import ExchangeRate

ENDPOINT = "https://open.er-api.com/v6/latest/USD"
_cached: ExchangeRate | None = None
_cached_at: datetime | None = None
_lock = threading.Lock()


def validate_rate(rate: ExchangeRate) -> ExchangeRate:
    now = datetime.now(timezone.utc)
    if rate.timestamp.tzinfo is None or not now - timedelta(hours=48) <= rate.timestamp <= now + timedelta(minutes=5):
        raise ValueError("Exchange rate timestamp is stale or invalid")
    return rate


def get_usd_to_lkr_exchange_rate(base: str = "USD", target: str = "LKR") -> ExchangeRate:
    if base != "USD" or target != "LKR":
        raise ValueError("Only USD to LKR is permitted")
    global _cached, _cached_at
    with _lock:
        if _cached and _cached_at and datetime.now(timezone.utc) - _cached_at < timedelta(hours=1):
            return validate_rate(_cached)
        # Redirects are disabled to preserve the endpoint allow-list.
        with httpx.Client(timeout=8, follow_redirects=False) as client:
            response = client.get(ENDPOINT)
            response.raise_for_status()
            data = response.json()
        if data.get("result") != "success" or data.get("base_code") != "USD":
            raise ValueError("Invalid exchange provider response")
        rate = validate_rate(ExchangeRate(rate=Decimal(str(data["rates"]["LKR"])), timestamp=datetime.fromtimestamp(data["time_last_update_unix"], timezone.utc)))
        _cached, _cached_at = rate, datetime.now(timezone.utc)
        return rate
