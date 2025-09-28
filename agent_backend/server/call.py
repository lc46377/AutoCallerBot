import os
from dotenv import load_dotenv
from vapi import Vapi

load_dotenv()

client = Vapi(token=os.environ["VAPI_API_KEY"])

payload = {
    "assistantId": os.environ["VAPI_ASSISTANT_ID"],
    "phone": {
        "to":   {"number": os.environ["TARGET_NUMBER"]},     # Company the bot will call
        "from": {"number": os.environ["VAPI_FROM_NUMBER"]}   # Your Vapi number
    },
    # Per-call context that flips to Company/IVR Mode and guides routing
    "assistant": {
        "variables": {
            "call_type": "outbound",
            "goal": "refund",                                 # or "return" | "quote" | "reservation"
            "user_name": os.getenv("USER_NAME", "Ankit"),
            "user_phone": os.getenv("USER_PHONE", "+1"),
            "vendor": {"name": "Walmart"},                    # set to the company you're dialing
            # Optional vendor hints; safe to omit
            "vendor_profile": {
                "keywords": {
                    "returns": ["return", "refund", "replacement"],
                    "agent":   ["representative", "agent", "operator"]
                },
                "paths": {
                    # If you already know a common path, pre-suggest it. Otherwise omit.
                    # "returns": {"dtmf": "1w3#"}
                },
                "fallback": {"dtmf": "0", "speak": "representative"}
            }
        }
    }
}

resp = client.calls.create(payload)
print("Started call. Call ID:", resp.get("id"))
