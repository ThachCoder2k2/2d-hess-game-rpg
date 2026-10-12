extends SceneTree

## Seeds the placeholders and records which files they are (docs/game-base-plan.md section 12).
##
## The art-swap contract: the owner overwrites a file whose name and role never change, and the
## game needs no edit. For that to work, the stand-in art must live in content/ (tracked, never
## in the gitignored assets/_generated/) and something must remember which files are still
## stand-ins. This tool does both:
##
##   1. GENERATED_SEEDS: a picture a generator painted into assets/_generated/ is COPIED into
##      content/ only when the target file is absent. It never overwrites the owner's file. A row
##      marked `supersedes_stand_in` may also replace an EARLIER stand-in, and only while that file
##      still equals the hash recorded for it (so it is provably not the owner's art); the new
##      stand-in is recorded in its place. PlaceholderManifest.seed_decision holds the rule.
##   2. ADOPTED_PLACEHOLDERS: art and audio that were already tracked when M1b ran, but that the
##      owner did not make, are recorded where they stand.
##   3. For every file in either list it records the sha256 in content/_placeholders.json.
##
## A file is a placeholder if and only if its sha256 still equals the recorded one, so the owner
## overwriting a file clears its flag with no extra edit (tools/list_placeholders.gd prints what
## is left). A file that is already in the manifest keeps its recorded hash for ever: running
## this tool again after the owner replaced a picture must not record the owner's art as a
## placeholder. A file that exists but is in neither list is never recorded: it is the owner's.
##
##   godot --headless --path . -s tools/seed_placeholders.gd             copy what is absent, record what is new
##   godot --headless --path . -s tools/seed_placeholders.gd -- --check  change nothing; exit 1 if anything would change
##
## Run the editor import pass afterwards (a copied PNG needs its .import) and commit the copied
## files with their .import sidecars. A new room, enemy or sound adds its row to the lists below.
## Exit code: 0 = ok, 1 = a source or a listed file is missing, or --check found work to do.

const PlaceholderManifest := preload("res://tools/placeholder_manifest.gd")

## Placeholders a generator makes. source is a generator output under assets/_generated/ (rebuilt
## by tools/bootstrap_worktree.sh); target is the file the game names.
const GENERATED_SEEDS: Array[Dictionary] = [
	{
		"source": "res://assets/_generated/rooms/t1_white_kings_fall_room.png",
		"target": "res://content/rooms/t1_white_kings_fall/background.png",
		"kind": "background",
		"id": "t1_white_kings_fall",
	},
	{
		"source": "res://assets/_generated/rooms/t2_fallen_sword_tile_room.png",
		"target": "res://content/rooms/t2_fallen_sword_tile/background.png",
		"kind": "background",
		"id": "t2_fallen_sword_tile",
	},
]

