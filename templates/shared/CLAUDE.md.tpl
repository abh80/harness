# Authoring guide for AI assistants

## Adding a new program

1. Create `<dir>/harness.toml`:
   ```toml
   name = "<dir>"
   run  = "<command to execute>"
   ```
2. Add test case: `<dir>/__tests__/<case>/in.txt` (optional) and `expect.txt`.
3. Run `record` once to capture expected output. Verify it matches intent before committing.
4. Future runs use `test` to detect drift.

## Rules

- Never write `in.txt` or `args.txt` from code — they are author-controlled.
- Stdout is always compared. Stderr/exit only when their expect files exist.
- One program per directory. Tests co-located under `__tests__/`.
- Convention fallback: omit `harness.toml`, create `install.ps1`/`build.ps1`/`run.ps1`/`clean.ps1` (or `.sh`) instead — runner picks them up automatically.
