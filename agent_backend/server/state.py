from enum import Enum
from dataclasses import dataclass, field
from typing import Any, Dict, List

class S(Enum):
    PARSE="PARSE"; CHECK="CHECK"; RETRIEVE="RETRIEVE"; PLAN="PLAN"; DIAL="DIAL"
    AUTH="AUTH"; NEGOTIATE="NEGOTIATE"; CONFIRM="CONFIRM"; SUMMARIZE="SUMMARIZE"; HALT="HALT"

@dataclass
class Ctx:
    task_id: str
    brief: Dict[str,Any] = field(default_factory=dict)
    context: Dict[str,Any] = field(default_factory=dict)
    plan: Dict[str,Any] = field(default_factory=dict)
    call_sid: str = ""
    outcome: Dict[str,Any] = field(default_factory=lambda: {"status":"pending"})
