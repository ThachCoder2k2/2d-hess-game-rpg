---
description: Run one editor-first milestone through the phase-gate loop
argument-hint: [what to build]
---

Deliver one milestone — **$ARGUMENTS** — following the project's phase-gate workflow.
Keep the playable slice green the whole way. Do not start a broad new phase while the
current one has a broken slice. The owner's six steps always hold: plan, owner approves,
build, verify, owner plays and reviews, accepted. You own steps 1, 3 and 4; the others
are the owner's.

1. **Orient.** Read `CLAUDE.md`, `AGENTS.md`, `docs/where-we-are.md` (status),
   the matching milestone in `docs/game-base-plan.md` section 15 (scope, acceptance,
   dependencies), the latest `task_plan.md` phases, and recent `progress.md`. Run
   `git status --short` and note the human's dirty files — never stage or revert them.

2. **Scope the smallest playable slice** of the request. State it in one sentence.
   If it changes art direction, core controls, scope, removes a mechanic, makes a
   destructive migration or adds a dependency — ask the human first (per AGENTS.md;
   the rows of `docs/game-base-plan.md` section 2.3 list the known cases and their stated
   defaults). Otherwise pick sensible defaults and proceed.

3. **Research, then build editor-first on the ECS.** For any new mechanic, first check
   Godot's built-in nodes/features for the capability; then a proven addon (ask the human
   before adding a dependency); custom script only if neither fits — say why in the
   commit. Prefer new/edited `.tscn` + `.tres` over new script. Place new work by the ECS
   map in `CLAUDE.md`: new state is a pure-data component in its own file under `ecs/components/`
   (`ecs_components.gd` is frozen); a new decision is a system in `ecs/systems/<phase>/` (only
   `ViewSyncSystem` touches nodes); an editor-draggable component extends `EntityComponent` in
   `authoring/entity_components/`; presentation consumes `drain_events()` (and the `HudSnapshot`
   once it exists). Content goes in `content/` (zero `.gd`). Never hardcode content, never
   duplicate a `.tres` value in code, never `_draw()` an actor/pickup body. Do not move or rename
   files by hand: only `tools/move_res.py` does (one folder per commit, `stamp_uids.gd --check`
   CLEAN, the dump baselines unchanged except for path strings).

4. **Add or update tests** for behavior and scene ownership (assertion messages read as
   a spec). Simulation tests drive `EcsWorld.tick(delta)` by hand.

5. **Verify** with `/verify` (self-tests, strict runner, `git diff --check`, uid check). Fix until
   green.
   If visuals changed, capture a frame with `--write-movie` and inspect it.

6. **Update planning docs:** `progress.md` (what + why + verification + commit hash),
   bump the phase in `task_plan.md`, add durable facts to `findings.md`, and update the
   status in `docs/where-we-are.md` if an area moved a step. Never write "owner approved"
   without the owner's exact sentence and date.

7. **Commit + push.** One logical change, why-focused message, explicit staged paths
   (exclude the human's dirty files and `.mcp.json`; include every new `.gd`'s `.gd.uid`).
   Branch first if on `main` and the change is large.

8. **Hand off** any art/feel/layout decisions to the human using the AGENTS.md handoff
   format (Open / Tune / Goal / Try / Tell me).

9. **Owner gate.** If this milestone ends at an owner gate in `docs/game-base-plan.md`
   section 15 (OG0 after M1a, OG1 after M5, OG2 after M7b, OG3 after M9, OG4 after M13),
   or it reaches step 5 of the owner's rule (the owner plays and reviews feel, art or
   prose), stop here. Prepare the gate package: what the owner should open or read, what
   to try, and the exact questions (Open / Tune / Goal / Try / Tell me), and list every
   default you took. Do not start the next milestone's gated work and do not mark anything
   accepted. If the owner has not responded, continue only on the stated defaults and log
   each assumption in `progress.md` as "no owner response, defaults taken".

Report: what was built, the verification result, the commit hash, any handoff, and the
gate status (reached / not applicable, and which defaults are in force).
