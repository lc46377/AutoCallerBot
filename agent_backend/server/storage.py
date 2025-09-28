import sqlite3, uuid, json

DB_FILE = "dev.db"

async def init_db():
    conn = sqlite3.connect(DB_FILE)
    with open("migrations/001_init.sql") as f:
        conn.executescript(f.read())
    conn.close()

async def create_task(task):
    tid = str(uuid.uuid4())
    conn = sqlite3.connect(DB_FILE); cur = conn.cursor()
    cur.execute("""insert into tasks(id,user_id,brand,department_hint,goal,reason,identifiers,constraints,auth,evidence,status)
                   values(?,?,?,?,?,?,?,?,?,?,?)""",
        (tid, task.user_id, task.brand, task.department_hint, task.goal, task.reason,
         json.dumps(task.identifiers), json.dumps(task.constraints), json.dumps(task.auth),
         json.dumps(task.evidence), "created"))
    conn.commit(); conn.close(); return tid

async def load_task(task_id):
    conn = sqlite3.connect(DB_FILE); cur = conn.cursor()
    row = cur.execute("select * from tasks where id=?", (task_id,)).fetchone()
    cols=[c[0] for c in cur.description]; conn.close()
    d=dict(zip(cols,row))
    for k in ["identifiers","constraints","auth","evidence"]:
        d[k]=json.loads(d[k]) if d[k] else {}
    return d

async def set_task_status(task_id, status):
    conn = sqlite3.connect(DB_FILE); cur = conn.cursor()
    cur.execute("update tasks set status=?, updated_at=CURRENT_TIMESTAMP where id=?", (status, task_id))
    conn.commit(); conn.close()

async def save_summary(task_id, summary):
    conn = sqlite3.connect(DB_FILE); cur = conn.cursor()
    cur.execute("""insert or replace into summaries(task_id,ticket_id,resolution,amount,eta,citations,notes)
                   values(?,?,?,?,?,?,?)""",
                (task_id, summary.get("ticket_id"), summary.get("resolution"),
                 summary.get("amount"), summary.get("eta"),
                 json.dumps(summary.get("citations",[])), json.dumps(summary.get("notes",[]))))
    conn.commit(); conn.close()

async def get_task(task_id):
    conn = sqlite3.connect(DB_FILE); cur = conn.cursor()
    row = cur.execute("select * from tasks where id=?", (task_id,)).fetchone()
    if not row: return None
    cols=[c[0] for c in cur.description]; conn.close()
    return dict(zip(cols,row))

async def get_summary(task_id):
    conn = sqlite3.connect(DB_FILE); cur = conn.cursor()
    row = cur.execute("select * from summaries where task_id=?", (task_id,)).fetchone()
    if not row: return {}
    cols=[c[0] for c in cur.description]; conn.close()
    d=dict(zip(cols,row))
    d["citations"]=json.loads(d["citations"]) if d["citations"] else []
    d["notes"]=json.loads(d["notes"]) if d["notes"] else []
    return d