## Files that already stand in the tree as placeholders and are recorded exactly where they are.
## Left out on purpose: assets/map_pieces/ (the owner drew those) and assets/tiles/playground/
## (the owner's first tile kit); both are the owner's art, not stand-ins.
const ADOPTED_PLACEHOLDERS: Array[Dictionary] = [
	{"path": "res://content/player/body.png", "kind": "body", "id": "player", "origin": "tracked sprite adopted at M1b (was hero_pawn_unarmed.png); provenance in THIRD_PARTY_NOTICES.md"},
	{"path": "res://content/enemies/pawn_recruit/body.png", "kind": "body", "id": "pawn_recruit", "origin": "tracked sprite adopted at M1b (was black_pawn.png); provenance in THIRD_PARTY_NOTICES.md"},
	{"path": "res://content/enemies/knight_tracker/body.png", "kind": "body", "id": "knight_tracker", "origin": "tracked sprite adopted at M1b (was black_knight.png); traced from a font glyph, see THIRD_PARTY_NOTICES.md"},
	{"path": "res://content/player/icon.png", "kind": "icon", "id": "player", "origin": "tracked sprite adopted at M1b (was hero_pawn.png); also the project icon"},
	{"path": "res://content/skills/wooden_sword/icon.png", "kind": "icon", "id": "wooden_sword", "origin": "tracked sprite adopted at M1b (was toy_sword.png)"},
	{"path": "res://content/pickups/pencil_spear/icon.png", "kind": "icon", "id": "pencil_spear", "origin": "tracked sprite adopted at M1b (was pencil_spear.png)"},
	{"path": "res://content/pickups/ruler_blade/icon.png", "kind": "icon", "id": "ruler_blade", "origin": "tracked sprite adopted at M1b (was ruler_blade.png)"},
	{"path": "res://content/pickups/toy_weapon/pickup.png", "kind": "pickup", "id": "toy_weapon", "origin": "tracked sprite adopted at M1b (was toy_weapon_pickup.png)"},
	{"path": "res://assets/tiles/kingdom/atlas.svg", "kind": "tileset", "id": "kingdom", "origin": "tracked tile atlas adopted at M1b (was kingdom_tiles.svg); the owner's single-tile PNGs will replace it"},
	{"path": "res://assets/ui/actor_view/facing_arrow.png", "kind": "ui", "id": "facing_arrow", "origin": "tracked sprite adopted at M1b"},
	{"path": "res://assets/ui/actor_view/health_pip_full.png", "kind": "ui", "id": "health_pip_full", "origin": "tracked sprite adopted at M1b"},
	{"path": "res://assets/ui/actor_view/health_pip_empty.png", "kind": "ui", "id": "health_pip_empty", "origin": "tracked sprite adopted at M1b"},
	{"path": "res://assets/ui/actor_view/warning_aura.png", "kind": "ui", "id": "warning_aura", "origin": "tracked sprite adopted at M1b"},
	{"path": "res://assets/sfx/defeat_crumple.wav", "kind": "sfx", "id": "defeat_crumple", "origin": "generated by tools/generate_sfx.py"},
	{"path": "res://assets/sfx/defeat_jingle.wav", "kind": "sfx", "id": "defeat_jingle", "origin": "generated by tools/generate_sfx.py"},
	{"path": "res://assets/sfx/gate_open.wav", "kind": "sfx", "id": "gate_open", "origin": "generated by tools/generate_sfx.py"},
	{"path": "res://assets/sfx/hurt_thud.wav", "kind": "sfx", "id": "hurt_thud", "origin": "generated by tools/generate_sfx.py"},
	{"path": "res://assets/sfx/pickup_chime.wav", "kind": "sfx", "id": "pickup_chime", "origin": "generated by tools/generate_sfx.py"},
	{"path": "res://assets/sfx/room_clear.wav", "kind": "sfx", "id": "room_clear", "origin": "generated by tools/generate_sfx.py"},
	{"path": "res://assets/sfx/sword_whoosh.wav", "kind": "sfx", "id": "sword_whoosh", "origin": "generated by tools/generate_sfx.py"},
	{"path": "res://assets/sfx/telegraph_warning.wav", "kind": "sfx", "id": "telegraph_warning", "origin": "generated by tools/generate_sfx.py"},
	{"path": "res://assets/sfx/wake_stir.wav", "kind": "sfx", "id": "wake_stir", "origin": "generated by tools/generate_sfx.py"},
	{"path": "res://assets/music/unbound_march.wav", "kind": "music", "id": "unbound_march", "origin": "generated by tools/generate_music.py"},
]


