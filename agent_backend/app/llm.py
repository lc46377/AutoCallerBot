import json, re
from typing import Dict, Any, List
from .config import USE_LLM, OPENAI_API_KEY
from .wizard import PROMPT, norm_goal

_oai = None
if USE_LLM and OPENAI_API_KEY:
    from openai import OpenAI
    _oai = OpenAI(api_key=OPENAI_API_KEY)

SCHEMA_KEYS = [
    "vendor_name", "goal", "order_id", "item",
    "reason", "question", "amount", "user_phone", "target_number"
]

SYSTEM_INSTRUCTIONS = """\
Return ONLY valid JSON (no prose). Keys allowed:
vendor_name, goal, order_id, item, reason, question, amount, user_phone, target_number.

Rules:
- vendor_name: proper noun company name mentioned (e.g., Walmart, Enterprise, Marriott).
- goal (lowercase): map synonyms:
  • "replace", "replacement", "exchange" -> "replacement"
  • "refund", "return" -> "refund"
  • otherwise if it's merely an informational ask -> "query"
- order_id: exact token(s) after "order id"/"order #"/"order number"; include letters/digits/dashes; stop at punctuation.
- item: from phrases like "replace/return my/the <item>" or "for/about/regarding <item>".
- amount: number only (no $).
- user_phone/target_number: keep as-is (strings).
- If a field is present in the text, DO NOT omit it. If not present, omit it.
- Trim punctuation/spaces. Do not invent values.

Examples:
Text: "Please initiate a replacement with Walmart, order id 12345, to replace my bluetooth headphones"
JSON: {"vendor_name":"Walmart","goal":"replacement","order_id":"12345","item":"bluetooth headphones"}

Text: "I need a refund from Enterprise. Order #A1B-234. It's for the car seat."
JSON: {"vendor_name":"Enterprise","goal":"refund","order_id":"A1B-234","item":"car seat"}

Text: "Can you ask Marriott if I can check in early?"
JSON: {"vendor_name":"Marriott","goal":"query"}
"""

def _normalize(data: Dict[str, Any]) -> Dict[str, Any]:
    if not data: return {}
    data = {k: v for k, v in data.items() if k in SCHEMA_KEYS and v not in (None, "", [])}
    if data.get("goal"):
        data["goal"] = norm_goal(data["goal"]) or data["goal"]
    if data.get("vendor_name"):
        data["vendor_name"] = data["vendor_name"].strip()
    if "amount" in data and isinstance(data["amount"], str):
        try:
            amt = re.sub(r"[^\d.]", "", data["amount"]).strip()
            data["amount"] = float(amt) if amt else None
        except Exception:
            data["amount"] = None
        if data["amount"] is None:
            data.pop("amount", None)
    return data

def _post_enrich_reason_phone(u: str, data: Dict[str, Any]) -> Dict[str, Any]:
    # Pick up "Reason: ..." or "... because ..." or "... due to ..."; phone phrases
    out = dict(data)
    if not out.get("reason"):
        m = re.search(r'\breason\s*(?:is|:)\s*(.+)', u, re.I)
        if m:
            out["reason"] = m.group(1).strip().rstrip(".")
        else:
            m2 = re.search(r'\b(?:because|due to|as)\s+([^.;]+)', u, re.I)
            if m2:
                out["reason"] = m2.group(1).strip()
    if not out.get("user_phone"):
        m3 = re.search(r'(?:my\s+phone\s+is|call\s+me\s+at|reach\s+me\s+at)\s*(\+\d{7,15})', u, re.I)
        if m3:
            out["user_phone"] = m3.group(1).strip()
    return {k: v for k, v in out.items() if v not in (None, "", [])}

def extract_fields_with_debug(utterance: str) -> Dict[str, Any]:
    """
    1) Chat Completions with response_format=json_object (primary)
    2) Chat Completions plain JSON (parse first JSON block)
    3) Safety fallback (minimal heuristics) -- rarely needed
    """
    utterance = (utterance or "").strip()
    dbg: Dict[str, Any] = {"pass": None, "raw": None, "fields": {}}
    if not utterance:
        dbg["pass"] = "empty"
        return dbg

    if _oai:
        # 1) chat.completions with JSON response_format
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
            if data:
                data = _post_enrich_reason_phone(utterance, data)
                dbg["pass"] = "chat_json_object"
                dbg["fields"] = data
                return dbg
        except Exception as e:
            dbg["raw"] = f"chat_json_object_error: {e}"

        # 2) plain chat, still asking for JSON
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
                if data2:
                    data2 = _post_enrich_reason_phone(utterance, data2)
                    dbg["pass"] = "chat_plain"
                    dbg["fields"] = data2
                    return dbg
        except Exception as e:
            dbg["raw"] = f"chat_plain_error: {e}"

    # 3) last-resort safety net (keeps UX moving even if LLM hiccups)
    out: Dict[str, Any] = {}
    g = norm_goal(utterance)
    if g: out["goal"] = g
    if "walmart" in utterance.lower(): out["vendor_name"] = "Walmart"
    m = re.search(r'order\s*(?:id|#|number)?\s*(?:is|:)?\s*([A-Za-z0-9\-]{4,})', utterance, re.I)
    if m: out["order_id"] = m.group(1).strip().rstrip(".,;:")
    m2 = re.search(r'(?:replace|return)\s+(?:my|the)\s+([^,.;]+)', utterance, re.I)
    if m2: out["item"] = m2.group(1).strip()
    out = _post_enrich_reason_phone(utterance, out)

    dbg["pass"] = "fallback"
    dbg["fields"] = out
    return dbg

def extract_fields(utterance: str) -> Dict[str, Any]:
    return extract_fields_with_debug(utterance).get("fields", {})

def compose_multi_question(missing: List[str], known: Dict[str, Any]) -> str:
    if not (_oai and USE_LLM):
        hints = [PROMPT[f] for f in missing]
        return "I need a couple of details to proceed: " + " ".join(hints)
    try:
        r = _oai.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{
                "role": "system",
                "content": (
                    "Ask for ALL missing fields in ONE short message (<=2 sentences), no bullets. "
                    "Be precise and include small hints (e.g., E.164 for phone)."
                )
            },{
                "role": "user",
                "content": f"Missing: {json.dumps(missing)}\nKnown: {json.dumps({k:v for k,v in known.items() if v})}"
            }],
            temperature=0
        )
        return (r.choices[0].message.content or "Please provide the remaining details.").strip()
    except Exception:
        hints = [PROMPT[f] for f in missing]
        return "I need a couple of details to proceed: " + " ".join(hints)
