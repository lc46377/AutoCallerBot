# app/main.py
import uuid
from typing import Dict, Any, Optional, List
from fastapi import FastAPI, HTTPException, Body, Request
from .models import StartBody, ReplyBody, SessionState
from .wizard import (
    missing_fields,
    resolve_target_number,
    build_call_vars,
    should_suppress,
)
from .llm import extract_fields, extract_fields_with_debug, compose_multi_question
from .vapi_client import start_vendor_call, hangup_call
from .config import (
    DEFAULT_USER_PHONE,
    USE_LLM,
    OPENAI_API_KEY,
    DEFAULT_TARGET_NUMBER,
)

app = FastAPI()
SESS: Dict[str, SessionState] = {}

# ----------------- helpers -----------------

def _merge(d: Dict[str, Any], add: Dict[str, Any], overwrite: bool = False):
    for k, v in (add or {}).items():
        if v in (None, "", []):
            continue
        if overwrite or (k not in d) or (not d[k]) or d[k] == "+1":
            d[k] = v

def _apply_intent(sess: SessionState):
    """Freeze a specific intent once chosen; do not downgrade to generic_query later."""
    cur = sess.data.get("intent")
    if cur in ("retail_return", "hotel_booking", "rental_issue", "service_booking"):
        return
    g = (sess.data.get("goal") or "").lower()
    if g in ("refund", "replacement", "return", "exchange"):
        sess.data["intent"] = "retail_return"

def _find_session_by_call_id(call_id: str) -> Optional[str]:
    if not call_id:
        return None
    for sid, sess in SESS.items():
        if sess.call_id == call_id:
            return sid
    return None

def _find_recent_session() -> Optional[str]:
    # last inserted key (ok for dev)
    return next(reversed(SESS)) if SESS else None

# ----------------- health -----------------

@app.get("/health")
def health():
    return {"ok": True}

# ----------------- intake/start -----------------

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

    if not missing:
        to_number = resolve_target_number(d) or DEFAULT_TARGET_NUMBER
        d.setdefault("target_number", to_number)

        # INCLUDE METADATA → so webhook can map back to the session
        call_id = start_vendor_call(
            to_number,
            {
                **build_call_vars(d),
                "metadata": {
                    "session_id": sid,
                    "vendor_name": d.get("vendor_name"),
                    "goal": d.get("goal"),
                    "intent": d.get("intent"),
                },
            },
        )
        sess.call_id = call_id
        return {
            "session_id": sid,
            "next_fields": [],
            "question": "Calling the company now.",
            "call_id": call_id,
        }

    # record ask counts for suppression
    for f in missing:
        sess.ask_counts[f] = sess.ask_counts.get(f, 0) + 1

    q = compose_multi_question(missing, d)
    return {"session_id": sid, "next_fields": missing, "question": q}

# ----------------- intent-scoped pruning (avoid cross-talk) -----------------

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

def _prune_by_intent(d: Dict[str, Any], intent: Optional[str]) -> None:
    if not intent:
        return
    keep = INTENT_FIELD_WHITELIST.get(intent)
    if not keep:
        return
    for k in list(d.keys()):
        if k not in keep and k not in ("goal",):  # keep legacy 'goal' only for mapping
            d.pop(k, None)

# ----------------- intake/reply -----------------

@app.post("/intake/reply")
def intake_reply(body: ReplyBody):
    sess = SESS.get(body.session_id)
    if not sess:
        raise HTTPException(404, "Unknown session_id")
    d = sess.data

    extracted = extract_fields(body.answer or "")
    print("=== EXTRACTED FROM ANSWER ===", extracted)

    prev_intent = d.get("intent")
    _merge(d, extracted, overwrite=True)

    # prevent accidental downgrade to generic_query
    if prev_intent in ("retail_return","hotel_booking","rental_issue","service_booking") and d.get("intent") == "generic_query":
        d["intent"] = prev_intent

    # prune if user truly switched intents
    if d.get("intent") and prev_intent and d.get("intent") != prev_intent:
        _prune_by_intent(d, d.get("intent"))

    _apply_intent(sess)

    # figure out what's missing and suppress over-asked fields
    missing_all = missing_fields(d, d.get("intent"))
    missing = [f for f in missing_all if not should_suppress(f, sess.ask_counts)]

    if missing:
        for f in missing:
            sess.ask_counts[f] = sess.ask_counts.get(f, 0) + 1
        q = compose_multi_question(missing, d)
        return {"done": False, "next_fields": missing, "question": q}

    # ===== READY TO DIAL =====
    to_number = resolve_target_number(d) or DEFAULT_TARGET_NUMBER
    d.setdefault("target_number", to_number)

    call_vars = build_call_vars(d)

    # clear memory before call: keep only essentials
    minimal: Dict[str, Any] = {}
    for k in (
        "intent", "vendor_name", "hotel_name", "service_type",
        "preferred_time", "ask_availability", "question",
        "user_phone", "target_number", "order_id", "item",
        "reason", "date_of_purchase", "bill_amount", "rental_agreement_number",
        "city", "stay_start", "stay_end", "nights", "ask_price", "ask_discounts",
    ):
        if d.get(k) not in (None, "", []):
            minimal[k] = d[k]
    sess.data = minimal

    call_id = start_vendor_call(
        to_number,
        {
            **call_vars,
            "metadata": {
                "session_id": body.session_id,
                "vendor_name": minimal.get("vendor_name"),
                "goal": minimal.get("intent") or minimal.get("goal"),
                "intent": minimal.get("intent"),
            },
        },
    )
    sess.call_id = call_id
    return {"done": True, "message": "Calling the company now.", "call_id": call_id}

