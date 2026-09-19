"""Read-only retrieval over reviewed project notes, not utility regulations or an LLM.

No uploads, arbitrary paths, user records, shell commands or model instructions are
accepted. Versioned passages are the only retrieval source. The same tokenizer is
used on the index and query; generated text is not involved.
"""
from math import log
import re

POLICY_VERSION = "2026-09-16"
PASSAGES = (
    {"id": "sizing", "title": "Preliminary sizing", "source": "project-policy:sizing", "text": "Monthly electricity use in kWh is divided by 120 to estimate kW. Preliminary sizing assumes 400 W panels. This is a planning estimate, not a final installation design."},
    {"id": "grid", "title": "Grid screening", "source": "project-policy:grid", "text": "Project screening uses nominal 230 V single phase or 400 V three phase, with a 6 percent voltage tolerance. Frequency screening is 49.5 to 50.5 Hz. These are university project thresholds, not proof of CEB or LECO approval."},
    {"id": "inspection", "title": "Inspection evidence", "source": "project-policy:inspection", "text": "A site inspection must supply grid voltage, grid frequency, main breaker rating and inverter location suitability. Missing measurements cannot establish compliance. Technician photos are evidence for engineer review."},
    {"id": "approval", "title": "Engineer approval", "source": "project-policy:approval", "text": "A completed compliance assessment and deterministic validation are required before an authorized senior engineer approves a proposal. Unknown grid status is not safe approval. AI cannot approve, reject or bypass this gate."},
    {"id": "pricing", "title": "Equipment pricing", "source": "project-policy:pricing", "text": "The equipment catalog uses 500 W panels and an inverter rated for at least the approved kW. USD prices are converted to LKR using a validated exchange rate. Equipment estimates exclude installation and taxes; expiry and current stock are checked before reservation."},
    {"id": "reservation", "title": "Stock reservation", "source": "project-policy:reservation", "text": "Only approved proposals with validated unexpired equipment quotes may reserve stock. ASP.NET Core rechecks available inventory in a PostgreSQL transaction. Agents cannot change stock. Repeating a successful reservation does not reserve stock twice."},
)


def tokens(text: str) -> set[str]:
    return set(re.findall(r"[a-z0-9]+", text.lower())) - {"the", "a", "an", "is", "to", "and", "of", "in", "for", "what", "how", "can"}


def retrieve_project_guidance(query: str, limit: int = 3) -> list[dict]:
    """Return at most five relevant project passages with source IDs and version.

    An empty list means there is no matching reviewed project evidence. This tool
    never invents an answer and must not be presented as semantic/vector search.
    """
    if not isinstance(query, str) or len(query) > 1000 or not 1 <= limit <= 5:
        raise ValueError("Guidance queries must be at most 1000 characters; limit must be 1–5.")
    terms = tokens(query)
    indexed = [(passage, tokens(passage["title"] + " " + passage["text"])) for passage in PASSAGES]
    ranked = []
    for passage, words in indexed:
        score = sum(log(1 + len(PASSAGES) / sum(term in other for _, other in indexed)) for term in terms & words)
        if score:
            ranked.append((score, passage))
    ranked.sort(key=lambda row: (-row[0], row[1]["id"]))
    return [{**passage, "version": POLICY_VERSION, "score": round(score, 4)} for score, passage in ranked[:limit]]
