# The Unbound Pawn - Owner Review Template

**Purpose:** make feedback specific, trackable, and safe to act on.  
**Use for:** review batches, one-room specs, editor scenes, combat feel, art,
animation, audio, UI, and release checks.

Copy the relevant section into `progress.md`, an issue, or the reviewed spec
when giving feedback.

---

## Review Header

```text
Review target:
Review type: design / editor scene / gameplay feel / art / animation / audio / UI / release
Reviewer:
Date:
State: draft / needs_revision / approved / owner_review / accepted
```

## Fast Verdict

```text
Overall verdict:
  [ ] approve
  [ ] approve with small fixes
  [ ] revise before approval
  [ ] block, do not implement

One-sentence reason:
```

---

## Design Review

Use this for review batches and design specs.

```text
What matches the game:

What does not match the game:

Missing decision:

Scope concern:

Gameplay concern:

Art / readability concern:

Editor workflow concern:

Must change before approval:

Approved parts:

Rejected parts:

Owner decision:
```

Pass condition:

```text
The design is specific enough that Codex can create the next task without
guessing the fantasy, scope, required nodes/assets, or definition of done.
```

---

## Editor Scene Review

Use this inside Godot after opening a scene.

```text
Scene reviewed:

Can I select and move important objects in the editor?

Can I understand the node tree?

Does the scene look like the intended place?

Does the TileMap / collision / exits make sense?

Does anything still feel script-hidden?

What feels good:

What must change:

What can wait:

Owner decision:
```

Pass condition:

```text
The owner can reasonably modify the room without asking Codex to explain hidden
runtime construction.
```

---

## Gameplay Feel Review

Use this after playing a build or editor run.

```text
Build / scene:

Input used:

Movement feel:

Attack feel:

Enemy readability:

Damage fairness:

Pacing:

Most confusing moment:

Most satisfying moment:

Must fix before acceptance:

Owner decision:
```

Pass condition:

```text
The player can understand what happened, why they were hit, and what they could
do better next time.
```

---

## Art And Animation Review

Use this for sprites, tiles, VFX, and AnimationPlayer/AnimationTree work.

```text
Asset / scene reviewed:

Does the silhouette read clearly?

Does it match the child's bedroom chess-war fantasy?

Does it stay readable during combat?

Does the animation show intent before impact?

Does it look editable in Godot?

What feels good:

What must change:

What can wait:

Owner decision:
```

Pass condition:

```text
The visual improves mood and readability at the same time.
```

---

## Audio Review

Use this for SFX, music, warning sounds, UI sounds, and mix passes.

```text
Audio reviewed:

Does it match the material/fantasy?

Is it useful for timing or feedback?

Is anything too loud, sharp, repetitive, or unclear?

Does it conflict with other important sounds?

What feels good:

What must change:

What can wait:

Owner decision:
```

Pass condition:

```text
Important gameplay sounds are recognizable and useful without becoming annoying.
```

---

## Accepted Decision Format

Use short, explicit acceptance text:

```text
accept <target>
approve <target> for implementation planning
revise <target>: <specific change>
block <target>: <reason>
```

Examples:

```text
approve Batch 1 for implementation planning
revise T1_WhiteKingsFall: make the room feel more like a bedroom floor, less like a stone castle
accept T2_FallenSwordTile scene
block Knight boss implementation: telegraph language is not approved yet
```