# ----------------- reset -----------------

@app.post("/intake/reset")
def intake_reset(session_id: str = Body(...)):
    if session_id in SESS:
        SESS[session_id].data.clear()
        SESS[session_id].ask_counts.clear()
        SESS[session_id].call_id = None
        SESS[session_id].outbox.clear()
    return {"ok": True, "cleared": session_id}

# ----------------- Vapi webhook → enqueue summary -----------------

# app/main.py (replace your vapi_webhook body with this)
@app.post("/vapi/webhook")
async def vapi_webhook(req: Request):
    payload = await req.json()

    # 1) Extract call_id from any of the known places
    call_id = (
        payload.get("call_id")
        or payload.get("id")
        or (payload.get("call") or {}).get("id")
        or (payload.get("message") or {}).get("callId")
    )

    # 2) Extract session_id from variables/assistantOverrides, if present
    session_id = (
        (((payload.get("variables") or {}).get("metadata")) or {}).get("session_id")
        or ((((payload.get("assistant") or {}).get("assistantOverrides") or {}).get("variableValues") or {}).get("metadata") or {}).get("session_id")
        or (payload.get("metadata") or {}).get("session_id")
        or (payload.get("message") or {}).get("metadata", {}).get("session_id")
    )

    # 3) Find session: prefer by call_id, else by session_id
    sess = None
    if call_id:
        sess = next((s for s in SESS.values() if s.call_id == call_id), None)
    if not sess and session_id:
        sess = SESS.get(session_id)

    if not sess:
        print(f"[/vapi/webhook] no session found (call_id={call_id}, session_id={session_id})")
        return {"ok": True}

    # 4) Extract a human summary from multiple possible shapes
    summary = (
        (payload.get("message") or {}).get("analysis", {}).get("summary")
        or payload.get("summary")
        or payload.get("report")
        or (payload.get("metadata") or {}).get("summary")
        or "Call completed."
    )

    # Optional confirmation/ticket
    conf = (
        (payload.get("message") or {}).get("analysis", {}).get("confirmation")
        or (payload.get("metadata") or {}).get("confirmation")
    )
    if conf:
        summary += f" Confirmation: {conf}."

    # 5) Enqueue to chat
    sess.outbox.append({"type": "call_summary", "text": summary})
    sess.outbox.append({"type": "status", "text": "Call ended."})

    # 6) Clear active call
    sess.call_id = None
    return {"ok": True, "queued": 2}

# ----------------- polling -----------------

@app.get("/events/poll")
def poll_events(session_id: str):
    sess = SESS.get(session_id)
    if not sess:
        raise HTTPException(404, "Unknown session_id")
    items = list(sess.outbox)
    sess.outbox.clear()
    return {"events": items}

# ----------------- debug -----------------

@app.get("/debug/sessions")
def debug_sessions():
    def brief(sess: SessionState) -> Dict[str, Any]:
        return {
            "call_id": sess.call_id,
            "expected_fields": getattr(sess, "expected_fields", []),
            "ask_counts": getattr(sess, "ask_counts", {}),
            "outbox_len": len(getattr(sess, "outbox", [])),
            "data_keys": list((sess.data or {}).keys()),
        }
    return {sid: brief(s) for sid, s in SESS.items()}

# ----------------- hangup -----------------

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

# ----------------- debug extract -----------------
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
