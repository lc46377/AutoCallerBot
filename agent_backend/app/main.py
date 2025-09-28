import uuid
from typing import Dict, Any
from fastapi import FastAPI, HTTPException, Request, Body
from .models import StartBody, ReplyBody, SessionState
from .wizard import missing_fields, resolve_target_number, build_call_vars
from .llm import extract_fields, extract_fields_with_debug, compose_multi_question
from .vapi_client import start_vendor_call, hangup_call
from .config import DEFAULT_USER_PHONE, USE_LLM, OPENAI_API_KEY

app = FastAPI()
SESS: Dict[str, SessionState] = {}

@app.get("/health")
def health():
    return {"ok": True}

# app/main.py
def _merge(d: Dict[str, Any], add: Dict[str, Any], overwrite: bool = False):
    for k, v in (add or {}).items():
        if v in (None, "", []):
            continue
        if overwrite or (k not in d) or (not d[k]) or d[k] == "+1":
            d[k] = v


@app.post("/intake/start")
def intake_start(body: StartBody):
    sid = str(uuid.uuid4())
    sess = SessionState(data={})
    SESS[sid] = sess
    d = sess.data

    # explicit prefills
    for f in ["vendor_name","goal","order_id","item","reason","amount","target_number","user_phone"]:
        val = getattr(body, f)
        if val not in (None, "", []):
            d[f] = val

    # LLM extraction from utterance (can fill multiple fields)
    if body.utterance:
        _merge(d, extract_fields(body.utterance))

    # default phone (will be validated later)
    d.setdefault("user_phone", DEFAULT_USER_PHONE)

    missing = missing_fields(d)
    if not missing:
        to_number = resolve_target_number(d)
        if not to_number:
            missing = ["target_number"]
        else:
            call_id = start_vendor_call(to_number, build_call_vars(d))
            sess.call_id = call_id
            return {"session_id": sid, "next_fields": [], "question": "Calling the company now.", "call_id": call_id}

    sess.expected_fields = missing
    q = compose_multi_question(missing, d)
    return {"session_id": sid, "next_fields": missing, "question": q}

@app.post("/intake/reply")
def intake_reply(body: ReplyBody):
    sess = SESS.get(body.session_id)
    if not sess:
        raise HTTPException(404, "Unknown session_id")
    d = sess.data

    extracted = extract_fields(body.answer or "")
    print("=== EXTRACTED FROM ANSWER ===", extracted)

    # OVERWRITE merge: always write non-empty values
    for k, v in (extracted or {}).items():
        if v not in (None, "", []):
            d[k] = v   # <— overwrite instead of setdefault
    # Extract multiple fields from a single reply
    _merge(d, extract_fields(body.answer), overwrite=True)

    # Recompute missing
    missing = missing_fields(d)
    if missing:
        sess.expected_fields = missing
        q = compose_multi_question(missing, d)
        return {"done": False, "next_fields": missing, "question": q}

    # Place the call
    to_number = resolve_target_number(d)
    if not to_number:
        sess.expected_fields = ["target_number"]
        q = compose_multi_question(["target_number"], d)
        return {"done": False, "next_fields": ["target_number"], "question": q}

    call_id = start_vendor_call(to_number, build_call_vars(d))
    sess.call_id = call_id
    return {"done": True, "message": "Calling the company now.", "call_id": call_id}

# Debug: see what the LLM produced
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

# Hang up a live call via controlUrl
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
