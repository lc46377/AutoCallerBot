# from dotenv import load_dotenv; load_dotenv()
# import asyncio
# from fastapi import FastAPI, HTTPException
# from app.models import TaskCreate, TaskOut, SummaryOut
# from app.storage import init_db, create_task, get_task, get_summary
# from app.fsm import run_fsm

# app = FastAPI()


# @app.on_event("startup")
# async def _startup():
#     await init_db()


# @app.post("/tasks", response_model=TaskOut)
# async def create(task: TaskCreate):
#     task_id = await create_task(task)
#     asyncio.create_task(run_fsm(task_id))
#     return TaskOut(task_id=task_id, status="calling")


# @app.get("/tasks/{task_id}", response_model=SummaryOut)
# async def status(task_id: str):
#     t = await get_task(task_id)
#     if not t:
#         raise HTTPException(404, "not found")
#     s = await get_summary(task_id) or {}
#     return SummaryOut(
#         task_id=task_id, status=t["status"],
#         ticket_id=s.get("ticket_id"), resolution=s.get("resolution"),
#         amount=s.get("amount"), eta=s.get("eta"),
#         citations=s.get("citations", []), notes=s.get("notes", [])
#     )

import os, re, uuid
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
from dotenv import load_dotenv
from vapi import Vapi

load_dotenv()
app = FastAPI()
client = Vapi(token=os.environ["VAPI_API_KEY"])

# ---- Simple vendor directory (add more or skip to ask user for number) ----
VENDOR_MAP = {
    "walmart": "+16674190027",
    # "amazon": "+1...", "best buy": "+1...", etc.
}

# ---- What we need for each goal ----
GOAL_FIELDS: Dict[str, List[str]] = {
    "refund":      ["vendor_name", "order_id", "reason", "user_phone"],
    "replacement": ["vendor_name", "order_id", "item", "reason", "user_phone"],
    "query":       ["vendor_name", "question", "user_phone"],
}

# ---- Friendly prompts per field ----
PROMPT: Dict[str, str] = {
    "vendor_name": "Which company is this for?",
    "goal": "What do you need? (refund / replacement / query)",
    "order_id": "What is the order ID?",
    "item": "Which item is this about?",
    "reason": "Briefly, what's the reason?",
    "question": "What do you want to ask them?",
    "amount": "Amount involved? (type a number or 'skip')",
    "target_number": "What phone number should I call for this company? (E.164 like +1...)",
    "user_phone": "If the agent insists to speak with you, what number should I bridge in? (E.164)",
}

# ---- In-memory sessions (replace with DB/redis in prod) ----
SESS: Dict[str, Dict[str, Any]] = {}

# ---- Helpers ----
def norm_goal(txt: str) -> Optional[str]:
    t = txt.lower()
    if "refund" in t: return "refund"
    if "replace" in t or "replacement" in t: return "replacement"
    if "query" in t or "question" in t or "ask" in t: return "query"
    return None

def next_missing(data: Dict[str, Any]) -> str:
    # Determine goal first
    goal = data.get("goal")
    if not goal:
        return "goal"
    required = GOAL_FIELDS.get(goal, [])
    for f in required:
        if not data.get(f):
            return f
    # If vendor has no known number, require target_number
    v = (data.get("vendor_name") or "").lower()
    if v and v not in VENDOR_MAP and not data.get("target_number"):
        return "target_number"
    # Optional amount for refund
    if goal == "refund" and "amount" not in data:
        return "amount"
    return ""  # all done

def clean_answer(field: str, answer: str) -> Any:
    a = answer.strip()
    if field == "goal":
        g = norm_goal(a)
        if not g: raise HTTPException(400, "Please answer: refund, replacement, or query.")
        return g
    if field in ("vendor_name", "order_id", "item", "reason", "question"):
        return a
    if field == "amount":
        if a.lower() in ("skip", "na", "n/a", "no"):
            return None
        try:
            return float(re.sub(r"[^\d.]", "", a))
        except:
            raise HTTPException(400, "Please type a number or 'skip'.")
    if field in ("user_phone", "target_number"):
        if not re.match(r"^\+\d{7,15}$", a):
            raise HTTPException(400, "Please provide an E.164 number like +14155551212.")
        return a
    return a

def build_call_vars(data: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "call_type": "outbound",
        "vendor": {"name": data["vendor_name"]},
        "goal": data["goal"],
        "order_id": data.get("order_id"),
        "item": data.get("item"),
        "reason": data.get("reason"),
        "amount": data.get("amount"),
        "user_name": os.getenv("USER_NAME", "Customer"),
        "user_phone": data.get("user_phone") or os.getenv("DEFAULT_USER_PHONE"),
    }

def resolve_target_number(data: Dict[str, Any]) -> str:
    v = (data.get("vendor_name") or "").lower()
    return data.get("target_number") or VENDOR_MAP.get(v, "")

# ---- API Models ----
# add/replace your StartBody with:
class StartBody(BaseModel):
    utterance: Optional[str] = None
    user_phone: Optional[str] = None
    vendor_name: Optional[str] = None
    goal: Optional[str] = None
    order_id: Optional[str] = None
    item: Optional[str] = None
    reason: Optional[str] = None
    amount: Optional[float] = None
    target_number: Optional[str] = None

class ReplyBody(BaseModel):
    session_id: str
    answer: str

# ---- Endpoints ----
@app.post("/intake/start")
def intake_start(body: StartBody):
    sid = str(uuid.uuid4())
    SESS[sid] = {"data": {}}
    d = SESS[sid]["data"]

    # 1) Prefill from explicit fields (if the app already knows them)
    for f in ["vendor_name","goal","order_id","item","reason","amount","target_number","user_phone"]:
        val = getattr(body, f)
        if val: d[f] = val

    # 2) Also try to parse from the utterance (see function below)
    if body.utterance:
        prefill_from_utterance(d, body.utterance)

    field = next_missing(d)
    prompt = PROMPT[field] if field else "All set. Starting the call now."
    return {"session_id": sid, "next_field": field, "question": prompt}

@app.post("/intake/reply")
def intake_reply(body: ReplyBody):
    sess = SESS.get(body.session_id)
    if not sess: raise HTTPException(404, "Unknown session_id")
    d = sess["data"]

    # Figure out which field we were asking
    field = next_missing(d)
    if not field:
        return {"done": True, "message": "Already complete."}

    # Store user answer
    d[field] = clean_answer(field, body.answer)

    # Ask next or start call
    field = next_missing(d)
    if field:
        return {"done": False, "next_field": field, "question": PROMPT[field]}

    # Everything collected -> place the Vapi call
    to_number = resolve_target_number(d)
    if not to_number:
        return {"done": False, "next_field": "target_number", "question": PROMPT["target_number"]}

    resp = client.calls.create({
        "assistantId": os.environ["VAPI_ASSISTANT_ID"],
        "phone": {
            "to":   {"number": to_number},
            "from": {"number": os.environ["VAPI_FROM_NUMBER"]}
        },
        "assistant": {"variables": build_call_vars(d)}
    })
    sess["call_id"] = resp.get("id")
    return {"done": True, "message": "Calling the company now.", "call_id": resp.get("id")}

# ---- Vapi webhook for dynamic transfer (only if rep insists) ----
@app.post("/vapi/server")
async def vapi_server(request: Request):
    payload = await request.json()
    msg = payload.get("message", {})
    if msg.get("type") == "transfer-destination-request":
        vars = msg.get("variables") or {}
        number = vars.get("user_phone") or os.getenv("DEFAULT_USER_PHONE")
        return {"destination": {"type": "number", "number": number}}
    return {"ok": True}
