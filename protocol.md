# AI-to-AI Handoff Protocol

## Directory Structure
```
handoff/
├── tasks/       # Director writes task files here
├── results/     # Executor writes results here
└── protocol.md  # This file
```

## Task File Format (`handoff/tasks/{id}.json`)
```json
{
  "id": "login-route",
  "description": "Add a login route to app.py",
  "constraints": "Use bcrypt for password hashing",
  "acceptance": "POST /login returns 200 on valid credentials, 401 on invalid"
}
```

## Execution Command (Terminal 2 - Executor)
```bash
cmd -p "
  Read handoff/tasks/login-route.json and execute it.
  Do exactly what the task says, nothing more.
  When done, write the result to handoff/results/login-route.json
"
```

## Result File Format (`handoff/results/{id}.json`)
```json
{
  "id": "login-route",
  "status": "done" | "failed",
  "summary": "Added POST /login route to app.py",
  "output": "Details of what was done"
}
```

## Workflow
1. Director plans and writes a task file
2. Executor runs `cmd -p` pointing at that task file
3. Executor reads the task, implements, writes result
4. Director reads the result, writes next task
5. Repeat
```
