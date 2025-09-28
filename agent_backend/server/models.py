from pydantic import BaseModel
from typing import Dict, List, Optional


class TaskCreate(BaseModel):
    user_id: str
    brand: str
    department_hint: Optional[str] = None
    goal: str
    reason: Optional[str] = None
    identifiers: Dict[str, str] = {}
    constraints: List[str] = []
    auth: Dict[str, str] = {}
    evidence: List[str] = []
    desired_outcome: Optional[str] = None


class TaskOut(BaseModel):
    task_id: str
    status: str


class SummaryOut(BaseModel):
    task_id: str
    status: str
    ticket_id: Optional[str] = None
    resolution: Optional[str] = None
    amount: Optional[float] = None
    eta: Optional[str] = None
    rep: Optional[Dict[str, str]] = None
    citations: List[Dict[str, str]] = []
    notes: List[str] = []
