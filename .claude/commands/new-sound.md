---
description: Add a sound effect the structured way (clip track or event registry)
---

Add a new sound without breaking the three-layer audio structure.

1. Get the audio file:
   - Placeholder: add a generator function to `tools/generate_sfx.py` and run
	 `python3 tools/generate_sfx.py` (writes `assets/sfx/<name>.wav`). It is a stand-in for the
	 owner's sound: add its row (kind `sfx`) to `ADOPTED_PLACEHOLDERS` in
	 `tools/seed_placeholders.gd`, run that tool, and commit `content/_placeholders.json`
	 so `tools/list_placeholders.gd` lists it. Or
   - Real asset: drop the `.wav` into `assets/sfx/` (mono, short). Overwriting
	 an existing name upgrades every use of it automatically (and clears its placeholder
	 flag, which is a file hash).

2. Pick the layer — this decides everything:
   - **Motion sound** (belongs to an animation moment — a swing, a flinch, a
	 windup): open the actor scene → `AnimationPlayer` → the clip → add an
	 AUDIO track targeting the actor's `AudioPlayer` node → key the stream at
	 the right time. No code. Looping clips re-fire the key each loop.
   - **Event sound** (no clip — pickups, room clear, jingles, UI): open
	 `presentation/audio/sfx_manager.tscn` → Inspector → add the stream to the
	 `streams` dictionary under a `&"name"` key. Then have the `AudioBridge`
	 (`presentation/bridges/audio_bridge.gd`) call `play(&"name")` from the matching drained event:
	 one const for the name and one `router.on(...)` line in its `register()`.
	 (The registry will move to `content/audio/sound_bank.tres` with the shell milestones;
	 this recipe is then rewritten.)

3. Never: play audio from a system, from a view, or from anywhere that isn't
   a clip track or the `AudioBridge`. Mixing tweaks (volumes per group, effects) go
   in `default_bus_layout.tres`, not on individual players.

4. Verify: editor import pass (the new `.wav` needs its committed `.import`), then `/verify`
   (asserts the bus layout and the SfxManager registry) + a real-render run for script errors.
