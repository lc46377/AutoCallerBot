import os
from twilio.rest import Client

def _must(name: str) -> str:
    v = os.getenv(name)
    if not v:
        raise RuntimeError(f"Missing env var: {name}")
    return v

async def dial_support(brief) -> str:
    """
    Places the outbound call using TwiML Bin (demo mode).
    Reads env at call time so changing .env works after a restart.
    """
    account_sid = _must("TWILIO_ACCOUNT_SID")
    auth_token  = _must("TWILIO_AUTH_TOKEN")
    from_num    = _must("TWILIO_FROM_NUMBER")
    to_num      = os.getenv("TEST_TO_NUMBER", from_num)   # demo: call your phone
    twiml_url   = _must("TWIML_URL")

    print(f"[dial_support] to={to_num} from_={from_num} url={twiml_url}")
    client = Client(account_sid, auth_token)
    call = client.calls.create(to=to_num, from_=from_num, url=twiml_url)
    print(f"[dial_support] call.sid={call.sid}")
    return call.sid

async def play_script(call_sid: str, text: str):
    """
    No-op for demo because TwiML Bin is static.
    When you move to dynamic speech/Media Streams, implement TTS/DTMF here.
    """
    return
