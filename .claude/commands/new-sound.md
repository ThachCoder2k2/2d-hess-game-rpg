---
description: Add a sound effect the structured way (clip track or event registry)
---

Add a new sound without breaking the three-layer audio structure.

1. Get the audio file:
   - Placeholder: add a generator function to `tools/generate_sfx.py` and run
	 `python3 tools/generate_sfx.py` (writes `assets/sfx/<name>.wav`), or
   - Real asset: drop the `.wav` into `assets/sfx/` (mono, short). Overwriting
	 an existing name upgrades every use of it automatically.

2. Pick the layer — this decides everything:
   - **Motion sound** (belongs to an animation moment — a swing, a flinch, a
	 windup): open the actor scene → `AnimationPlayer` → the clip → add an
	 AUDIO track targeting the actor's `AudioPlayer` node → key the stream at
	 the right time. No code. Looping clips re-fire the key each loop.
   - **Event sound** (no clip — pickups, room clear, jingles, UI): open
	 `objects/audio/sfx_manager.tscn` → Inspector → add the stream to the
	 `streams` dictionary under a `&"name"` key. Then have the main.gd bridge
	 call `_play_sfx(&"name")` from the matching drained event. One line.

3. Never: play audio from a system, from a view, or from anywhere that isn't
   a clip track or the bridge. Mixing tweaks (volumes per group, effects) go
   in `default_bus_layout.tres`, not on individual players.

4. Verify: editor import pass, then `run_tests` (asserts the bus layout and
   the SfxManager registry) + a real-render run for script errors.
