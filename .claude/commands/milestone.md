---
description: Run one editor-first milestone through the phase-gate loop
argument-hint: [what to build]
---

Deliver one milestone — **$ARGUMENTS** — following the project's phase-gate workflow.
Keep the playable slice green the whole way. Do not start a broad new phase while the
current one has a broken slice.

1. **Orient.** Read `AGENTS.md`, the latest `task_plan.md` phases, and recent
   `progress.md`. Run `git status --short` and note the human's dirty files —
   never stage or revert them.

2. **Scope the smallest playable slice** of the request. State it in one sentence.
   If it changes art direction, core controls, scope, or removes a mechanic — ask the
   human first (per AGENTS.md). Otherwise pick sensible defaults and proceed.

3. **Research, then build editor-first.** For any new mechanic, first check Godot's
   built-in nodes/features for the capability; then a proven addon (ask the human
   before adding a dependency); custom script only if neither fits — say why in the
   commit. Prefer new/edited `.tscn` + `.tres` over new script. Scripts only for
   reusable behavior. Never hardcode content, never duplicate a `.tres` value in
   code, never `_draw()` an actor/pickup body.

4. **Add or update tests** for behavior and scene ownership (assertion messages read as
   a spec).

5. **Verify** with `/verify` (tests + import + `git diff --check`). Fix until green.
   If visuals changed, capture a frame with `--write-movie` and inspect it.

6. **Update planning docs:** `progress.md` (what + why + verification + commit hash),
   bump the phase in `task_plan.md`, add durable facts to `findings.md`.

7. **Commit + push.** One logical change, why-focused message, explicit staged paths
   (exclude the human's dirty files and `.mcp.json`). Branch first if on `main` and
   the change is large.

8. **Hand off** any art/feel/layout decisions to the human using the AGENTS.md handoff
   format (Open / Tune / Goal / Try / Tell me).

Report: what was built, the verification result, the commit hash, and any handoff.
