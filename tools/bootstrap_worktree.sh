#!/usr/bin/env bash
# Make a fresh clone or a fresh git worktree test-ready in one command.
#
# Why this exists: the global-class cache (.godot/) does not exist in a new
# checkout, so strict-typed scripts do not parse until an import pass has run, and
# generated art (everything under assets/_generated/) is gitignored, so it does not
# exist either. No tracked scene names generated art any more (the room backgrounds
# are tracked stand-ins in content/), but the generated pictures are what
# tools/seed_placeholders.gd copies from for a new room. This script runs three steps:
#   1. an editor import pass, to import the tracked audio and art and register
#      every class_name (the SfxManager autoload loads imported .wav files, so the
#      generators print resource errors if they run before this);
#   2. the four generators in tools/;
#   3. a second import pass, to import what the generators just wrote.
#
# Usage (from anywhere):
#   tools/bootstrap_worktree.sh                  # bootstrap the project this script lives in
#   tools/bootstrap_worktree.sh /path/to/project # bootstrap another checkout
#
# Environment:
#   GODOT_BIN  path to the Godot 4.6 binary. Default: first existing of
#              <project>/../Godot.app/Contents/MacOS/Godot, the parent of the
#              main checkout (git worktrees live under <main>/.claude/worktrees/),
#              or `godot` on PATH.
#   BOOTSTRAP_HOME  private HOME for Godot (its user:// data and editor settings
#              land there, never in the real home). Default: /tmp/upg-bootstrap-<folder name>.
#
# Exit code: 0 when every step finished and neither import pass nor any generator
# printed a SCRIPT ERROR, Parse Error or engine ERROR line; 1 otherwise.
set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="${1:-$(cd "$script_dir/.." && pwd)}"
project_dir="$(cd "$project_dir" && pwd)"

if [ ! -f "$project_dir/project.godot" ]; then
	echo "bootstrap: no project.godot in '$project_dir'" >&2
	exit 1
fi

find_godot() {
	if [ -n "${GODOT_BIN:-}" ]; then
		echo "$GODOT_BIN"
		return
	fi
	local candidate
	# A plain checkout keeps Godot.app next to the project; a worktree keeps it next to the main checkout.
	for candidate in \
		"$project_dir/../Godot.app/Contents/MacOS/Godot" \
		"$project_dir/../../../../Godot.app/Contents/MacOS/Godot" \
		"$(command -v godot 2>/dev/null || true)"; do
		if [ -n "$candidate" ] && [ -x "$candidate" ]; then
			echo "$candidate"
			return
		fi
	done
}

godot_bin="$(find_godot)"
if [ -z "$godot_bin" ] || [ ! -x "$godot_bin" ]; then
	echo "bootstrap: Godot binary not found. Set GODOT_BIN=/path/to/Godot." >&2
	exit 1
fi
# Collapse the ../ segments so messages and logs show one clean absolute path.
godot_bin="$(cd "$(dirname "$godot_bin")" && pwd)/$(basename "$godot_bin")"

folder_name="$(basename "$project_dir")"
export HOME="${BOOTSTRAP_HOME:-/tmp/upg-bootstrap-$folder_name}"
mkdir -p "$HOME"

echo "bootstrap: project = $project_dir"
echo "bootstrap: godot   = $godot_bin"
echo "bootstrap: HOME    = $HOME"

cd "$project_dir" || exit 1

# Run the editor import pass and report errors in its log.
# $1 = label for messages and the log file name.
# $2 = "warmup" to only print what it found (returns 0), anything else to fail on real errors.
run_import_pass() {
	local label="$1"
	local mode="${2:-strict}"
	echo "bootstrap: import pass ($label)"
	"$godot_bin" --headless --path . --editor --quit >"$HOME/$label.log" 2>&1
	local status=$?
	if [ "$status" -ne 0 ]; then
		echo "bootstrap: import pass '$label' exited $status (see $HOME/$label.log)" >&2
		[ "$mode" = "warmup" ] || return 1
	fi
	# Teardown noise (RID leaks, ObjectDB, CanvasLayer) is expected; real errors are not.
	if grep -E "^(ERROR|SCRIPT ERROR)|Parse Error" "$HOME/$label.log" | grep -v -E "RID|ObjectDB|CanvasLayer" >"$HOME/$label.errors"; then
		if [ "$mode" = "warmup" ]; then
			echo "bootstrap: note: the warm-up pass saw $(wc -l <"$HOME/$label.errors" | tr -d ' ') error line(s), tolerated on a bare clone (nothing is imported yet); the pass after the generators decides"
			return 0
		fi
		echo "bootstrap: import pass '$label' printed errors:" >&2
		head -n 10 "$HOME/$label.errors" >&2
		return 1
	fi
	return 0
}

failed=0

# 1. warm the import cache so the generators can load the audio autoload and every class_name.
#    A pass on a bare clone may print resource errors (nothing is imported yet), so this one
#    only reports; step 3 is the one that must come out clean.
run_import_pass import_before_generators warmup

# 2. generators. Order matters: chess sprites first (the demo map and room art read them),
#    tiles before the map.
generators="generate_chess_sprites generate_kingdom_tiles generate_demo_map generate_stage1_room_art"
for generator in $generators; do
	echo "bootstrap: running tools/$generator.gd"
	if ! "$godot_bin" --headless --path . -s "tools/$generator.gd" >"$HOME/$generator.log" 2>&1; then
		echo "bootstrap: FAILED tools/$generator.gd (see $HOME/$generator.log)" >&2
		tail -n 5 "$HOME/$generator.log" >&2
		failed=1
	elif grep -q -E "SCRIPT ERROR|Parse Error" "$HOME/$generator.log"; then
		echo "bootstrap: tools/$generator.gd printed script errors (see $HOME/$generator.log)" >&2
		grep -E "SCRIPT ERROR|Parse Error" "$HOME/$generator.log" | head -n 5 >&2
		failed=1
	fi
done

# 3. import what the generators wrote (.import files for the new PNGs).
run_import_pass import_after_generators || failed=1

if [ "$failed" -eq 0 ]; then
	echo "bootstrap: OK. Run the suite with: HOME=$HOME \"$godot_bin\" --headless --path . -s tests/run_tests.gd"
else
	echo "bootstrap: finished WITH PROBLEMS" >&2
fi
exit "$failed"
