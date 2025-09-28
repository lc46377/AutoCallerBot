def build_summary_object(ctx):
    return {
        "ticket_id": ctx.outcome.get("ticket"),
        "resolution": "Full refund to original payment",
        "amount": ctx.outcome.get("amount"),
        "eta": ctx.outcome.get("eta"),
        "citations": ctx.plan.get("citations", []),
        "notes": ["Prepaid label emailed"]
    }
