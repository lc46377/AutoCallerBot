import os
from dotenv import load_dotenv

load_dotenv()

VAPI_API_KEY       = os.getenv("VAPI_API_KEY", "")
VAPI_ASSISTANT_ID  = os.getenv("VAPI_ASSISTANT_ID", "")
VAPI_PHONE_NUMBER_ID = os.getenv("VAPI_PHONE_NUMBER_ID", "")  
VAPI_FROM_NUMBER   = os.getenv("VAPI_FROM_NUMBER", "")
USER_NAME          = os.getenv("USER_NAME", "Customer")
DEFAULT_USER_PHONE = os.getenv("DEFAULT_USER_PHONE", "+16674190027")
DEFAULT_TARGET_NUMBER = os.getenv("DEFAULT_TARGET_NUMBER", "+16674190027")

USE_LLM            = os.getenv("USE_LLM", "false").lower() in ("1","true","yes")
OPENAI_API_KEY     = os.getenv("OPENAI_API_KEY", "")
USE_LLM_QUESTIONS  = os.getenv("USE_LLM_QUESTIONS", "false").lower() in ("1","true","yes")
