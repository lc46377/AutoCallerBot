# app/wizard.py
import re
from typing import Dict, Any, List, Optional
from .config import USER_NAME, DEFAULT_USER_PHONE

# Simple vendor → phone mapping (extend as needed)
VENDOR_MAP = {
    "walmart": "+16674190027",
    # "enterprise": "...",
    # "marriott": "...",
}

# INTENT → required slots (policy)
INTENT_SLOTS = {
    "retail_return": ["vendor_name","order_id","date_of_purchase","bill_amount","item","reason","user_phone"],
    "hotel_booking": ["hotel_name","city","stay_start","stay_end","nights","ask_price","ask_discounts","user_phone"],
    "rental_issue":  ["vendor_name","rental_agreement_number","car_issue","user_phone"],
    # NEW:
    "service_booking": ["vendor_name","service_type","preferred_time","ask_price","ask_availability","user_phone"],
    "generic_query": ["vendor_name","question","user_phone"],
}

PROMPT: Dict[str, str] = {
    "vendor_name": "Which company or hotel is this for?",
    "order_id": "What’s the order ID shown on your receipt or email?",
    "date_of_purchase": "What was the purchase date? (e.g., 2025-09-01 or Sep 1, 2025)",
    "bill_amount": "What was the total billed amount (numbers only, like 89.99)?",
    "item": "Which item is this about?",
    "reason": "Briefly, what’s the reason?",
    "hotel_name": "What’s the hotel’s name?",
    "city": "Which city is the hotel in?",
    "stay_start": "When do you want to check in? (date)",
    "stay_end": "When do you plan to check out? (date)",
    "nights": "How many nights?",
    "ask_price": "Should I ask for the total price for that duration? (yes/no)",
    "ask_discounts": "Should I ask about any discounts? (yes/no)",
    "rental_agreement_number": "What’s your rental agreement number?",
    "car_issue": "What’s the issue with the car?",
    "question": "What do you want me to ask them?",
    "user_phone": "If they need to reach you, what’s your number with country code? (e.g., +1 415 555 0134)",
}

def _is_e164ish(s: Optional[str]) -> bool:
    # Accept + and digits with 8–16 total digits; ignore spaces and hyphens
    if not s:
        return False
    clean = s.replace(" ", "").replace("-", "")
    return bool(re.fullmatch(r"\+\d{8,16}", clean))

def resolve_target_number(data: Dict[str, Any]) -> str:
    v = (data.get("vendor_name") or data.get("hotel_name") or "").lower()
    return data.get("target_number") or VENDOR_MAP.get(v, "")

def missing_fields(data: Dict[str, Any], intent: Optional[str]) -> List[str]:
    if not intent:
        return ["intent"]
    slots = INTENT_SLOTS.get(intent, [])
    missing = [f for f in slots if not data.get(f)]
    # phone sanity
    if "user_phone" in slots and not _is_e164ish(data.get("user_phone")):
        if "user_phone" not in missing:
            missing.append("user_phone")
    # NOTE: we no longer add 'target_number' to missing, because main.py
    # will always fall back to DEFAULT_TARGET_NUMBER when none is available.
    return missing

def build_call_vars(data: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "call_type": "outbound",
        "intent": data.get("intent"),
        "vendor_name": data.get("vendor_name") or data.get("hotel_name"),
        # retail
        "order_id": data.get("order_id"),
        "date_of_purchase": data.get("date_of_purchase"),
        "bill_amount": data.get("bill_amount"),
        "item": data.get("item"),
        "reason": data.get("reason"),
        # hotel
        "hotel_name": data.get("hotel_name"),
        "city": data.get("city"),
        "stay_start": data.get("stay_start"),
        "stay_end": data.get("stay_end"),
        "nights": data.get("nights"),
        "ask_price": data.get("ask_price"),
        "ask_discounts": data.get("ask_discounts"),
        # rental
        "rental_agreement_number": data.get("rental_agreement_number"),
        "car_issue": data.get("car_issue"),
        # user
        "user_name": USER_NAME,
        "user_phone": data.get("user_phone") or DEFAULT_USER_PHONE,
        "service_type": data.get("service_type"),
        "preferred_time": data.get("preferred_time"),
        "ask_availability": data.get("ask_availability"),
        "question": data.get("question"),
    }

def friendly_prompt(fields: List[str]) -> str:
    hints = [PROMPT[f] for f in fields if f in PROMPT]
    return "I need a couple of details to proceed: " + " ".join(hints)

def should_suppress(field: str, ask_counts: Dict[str, int], cap: int = 2) -> bool:
    return ask_counts.get(field, 0) >= cap
