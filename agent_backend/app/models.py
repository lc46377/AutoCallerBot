# app/models.py
from typing import Optional, Dict, Any, List
from pydantic import BaseModel

class StartBody(BaseModel):
    utterance: Optional[str] = None
    vendor_name: Optional[str] = None
    goal: Optional[str] = None
    order_id: Optional[str] = None
    item: Optional[str] = None
    reason: Optional[str] = None
    amount: Optional[float] = None
    target_number: Optional[str] = None
    user_phone: Optional[str] = None

class ReplyBody(BaseModel):
    session_id: str
    answer: str

class SessionState(BaseModel):
    data: Dict[str, Any] = {}
    call_id: Optional[str] = None
    expected_fields: List[str] = []   # <— ask-for-these in one go