func _init() -> void:
	var check_only := "--check" in OS.get_cmdline_user_args() or "--check" in OS.get_cmdline_args()
	var failed := false

	# What is recorded already. A missing manifest is a first run; an unreadable one is an error.
	var entries: Array[Dictionary] = []
	if FileAccess.file_exists(PlaceholderManifest.MANIFEST_PATH):
		var manifest := PlaceholderManifest.read_manifest()
		if not String(manifest["error"]).is_empty():
			printerr("SEED PLACEHOLDERS: %s" % manifest["error"])
			quit(1)
			return
		entries = manifest["entries"]
	var recorded_paths := {}
	for entry in entries:
		recorded_paths[entry["path"]] = true

	var work_lines := PackedStringArray()

	for seed_row in GENERATED_SEEDS:
		var source_path := String(seed_row["source"])
		var target_path := String(seed_row["target"])
		var recorded_entry := _entry_for_path(entries, target_path)
		var decision := PlaceholderManifest.seed_decision(seed_row, FileAccess.file_exists(target_path), recorded_entry)
		if decision == PlaceholderManifest.SEED_OWNERS_FILE:
			print("SEED PLACEHOLDERS: %s exists but is not recorded; treated as the owner's file, not a placeholder" % target_path.trim_prefix("res://"))
			continue
		if decision == PlaceholderManifest.SEED_NOTHING:
			continue
		if not FileAccess.file_exists(source_path):
			printerr("SEED PLACEHOLDERS: %s is missing; run tools/bootstrap_worktree.sh first" % source_path)
			failed = true
			continue
		var replacing := decision == PlaceholderManifest.SEED_REPLACE_STAND_IN
		work_lines.append("%s %s -> %s" % ["replace the stand-in with" if replacing else "copy", source_path.trim_prefix("res://"), target_path.trim_prefix("res://")])
		if check_only:
			continue
		if not _copy_file(source_path, target_path, replacing):
			printerr("SEED PLACEHOLDERS: could not copy %s to %s" % [source_path, target_path])
			failed = true
			continue
		if replacing:
			recorded_entry["sha256"] = FileAccess.get_sha256(target_path)
			recorded_entry["origin"] = PlaceholderManifest.seed_origin(seed_row)
		else:
			entries.append(_new_entry(target_path, String(seed_row["kind"]), String(seed_row["id"]), PlaceholderManifest.seed_origin(seed_row)))
		recorded_paths[target_path] = true

	for adopted_row in ADOPTED_PLACEHOLDERS:
		var adopted_path := String(adopted_row["path"])
		if recorded_paths.has(adopted_path):
			continue
		if not FileAccess.file_exists(adopted_path):
			printerr("SEED PLACEHOLDERS: %s is listed as a placeholder but the file does not exist" % adopted_path)
			failed = true
			continue
		work_lines.append("record %s" % adopted_path.trim_prefix("res://"))
		if check_only:
			continue
		entries.append(_new_entry(adopted_path, String(adopted_row["kind"]), String(adopted_row["id"]), String(adopted_row["origin"])))
		recorded_paths[adopted_path] = true

	for line in work_lines:
		print("SEED PLACEHOLDERS: %s%s" % ["would " if check_only else "", line])
	if check_only:
		print("SEED PLACEHOLDERS: --check: %d change(s) pending, %d placeholder(s) recorded" % [work_lines.size(), entries.size()])
		quit(1 if (failed or not work_lines.is_empty()) else 0)
		return

	if not work_lines.is_empty() or not FileAccess.file_exists(PlaceholderManifest.MANIFEST_PATH):
		var manifest_file := FileAccess.open(PlaceholderManifest.MANIFEST_PATH, FileAccess.WRITE)
		if manifest_file == null:
			printerr("SEED PLACEHOLDERS: cannot write %s (error %d)" % [PlaceholderManifest.MANIFEST_PATH, FileAccess.get_open_error()])
			quit(1)
			return
		manifest_file.store_string(PlaceholderManifest.manifest_text(entries))
		manifest_file.close()
		print("SEED PLACEHOLDERS: wrote %s with %d placeholder(s)" % [PlaceholderManifest.MANIFEST_PATH.trim_prefix("res://"), entries.size()])
		print("SEED PLACEHOLDERS: now run the editor import pass (godot --headless --path . --editor --quit) and commit the new files with their .import sidecars")
	else:
		print("SEED PLACEHOLDERS: nothing to do, %d placeholder(s) already recorded" % entries.size())
	quit(1 if failed else 0)


func _new_entry(path: String, kind: String, id: String, origin: String) -> Dictionary:
	return {"path": path, "kind": kind, "id": id, "sha256": FileAccess.get_sha256(path), "origin": origin}


## The manifest entry for a file, or an empty dictionary when the manifest does not list it. The
## dictionary is the entry itself, so changing it changes what is written back.
func _entry_for_path(entries: Array[Dictionary], path: String) -> Dictionary:
	for entry in entries:
		if entry["path"] == path:
			return entry
	return {}


## Copies source over to target (creating the folder). Over an existing file only when the caller
## has decided it is a stand-in being superseded (PlaceholderManifest.seed_decision).
func _copy_file(source_path: String, target_path: String, overwrite_stand_in := false) -> bool:
	if FileAccess.file_exists(target_path) and not overwrite_stand_in:
		return false
	var target_directory := ProjectSettings.globalize_path(target_path.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(target_directory) != OK:
		return false
	return DirAccess.copy_absolute(ProjectSettings.globalize_path(source_path), ProjectSettings.globalize_path(target_path)) == OK
