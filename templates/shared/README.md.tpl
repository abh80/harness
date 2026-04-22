# Snapshot Harness Project

Author program → record expected output → run tests on every change.

## Layout

- `samples/<lang>-hello/` — example programs (delete or replace)
- `<your-program>/harness.toml` — declare install/build/run/clean commands
- `<your-program>/__tests__/<case>/{in.txt,args.txt,expect.txt,expect.err.txt,exit.txt}`

## Workflow (PowerShell)

```powershell
.\scripts\install.ps1 -All       # one-time per program
.\scripts\build.ps1 -All
.\scripts\record.ps1 -All        # capture current output as golden
.\scripts\test.ps1 -All          # verify nothing drifted
.\scripts\test.ps1 -Program python-hello -Filter default
.\scripts\clean.ps1 -All -Refs   # nuke build artifacts + recorded outputs
```

## Workflow (Bash)

```bash
./scripts/install.sh --all
./scripts/build.sh --all
./scripts/record.sh --all
./scripts/test.sh --all
./scripts/test.sh --program python-hello --filter default
./scripts/clean.sh --all --refs
```

## Case files

| File | Role | Written by record? |
|---|---|---|
| `in.txt` | piped stdin | never |
| `args.txt` | extra CLI args | never |
| `expect.txt` | golden stdout | always |
| `expect.err.txt` | golden stderr | only when stderr non-empty |
| `exit.txt` | expected exit code | only when ≠ 0 |
