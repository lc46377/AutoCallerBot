import re
from typing import Dict, Any, List, Optional
from .config import USER_NAME, DEFAULT_USER_PHONE

# Simple vendor → phone mapping (extend as needed)
VENDOR_MAP = {
    "walmart": "+16674190027",
}

GOAL_FIELDS: Dict[str, List[str]] = {
    "refund":      ["vendor_name", "order_id", "reason", "user_phone"],
    "replacement": ["vendor_name", "order_id", "item", "reason", "user_phone"],
    "query":       ["vendor_name", "question", "user_phone"],
}

PROMPT: Dict[str, str] = {
    "vendor_name": "Which company is this for?",
    "goal": "What do you need? (refund / replacement / query)",
    "order_id": "What is the order ID?",
    "item": "Which item is this about?",
    "reason": "Briefly, what's the reason?",
    "question": "What do you want to ask them?",
    "amount": "Amount involved? (type a number or 'skip')",
    "target_number": "What phone number should I call for this company? (E.164 like +1...)",
    "user_phone": "If the agent needs you, what number should I bridge in? (E.164)",
}

def norm_goal(txt: str) -> Optional[str]:
    if not txt: return None
    t = txt.lower()
    if "refund" in t or "return" in t:
        return "refund"
    if "replace" in t or "replacement" in t or "exchange" in t:
        return "replacement"
    if "query" in t or "question" in t or "ask" in t or "info" in t:
        return "query"
    return None

def _is_e164(s: Optional[str]) -> bool:
    return bool(s and re.fullmatch(r"\+\d{7,15}", s))

def missing_fields(data: Dict[str, Any]) -> List[str]:
    fields: List[str] = []
    goal = data.get("goal")
    if not goal:
        return ["goal"]

    for f in GOAL_FIELDS.get(goal, []):
        if not data.get(f):
            fields.append(f)

    v = (data.get("vendor_name") or "").lower()
    if v and v not in VENDOR_MAP and not data.get("target_number"):
        fields.append("target_number")

    # Require an actual E.164 phone number (avoid placeholders like "+1")
    if not _is_e164(data.get("user_phone")) and "user_phone" not in fields:
        fields.append("user_phone")

    # Example: refunds sometimes need an amount
    if goal == "refund" and "amount" not in data:
        fields.append("amount")

    return fields

def resolve_target_number(data: Dict[str, Any]) -> str:
    v = (data.get("vendor_name") or "").lower()
    return data.get("target_number") or VENDOR_MAP.get(v, "")

def build_call_vars(data: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "call_type": "outbound",
        "vendor_name": data.get("vendor_name"),
        "goal": data.get("goal"),
        "order_id": data.get("order_id"),
        "item": data.get("item"),
        "reason": data.get("reason"),
        "amount": data.get("amount"),
        "user_name": USER_NAME,
        "user_phone": data.get("user_phone") or DEFAULT_USER_PHONE,
    }
