import asyncio
from server.state import S, Ctx
from server.storage import load_task, set_task_status, save_summary
from server.rag_client import check_missing, retrieve_context, make_plan
from server.twilio_driver import dial_support, play_script
from server.summarize import build_summary_object

async def run_fsm(task_id: str):
    ctx = Ctx(task_id=task_id, brief=await load_task(task_id))
    state = S.PARSE
    try:
        while state != S.HALT:
            if state==S.PARSE:
                await set_task_status(task_id, "calling"); state = S.CHECK

            elif state==S.CHECK:
                res = await check_missing(ctx.brief)
                if res.get("status") == "needs_info":
                    await set_task_status(task_id, "needs_info")  # app should prompt user
                    return
                state = S.RETRIEVE

            elif state==S.RETRIEVE:
                ctx.context = await retrieve_context(ctx.brief); state = S.PLAN

            elif state==S.PLAN:
                ctx.plan = await make_plan(ctx.brief, ctx.context); state = S.DIAL

            elif state==S.DIAL:
                ctx.call_sid = await dial_support(ctx.brief)
                await asyncio.sleep(1); state = S.AUTH

            elif state==S.AUTH:
                await play_script(ctx.call_sid, ctx.plan["opening"])
                state = S.NEGOTIATE

            elif state==S.NEGOTIATE:
                # MVP: speak primary ask; TwiML mock will "approve"
                await play_script(ctx.call_sid, ctx.plan["negotiation_ladder"][0])
                await asyncio.sleep(1); state = S.CONFIRM

            elif state==S.CONFIRM:
                # MVP stub (replace later with parsed transcript or live webhook)
                ctx.outcome = {"status":"resolved","ticket":"WM-CASE-55321","amount":89.99,"eta":"3-5 business days"}
                state = S.SUMMARIZE

            elif state==S.SUMMARIZE:
                summary = build_summary_object(ctx)
                await save_summary(ctx.task_id, summary)
                await set_task_status(ctx.task_id, "resolved")
                state = S.HALT
    except Exception:
        await set_task_status(task_id, "failed")
