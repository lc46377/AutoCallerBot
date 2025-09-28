# app/llm.py
import json, re
from typing import Dict, Any, List, Optional
from .config import USE_LLM, OPENAI_API_KEY
from .wizard import friendly_prompt

_oai = None
if USE_LLM and OPENAI_API_KEY:
    from openai import OpenAI
    _oai = OpenAI(api_key=OPENAI_API_KEY)

SCHEMA_KEYS = [
    # intent
    "intent",
    # common
    "vendor_name", "target_number", "user_phone", "question",
    # retail return
    "order_id", "date_of_purchase", "bill_amount", "item", "reason",
    # hotel booking
    "hotel_name", "city", "stay_start", "stay_end", "nights", "ask_price", "ask_discounts",
    # rental
    "rental_agreement_number", "car_issue",
    # service booking (we mostly rely on question, but leave keys open)
    "service_type", "preferred_time", "ask_availability",
]

SYSTEM_INSTRUCTIONS = """\
Return ONLY valid JSON (no prose). Keys allowed:
intent, vendor_name, target_number, user_phone, question,
order_id, date_of_purchase, bill_amount, item, reason,
hotel_name, city, stay_start, stay_end, nights, ask_price, ask_discounts,
rental_agreement_number, car_issue,
service_type, preferred_time, ask_availability.

Intent classification (choose one):
- "retail_return"  (return/refund/exchange related to a purchase/retailer like Walmart)
- "hotel_booking"  (book/reserve a hotel or ask pricing/availability/discounts)
- "rental_issue"   (car rental exchange/return/issues needing agreement number)
- "service_booking" (book/reserve a service like haircut/doctor/restaurant)
- "generic_query"  (other info-seeking calls)

Rules:
- Extract ALL fields clearly present; omit unknowns.
- Normalize booleans ask_price/ask_discounts/ask_availability: true/false.
- nights: integer if user mentions "for X nights" (or infer from dates if both present).
- bill_amount: number only (e.g., 89.99).
- user_phone/target_number: keep as-is (strings; include '+' if present).
- Dates: keep as user-stated strings; do not invent values.

Examples:
Text: "I want to return my AirPods to Walmart, order id 12-ABC, bought on Sep 2 for $199.99. Reason: left bud dead. Call me at +1 202 555 0188."
JSON: {"intent":"retail_return","vendor_name":"Walmart","order_id":"12-ABC","date_of_purchase":"Sep 2, 2025","bill_amount":199.99,"item":"AirPods","reason":"left bud dead","user_phone":"+12025550188"}

Text: "Book Marriott Downtown in Boston from Oct 3 to Oct 6 for 3 nights. Please ask the price and if any student discounts."
JSON: {"intent":"hotel_booking","hotel_name":"Marriott Downtown","city":"Boston","stay_start":"Oct 3, 2025","stay_end":"Oct 6, 2025","nights":3,"ask_price":true,"ask_discounts":true}

Text: "Enterprise gave me a rattling car, I want to exchange it. Agreement RA-7782."
JSON: {"intent":"rental_issue","vendor_name":"Enterprise","rental_agreement_number":"RA-7782","car_issue":"rattling car"}

Text: "I’d like to book a haircut at Supercuts."
JSON: {"intent":"service_booking","vendor_name":"Supercuts","service_type":"haircut"}
"""

def _normalize(data: Dict[str, Any]) -> Dict[str, Any]:
    if not data:
        return {}
    data = {k: v for k, v in data.items() if k in SCHEMA_KEYS and v not in (None, "", [])}
    # bill_amount
    if "bill_amount" in data and isinstance(data["bill_amount"], str):
        m = re.sub(r"[^\d.]", "", data["bill_amount"])
        data["bill_amount"] = float(m) if m else None
        if data["bill_amount"] is None:
            data.pop("bill_amount", None)
    # nights
    if "nights" in data and isinstance(data["nights"], str):
        m = re.search(r"\d+", data["nights"])
        if m:
            data["nights"] = int(m.group(0))
        else:
            data.pop("nights", None)
    # booleans
    for k in ["ask_price", "ask_discounts", "ask_availability"]:
        if k in data and isinstance(data[k], str):
            val = data[k].strip().lower()
            if val in ("yes", "y", "true"):
                data[k] = True
            elif val in ("no", "n", "false"):
                data[k] = False
            else:
                data.pop(k, None)
    return data

