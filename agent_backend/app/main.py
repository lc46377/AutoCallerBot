# app/main.py
import uuid
from typing import Dict, Any
from fastapi import FastAPI, HTTPException, Body
from .models import StartBody, ReplyBody, SessionState
from .wizard import missing_fields, resolve_target_number, build_call_vars, should_suppress
from .llm import extract_fields, extract_fields_with_debug, compose_multi_question
from .vapi_client import start_vendor_call, hangup_call
from .config import (
    DEFAULT_USER_PHONE,
    USE_LLM,
    OPENAI_API_KEY,
    DEFAULT_TARGET_NUMBER,  # NEW
)

app = FastAPI()
SESS: Dict[str, SessionState] = {}

def _merge(d: Dict[str, Any], add: Dict[str, Any], overwrite: bool = False):
    for k, v in (add or {}).items():
        if v in (None, "", []):
            continue
        if overwrite or (k not in d) or (not d[k]) or d[k] == "+1":
            d[k] = v

def _apply_intent(sess: SessionState):
    """
    Freeze a specific intent once chosen; do not downgrade to generic_query later.
    """
    cur = sess.data.get("intent")
    if cur in ("retail_return", "hotel_booking", "rental_issue"):
        return
    # legacy goal -> intent fallback
    g = (sess.data.get("goal") or "").lower()
    if g in ("refund", "replacement", "return", "exchange"):
        sess.data["intent"] = "retail_return"
    # else: keep whatever extractor set (possibly generic_query)

@app.get("/health")
def health():
    return {"ok": True}

@app.post("/intake/start")
def intake_start(body: StartBody):
    sid = str(uuid.uuid4())
    sess = SessionState(data={}, ask_counts={})
    SESS[sid] = sess
    d = sess.data

    # explicit prefills
    _merge(d, body.model_dump(exclude_none=True))

    # LLM extraction (one pass)
    if body.utterance:
        _merge(d, extract_fields(body.utterance), overwrite=True)

    _apply_intent(sess)
    d.setdefault("user_phone", DEFAULT_USER_PHONE)

    missing = missing_fields(d, d.get("intent"))

    # If nothing essential is missing, dial immediately using resolved or fallback number
    if not missing:
        to_number = resolve_target_number(d) or DEFAULT_TARGET_NUMBER
        # persist what we dial for clarity/debug/vapi vars
        d.setdefault("target_number", to_number)
        call_id = start_vendor_call(to_number, build_call_vars(d))
        sess.call_id = call_id
        return {
            "session_id": sid,
            "next_fields": [],
            "question": "Calling the company now.",
            "call_id": call_id,
        }

    # record ask counts for suppression later
    for f in missing:
        sess.ask_counts[f] = sess.ask_counts.get(f, 0) + 1

    q = compose_multi_question(missing, d)
    return {"session_id": sid, "next_fields": missing, "question": q}

# app/main.py

INTENT_FIELD_WHITELIST = {
    "retail_return": {
        "intent","vendor_name","target_number","user_phone",
        "order_id","date_of_purchase","bill_amount","item","reason",
    },
    "hotel_booking": {
        "intent","vendor_name","hotel_name","city","stay_start","stay_end","nights",
        "ask_price","ask_discounts","question","target_number","user_phone",
    },
    "rental_issue": {
        "intent","vendor_name","target_number","user_phone",
        "rental_agreement_number","car_issue",
    },
    "service_booking": {
        "intent","vendor_name","service_type","preferred_time","ask_availability",
        "question","target_number","user_phone",
    },
    "generic_query": {
        "intent","vendor_name","question","target_number","user_phone",
    },
}

def _prune_by_intent(d: Dict[str, Any], intent: str | None) -> None:
    """Drop fields that don't belong to the new intent to avoid cross-talk."""
    if not intent:
        return
    keep = INTENT_FIELD_WHITELIST.get(intent)
    if not keep:
        return
    for k in list(d.keys()):
        if k not in keep and k not in ("goal",):  # keep 'goal' only for legacy mapping
            d.pop(k, None)

@app.post("/intake/reply")
def intake_reply(body: ReplyBody):
    sess = SESS.get(body.session_id)
    if not sess:
        raise HTTPException(404, "Unknown session_id")
    d = sess.data

    extracted = extract_fields(body.answer or "")
    print("=== EXTRACTED FROM ANSWER ===", extracted)

    prev_intent = d.get("intent")

    # Accept new info (overwrite wins)
    _merge(d, extracted, overwrite=True)

    # Preserve specific intent; block accidental downgrade to generic_query
    if prev_intent in ("retail_return", "hotel_booking", "rental_issue", "service_booking") and d.get("intent") == "generic_query":
        d["intent"] = prev_intent

    # If the user truly switched intents mid-flow, prune unrelated fields
    if d.get("intent") and prev_intent and d.get("intent") != prev_intent:
        _prune_by_intent(d, d.get("intent"))

    _apply_intent(sess)

    # Figure out what's still missing; suppress fields we've asked > cap
    missing_all = missing_fields(d, d.get("intent"))
    missing = [f for f in missing_all if not should_suppress(f, sess.ask_counts)]

    if missing:
        for f in missing:
            sess.ask_counts[f] = sess.ask_counts.get(f, 0) + 1
        q = compose_multi_question(missing, d)
        return {"done": False, "next_fields": missing, "question": q}

    # ===== READY TO DIAL =====
    # Choose number (resolved or fallback) and persist what we’ll dial
    to_number = resolve_target_number(d) or DEFAULT_TARGET_NUMBER
    d.setdefault("target_number", to_number)

    # 1) Build full call vars from the *current* state
    call_vars = build_call_vars(d)

    # 2) CLEAR MEMORY BEFORE CALL: keep only minimal session fields
    minimal = {}
    for k in (
        "intent", "vendor_name", "hotel_name", "service_type",
        "preferred_time", "ask_availability", "question",
        "user_phone", "target_number"
    ):
        if d.get(k) not in (None, "", []):
            minimal[k] = d[k]
    sess.data = minimal  # drop everything else to avoid leakage across tasks

    # 3) Place the call
    call_id = start_vendor_call(to_number, call_vars)
    sess.call_id = call_id
    return {"done": True, "message": "Calling the company now.", "call_id": call_id}


@app.post("/intake/reset")
def intake_reset(session_id: str = Body(...)):
    if session_id in SESS:
        SESS[session_id].data.clear()
        SESS[session_id].ask_counts.clear()
        SESS[session_id].call_id = None
    return {"ok": True, "cleared": session_id}

@app.post("/debug/extract")
def debug_extract(text: str = Body(..., embed=True)):
    dbg = extract_fields_with_debug(text)
    return {
        "USE_LLM": USE_LLM,
        "has_key": bool(OPENAI_API_KEY),
        "pass": dbg.get("pass"),
        "raw": dbg.get("raw"),
        "extracted": dbg.get("fields"),
    }

@app.post("/call/hangup")
def call_hangup(session_id: str = Body(None), call_id: str = Body(None)):
    if session_id and not call_id:
        sess = SESS.get(session_id)
        if not sess or not sess.call_id:
            raise HTTPException(404, "Unknown session or no active call for that session_id")
        call_id = sess.call_id
    if not call_id:
        raise HTTPException(400, "Provide session_id or call_id")
    ok = hangup_call(call_id)
    if not ok:
        raise HTTPException(502, "Failed to end call (no controlUrl or POST failed)")
    return {"ok": True, "ended": True, "call_id": call_id}
