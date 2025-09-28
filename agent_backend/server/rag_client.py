# app/rag_client.py
import os
import httpx

BASE = os.getenv("RAG_SERVICE_URL", "http://localhost:8001")

async def _post(path: str, payload: dict) -> dict:
    """POST helper with graceful fallback if Person B's service is down."""
    url = f"{BASE}{path}"
    try:
        async with httpx.AsyncClient(timeout=5.0) as c:
            r = await c.post(url, json=payload)
            r.raise_for_status()
            return r.json()
    except Exception:
        # Fallbacks so your FSM can still run the demo with the TwiML mock.
        if path == "/check_missing":
            return {"status": "ready", "missing_fields": [], "call_reason_summary": "Proceed with call."}
        if path == "/retrieve":
            # Minimal shape your planner expects: citations live under 'call_brief'
            return {
                "status": "ok",
                "selected_chunks": [],
                "call_brief": {
                    "key_points": [],
                    "required_identifiers": payload.get("brief", {}).get("identifiers", {}).keys(),
                    "agents_notes": ""
                }
            }
        if path == "/plan":
            brief = payload.get("brief", {})
            pin = (brief.get("auth") or {}).get("pin", "")
            order_id = (brief.get("identifiers") or {}).get("order_id", "ORDER-XXXX")
            opening = (
                f"Hi, I’m Mercury, authorized assistant for the customer. "
                f"{'I can verify with passcode ' + str(pin) + '. ' if pin else ''}"
                f"We’re calling about {order_id}: {brief.get('reason','an issue')}."
            )
            return {
                "opening": opening,
                "citations": [],
                "ivr_keywords": ["returns", "online order", "customer care"],
                "negotiation_ladder": [
                    "Primary ask: prepaid return label and refund to original payment method."
                ],
                "confirmation_checklist": [
                    "ticket_id","refund_amount","refund_method","SLA_date",
                    "rep_name_or_id","confirmation_email"
                ],
                "risk_flags": []
            }
        # Generic fallback
        return {}

async def check_missing(brief: dict) -> dict:
    """Person B endpoint: decide if we have enough info to call."""
    return await _post("/check_missing", {"brief": brief})

async def retrieve_context(brief: dict) -> dict:
    """Person B endpoint: return policy context/call_brief."""
    return await _post("/retrieve", {"brief": brief})

async def make_plan(brief: dict, call_brief: dict) -> dict:
    """Person B endpoint: produce opening line, IVR keywords, ladder, checklist."""
    return await _post("/plan", {"brief": brief, "call_brief": call_brief})