def _post_enrich_reason_phone(u: str, data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Enrich 'reason', 'target_number', and 'user_phone' from natural replies like:
    - "I don't like the product" (short free-form reason)
    - "because it broke…" / "Reason: …"
    - "Call +1 415-555-0134" (target number)
    - "Call me at +1 415 555 0134" (user phone)
    """
    out = dict(data)
    txt = (u or "").strip()
    low = txt.lower()

    # Reason
    if not out.get("reason"):
        # 1) "Reason: ..." or "... because ... / due to / as ..."
        m = re.search(r'\breason\s*(?:is|:)\s*(.+)', txt, re.I)
        if m:
            out["reason"] = m.group(1).strip().rstrip(".")
        else:
            m2 = re.search(r'\b(?:because|due to|as)\s+([^.;]+)', txt, re.I)
            if m2:
                out["reason"] = m2.group(1).strip()

        # 2) If short sentence in a returns context, treat whole reply as reason
        if not out.get("reason"):
            if len(txt) <= 160 and any(w in low for w in ["return", "refund", "exchange", "replace", "product", "item"]):
                out["reason"] = txt.rstrip(" .")

        # 3) Common phrases
        if not out.get("reason"):
            if re.search(r"\b(i\s+don[’']?t\s+like\s+(it|the\s+product)|doesn[’']?t\s+work|defective|broken|broke|damaged|too\s+small|too\s+big|wrong\s+item)\b", low, re.I):
                out["reason"] = txt.rstrip(" .")

    # Target number like "call +1 667-419-0027"
    if not out.get("target_number"):
        mtn = re.search(
            r'\b(?:call|dial|ring|reach\s+them\s+at|their\s+number\s+is|support\s+number)\s*(?:at|on)?\s*(\+\d[\d\s\-]{7,18}\d)',
            txt, re.I
        )
        if mtn:
            out["target_number"] = mtn.group(1).replace(" ", "").replace("-", "")

    # User phone like "call me at / my phone is / reach me at"
    if not out.get("user_phone"):
        mup = re.search(
            r'(?:my\s+phone\s+is|call\s+me\s+at|reach\s+me\s+at)\s*(\+\d[\d\s\-]{7,18}\d)',
            txt, re.I
        )
        if mup:
            out["user_phone"] = mup.group(1).replace(" ", "").replace("-", "")

    return {k: v for k, v in out.items() if v not in (None, "", [])}

def _post_enrich_question(u: str, data: Dict[str, Any], intent: Optional[str] = None) -> Dict[str, Any]:
    """
    Infer a 'question' from short natural-language replies like:
    - "What time are they open?"
    - "Ask their price."
    - "Please check availability for today"
    Only fills if missing.
    """
    out = dict(data)
    if out.get("question"):
        return out

    txt = (u or "").strip()
    low = txt.lower()

    # If it looks like a question or short imperative, accept it.
    keyword_hit = any(k in low for k in [
        "what", "when", "how", "can you", "could you", "please", "ask",
        "price", "cost", "open", "hours", "availability", "available",
        "book", "reserve", "appointment", "schedule", "quote"
    ])

    # Looser acceptance for intents that commonly take a 'question'
    intent_is_q = intent in ("generic_query", "service_booking", "hotel_booking")

    if "?" in txt or (len(txt) <= 160 and (keyword_hit or intent_is_q)):
        cleaned = re.sub(r"[ \t]+", " ", txt).strip().rstrip("?.! ").strip()
        if cleaned:
            out["question"] = cleaned

    return out

def extract_fields_with_debug(utterance: str) -> Dict[str, Any]:
    """
    1) Chat Completions with JSON response_format (primary)
    2) Plain chat JSON parsing (fallback)
    3) Heuristic fallback
    """
    utterance = (utterance or "").strip()
    dbg: Dict[str, Any] = {"pass": None, "raw": None, "fields": {}}
    if not utterance:
        dbg["pass"] = "empty"
        return dbg

    if _oai:
        # 1) JSON-formatted response
        try:
            r = _oai.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": SYSTEM_INSTRUCTIONS},
                    {"role": "user", "content": f"Text: {utterance}\nJSON:"}
                ],
                response_format={"type": "json_object"},
                temperature=0
            )
            text = r.choices[0].message.content
            dbg["raw"] = text
            data = _normalize(json.loads(text))
            data = _post_enrich_reason_phone(utterance, data)
            data = _post_enrich_question(utterance, data, data.get("intent"))
            dbg["pass"] = "chat_json_object"
            dbg["fields"] = data
            return dbg
        except Exception as e:
            dbg["raw"] = f"chat_json_object_error: {e}"

        # 2) Plain chat JSON parsing
        try:
            r2 = _oai.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": SYSTEM_INSTRUCTIONS},
                    {"role": "user", "content": f"Text: {utterance}\nJSON:"}
                ],
                temperature=0
            )
            text2 = r2.choices[0].message.content
            dbg["raw"] = text2
            m = re.search(r'\{.*\}', text2, re.S)
            if m:
                data2 = _normalize(json.loads(m.group(0)))
                data2 = _post_enrich_reason_phone(utterance, data2)
                data2 = _post_enrich_question(utterance, data2, data2.get("intent"))
                dbg["pass"] = "chat_plain"
                dbg["fields"] = data2
                return dbg
        except Exception as e:
            dbg["raw"] = f"chat_plain_error: {e}"

    # 3) Heuristic fallback (no network)
    out: Dict[str, Any] = {}
    low = utterance.lower()

    if any(w in low for w in ["return", "refund", "exchange"]) and "hotel" not in low:
        out["intent"] = "retail_return"
    elif any(w in low for w in ["hotel", "book", "reservation"]) and "haircut" not in low and "salon" not in low:
        out["intent"] = "hotel_booking"
    elif any(w in low for w in ["rental", "enterprise", "hertz", "avis"]) and any(w in low for w in ["issue", "return", "exchange"]):
        out["intent"] = "rental_issue"
    elif any(w in low for w in ["book", "appointment", "reserve", "reservation"]) and any(
        w in low for w in ["haircut", "barber", "salon", "spa", "stylist", "doctor", "dentist", "restaurant", "table"]
    ):
        out["intent"] = "service_booking"
    else:
        out["intent"] = "generic_query"

    # Quick field grabs
    m = re.search(r'order\s*(?:id|#|number)?\s*(?:is|:)?\s*([A-Za-z0-9\-]{4,})', utterance, re.I)
    if m:
        out["order_id"] = m.group(1).strip().rstrip(".,;:")
    m2 = re.search(r'(?:agreement|contract)\s*(?:no|number|#)?\s*[:\-]?\s*([A-Za-z0-9\-]{3,})', utterance, re.I)
    if m2:
        out["rental_agreement_number"] = m2.group(1).strip()
    # User phone (spaces/hyphens allowed)
    m3 = re.search(r'(\+\d[\d\s\-]{7,18}\d)', utterance)
    if m3:
        out["user_phone"] = m3.group(1).replace(" ", "").replace("-", "")

    out = _post_enrich_reason_phone(utterance, out)
    out = _post_enrich_question(utterance, out, out.get("intent"))

    dbg["pass"] = "fallback"
    dbg["fields"] = out
    return dbg

def extract_fields(utterance: str) -> Dict[str, Any]:
    return extract_fields_with_debug(utterance).get("fields", {})

def compose_multi_question(missing: List[str], known: Dict[str, Any]) -> str:
    # Friendly copy; no "E.164" wording
    return friendly_prompt(missing)
