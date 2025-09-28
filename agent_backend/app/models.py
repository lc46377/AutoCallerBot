# app/models.py
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field

class StartBody(BaseModel):
    utterance: Optional[str] = None
    # generic vendor/phone
    vendor_name: Optional[str] = None
    target_number: Optional[str] = None
    user_phone: Optional[str] = None
    # legacy goal (kept for backward compat; LLM will set intent)
    goal: Optional[str] = None

    # retail returns
    order_id: Optional[str] = None
    date_of_purchase: Optional[str] = None  # ISO or natural; we normalize later
    bill_amount: Optional[float] = None
    item: Optional[str] = None
    reason: Optional[str] = None

    # hotel booking
    hotel_name: Optional[str] = None
    city: Optional[str] = None
    stay_start: Optional[str] = None
    stay_end: Optional[str] = None
    nights: Optional[int] = None
    ask_price: Optional[bool] = None
    ask_discounts: Optional[bool] = None

    # rental issue
    rental_agreement_number: Optional[str] = None
    car_issue: Optional[str] = None

class ReplyBody(BaseModel):
    session_id: str
    answer: str

class SessionState(BaseModel):
    data: Dict[str, Any] = Field(default_factory=dict)
    call_id: Optional[str] = None
    expected_fields: List[str] = []
    intent: Optional[str] = None
    ask_counts: Dict[str, int] = Field(default_factory=dict)  # track field prompts
    intent: Optional[str] = None
    outbox: List[Dict[str, Any]] = Field(default_factory=list)
