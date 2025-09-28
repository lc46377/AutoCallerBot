create table if not exists tasks (
  id text primary key, user_id text,
  brand text, department_hint text,
  goal text, reason text,
  identifiers text, constraints text, auth text, evidence text,
  status text, created_at text default CURRENT_TIMESTAMP, updated_at text default CURRENT_TIMESTAMP
);
create table if not exists calls (
  id text primary key, task_id text, twilio_sid text, state text,
  rep_name text, rep_id text, started_at text default CURRENT_TIMESTAMP, ended_at text
);
create table if not exists messages (
  id integer primary key autoincrement, task_id text, role text, text text, ts text default CURRENT_TIMESTAMP
);
create table if not exists summaries (
  task_id text primary key, ticket_id text, resolution text, amount real, eta text,
  citations text, notes text, created_at text default CURRENT_TIMESTAMP
);
