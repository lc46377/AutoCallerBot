# app/vapi_client.py
import requests
from vapi import Vapi
from .config import (
    VAPI_API_KEY,
    VAPI_ASSISTANT_ID,
    VAPI_PHONE_NUMBER_ID,
)

client = Vapi(token=VAPI_API_KEY)

def _to_dict(model):
    """Tolerant Pydantic->dict across SDK versions."""
    if hasattr(model, "model_dump"):
        return model.model_dump()
    if hasattr(model, "dict"):
        return model.dict()
    if isinstance(model, dict):
        return model
    return {}

def start_vendor_call(customer_number: str, variable_values: dict) -> str:
    """
    Start an outbound call from your Vapi number to the vendor (customer_number).
    Pass flat variables used by your assistant prompt ({{goal}}, {{vendor_name}}, ...).
    """
    resp = client.calls.create(
        assistant_id=VAPI_ASSISTANT_ID,            # saved assistant ID
        phone_number_id=VAPI_PHONE_NUMBER_ID,      # your Vapi phone number ID (NOT +1...)
        customer={"number": customer_number},      # destination to dial
        assistant_overrides={"variable_values": variable_values or {}},
    )
    # SDK returns a Pydantic model
    if hasattr(resp, "id"):
        return resp.id
    # fallback just in case
    data = _to_dict(resp)
    return data.get("id")

def get_control_url(call_id: str) -> str | None:
    """
    Fetch the call object and return its control URL (used to end the call).
    """
    call_obj = client.calls.get(id=call_id)
    data = _to_dict(call_obj)
    mon = data.get("monitor") or {}
    # handle both styles, just in case
    return mon.get("controlUrl") or mon.get("control_url")

def hangup_call(call_id: str) -> bool:
    """
    Hard-end an in-progress call by POSTing {"type": "end-call"} to its controlUrl.
    """
    ctrl = get_control_url(call_id)
    if not ctrl:
        return False
    r = requests.post(ctrl, json={"type": "end-call"}, timeout=10)
    return r.ok
