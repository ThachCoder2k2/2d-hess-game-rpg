#!/usr/bin/env python3
"""Build the owner-facing asset request list for "The Unbound Pawn".

Reads style.json and the five category spec files (characters, world, ui_story,
vfx, audio) and expands every group into ONE entry per file (one image, one
animation frame, one sound, one font, one sourced glyph). Each entry carries a
complete, self-contained generation prompt, and the whole list is written as
Markdown (for the owner) plus a JSON manifest (for tools).

Usage (from the repo root, once this file lives at tools/asset_requests/):

    python3 tools/asset_requests/build_requests.py
    python3 tools/asset_requests/build_requests.py --spec docs/assets/spec --out docs/assets

Defaults (repo layout): --spec docs/assets/spec, --out docs/assets,
--gitignore <repo>/.gitignore. When the script is not inside a repo checkout
(for example while it is still in /tmp) pass --spec, --out and --gitignore.

Output (all inside --out):
    README.md             how the list works, delivery checklist, counts
    STYLE.md              style block, global avoid, sound brief, scale table
    by-milestone.md       every id and path per milestone, must first
    asset-manifest.json   every entry with all fields, including the prompt
    requests/INDEX.md     every group with a link
    requests/<category>/<group_id>.md   the entries of one group

The generated files are rewritten on every run. The script only ever removes
files it generates; it wipes the whole --out folder only when that folder holds
nothing else that matters (it never holds the spec, this script, or a .git).

Validation (exit code 1 on any failure, nothing is written then):
    unique paths and ids, image entries have a size, every clip has exactly
    'frames' poses, every prompt contains the style block (or the sound brief),
    no path lies under a gitignored folder, plus format sanity checks (sound
    effects and voice blips end in .wav, music and ambience in .ogg). Content
    rules (lint_specs): the style block keeps its PERCENTAGES AND TRANSLUCENCY
    paragraph, a tile group names at most 10 colours, a voice-blip group
    describes the takes it really has, every chess piece is drawn on the 32x32
    canvas of its cell, no prompt names another group or points at a sibling
    file by name ("as path_pink_h", "identical to prop_closed.png", "idle frame 1"),
    music is one complete
    track (no stems). Pixel scale (owner decision 2026-10-13, "Tat ca 1x1", lint_pixel_scale):
    every image is drawn at 1x1, so every scale-table row has block_px 1, every CANVAS line
    says "1 art pixel = 1 game pixel", and no image prompt may still talk about 2x2 blocks,
    "chunky" art, half-size or half-resolution drawing, upscaling, art pixels as a unit of
    their own or a "world" versus "fine" pixel scale; the build fails with the group and the
    phrase. Warnings (not blocking): pair-style file names and images larger than 128x96.
    --self-test proves the rules catch those phrases and spare plain cell counts ("a 2x2-cell
    emblem").

Fonts (Vietnamese coverage, no spec needed):
    python3 tools/asset_requests/build_requests.py --check-font assets/fonts/ui_body_pixel.ttf
    python3 tools/asset_requests/build_requests.py --spec ... --out ... --check-fonts <repo root>
    The check reads the font's cmap table (the table FontFile.has_char reads)
    and fails with the list of missing code points; the rendering check of line
    height and diacritic clearance stays a human step.

Python 3 standard library only.
"""

import argparse
import json
import os
import re
import shutil
import struct
import sys
import unicodedata
from collections import Counter, OrderedDict, defaultdict
from pathlib import Path

SCRIPT_PATH = Path(__file__).resolve()
CATEGORIES = ["characters", "world", "ui_story", "vfx", "audio"]
IMAGE_KINDS = ("sprite", "tile", "prop", "icon", "ui", "portrait", "vfx")
AUDIO_KINDS = ("sfx", "music", "ambience", "voice_blip")
FONT_KINDS = ("font",)
SOURCING_KINDS = ("sourcing",)  # files the owner copies out of a licensed pack (nothing is drawn): the Kenney CC0 input glyphs
PRIORITIES = ("must", "should", "could")
# Owner decision 2026-10-13 ("Tat ca 1x1"): EVERY image is drawn at 1x1 pixels on the native 640x360, so there is exactly one
# pixel scale and no per-kind or per-group block size. block_px stays in the entries and the manifest (always 1) so tools that
# read them keep working; lint_pixel_scale rejects any spec that asks for something else.
PIXEL_SCALE = 1
IMAGE_EXT = (".png",)
AUDIO_EXT = (".wav", ".ogg")
# Owner decision 2026-10-12 ("SFX WAV, nhac OGG"): sound effects and voice blips are WAV, music and ambience are OGG Vorbis.
AUDIO_EXT_BY_KIND = {"sfx": (".wav",), "voice_blip": (".wav",), "music": (".ogg",), "ambience": (".ogg",)}
FONT_EXT = (".ttf", ".otf")
PIECE_CLASSES = ("pawn", "knight", "bishop", "rook", "queen", "king", "boss", "fallen", "mixed")
# Sprites that are deliberately NOT a chess piece and therefore may be larger than one cell (everything else drawn as a
# sprite in the characters lane is a piece or a piece overlay and lives on the 32x32 canvas of its cell).
NON_PIECE_LARGE_SPRITES = ("boss_rule_engine", "child_hand", "child_hand_shadow")
PIECE_CANVAS = [32, 32]
MILESTONE_RE = re.compile(r"^M(\d+)([a-z]?)$")
GROUP_ID_RE = re.compile(r"^[a-z0-9_]+$")

# Validation rules that are deliberately not applied, reported at the end of the run
# and in README.md so nobody is surprised. Keep this list honest.
RELAXED = [
    "Fonts (kind 'font', 4 entries): the owner supplies a font file, nothing is drawn, so these "
    "prompts are sourcing briefs. They are exempt from the 'prompt contains the style block' rule, "
    "from the 'image entries have a size' rule and from the PNG checks (they must end in .ttf or .otf).",
    "CANVAS wording: every image prompt says '1 art pixel = 1 game pixel' (owner decision 2026-10-13: all art is 1x1, so the "
    "old chunky exception for world art is gone). Only opaque files (tiles, map ground tiles, paper tiles, vista tile_ fills) say "
    "'fully opaque' instead of 'transparent background'.",
    "DO NOT wording: the shared DO NOT line is written for one free-standing object on a transparent canvas. "
    "Tiles and opaque ground pieces use the 'surface' variant and UI, 9-patch, frame and fence files use the "
    "'frame' variant (style.json global_avoid_variants_en), so a floor, a wall, a panel or a fence is never "
    "forbidden by the line that goes with it. Every variant keeps the clauses it does not relax.",
    "Sourced glyphs (kind 'sourcing'): the keyboard and gamepad glyphs are not drawn, they are copied and renamed out of "
    "Kenney's CC0 pack 'Input Prompts Pixel'. Their prompts are sourcing briefs: exempt from the 'prompt contains the style "
    "block' rule; they must end in .png and sit on the 16x16 canvas of the pack.",
]
RELAXED_VI = [
    "Font (loại `font`, 4 mục): font do anh cung cấp, không có gì để vẽ, nên prompt của chúng là bản hướng dẫn tìm "
    "file. Các mục này được miễn quy tắc 'prompt chứa khối phong cách', quy tắc 'mục ảnh có kích thước' và kiểm tra "
    "PNG (thay bằng: đuôi phải là `.ttf` hoặc `.otf`).",
    "Dòng CANVAS trong prompt ảnh: mọi ảnh ghi 'một pixel vẽ = một pixel game' (quyết định của anh, 2026-10-13: tất cả 1x1, không còn "
    "ngoại lệ pixel to hơn cho tranh thế giới). Chỉ các file đánh dấu đặc (ô nền bản đồ, ô giấy, mảnh tile_ của vista, tile) ghi "
    "'đặc hoàn toàn' thay cho 'nền trong suốt'.",
    "Dòng DO NOT: dòng chung viết cho MỘT vật đứng riêng trên nền trong suốt. Tile và ô nền đặc dùng biến thể `surface`, "
    "UI/9-patch/khung/hàng rào dùng biến thể `frame` (style.json, global_avoid_variants_en) để sàn, tường, bảng, hàng rào "
    "không bị chính dòng cấm đi kèm cấm vẽ. Mỗi biến thể giữ nguyên mọi điều cấm mà nó không nới.",
    "Glyph phím và tay cầm (loại `sourcing`): không vẽ, chỉ chép và đổi tên file từ bộ CC0 'Input Prompts Pixel' của Kenney. "
    "Prompt của chúng là bản hướng dẫn lấy file nên được miễn quy tắc 'prompt chứa khối phong cách'; đuôi phải là `.png`, "
    "canvas 16x16 như bộ gốc.",
]


# --------------------------------------------------------------------------- helpers

class Problems:
    """Collects validation failures and non-fatal warnings."""

    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, msg):
        self.errors.append(msg)

    def warn(self, msg):
        self.warnings.append(msg)


def milestone_key(label):
    m = MILESTONE_RE.match(label or "")
    if not m:
        return (10 ** 6, label or "")
    return (int(m.group(1)), m.group(2))


def major_milestone(label):
    m = MILESTONE_RE.match(label or "")
    return "M" + m.group(1) if m else (label or "?")


def stem_of(name):
    """File name without its extension; sub-folders are folded in with underscores."""
    base = name.rsplit(".", 1)[0] if "." in os.path.basename(name) else name
    return base.replace("/", "_")


def fence_for(text):
    """Return a backtick fence longer than any backtick run inside text."""
    longest = 0
    for m in re.finditer(r"`+", text):
        longest = max(longest, len(m.group(0)))
    return "`" * max(3, longest + 1)


def md_cell(text):
    return str(text).replace("|", "\\|").replace("\n", " ")


def fmt_seconds(value):
    text = ("%.3f" % value).rstrip("0").rstrip(".")
    return text if text else "0"


# --------------------------------------------------------------------------- gitignore

def _glob_to_regex(pattern):
    """Translate one gitignore glob (no leading/trailing slash) to a regex string."""
    out = []
    i = 0
    n = len(pattern)
    while i < n:
        c = pattern[i]
        if c == "*":
            if pattern[i:i + 2] == "**":
                i += 2
                if i < n and pattern[i] == "/":
                    i += 1
                    out.append("(?:.*/)?")
                else:
                    out.append(".*")
                continue
            out.append("[^/]*")
        elif c == "?":
            out.append("[^/]")
        elif c == "[":
            j = pattern.find("]", i + 2)
            if j == -1:
                out.append(re.escape(c))
            else:
                body = pattern[i + 1:j]
                if body.startswith("!"):
                    body = "^" + body[1:]
                out.append("[" + body.replace("\\", "\\\\") + "]")
                i = j
        else:
            out.append(re.escape(c))
        i += 1
    return "".join(out)


def parse_gitignore(text):
    rules = []
    for raw in text.splitlines():
        line = raw.rstrip("\r\n")
        if not line.endswith("\\ "):
            line = line.rstrip()
        if not line or line.startswith("#"):
            continue
        negated = False
        if line.startswith("!"):
            negated = True
            line = line[1:]
        elif line.startswith("\\") and len(line) > 1 and line[1] in "#!":
            line = line[1:]
        dir_only = line.endswith("/")
        line = line.rstrip("/")
        if not line:
            continue
        anchored = "/" in line
        line = line.lstrip("/")
        rules.append({
            "negated": negated,
            "dir_only": dir_only,
            "anchored": anchored,
            "regex": re.compile(_glob_to_regex(line) + r"\Z"),
            "text": raw.strip(),
        })
    return rules


def gitignored_by(rules, rel_path):
    """Return the .gitignore line that ignores rel_path (file or any parent folder), or None."""
    parts = rel_path.split("/")
    for index in range(len(parts)):
        prefix = "/".join(parts[:index + 1])
        is_dir = index < len(parts) - 1
        verdict = None
        for rule in rules:
            if rule["dir_only"] and not is_dir:
                continue
            target = prefix if rule["anchored"] else parts[index]
            if rule["regex"].match(target):
                verdict = None if rule["negated"] else rule["text"]
        if verdict:
            return verdict
    return None


# --------------------------------------------------------------------------- loading

def load_json(path, problems):
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError:
        problems.error("missing file: %s" % path)
    except json.JSONDecodeError as exc:
        problems.error("invalid JSON in %s: %s" % (path, exc))
    return None


def load_specs(spec_dir, problems):
    style = load_json(spec_dir / "style.json", problems)
    specs = OrderedDict()
    for category in CATEGORIES:
        data = load_json(spec_dir / ("%s.json" % category), problems)
        if data is None:
            continue
        if data.get("category") != category:
            problems.error("%s.json: category is %r, expected %r" % (category, data.get("category"), category))
        if not isinstance(data.get("groups"), list):
            problems.error("%s.json: 'groups' must be a list" % category)
            continue
        specs[category] = data["groups"]
    if style is not None:
        for key in ("style_block_en", "global_avoid_en", "sound_brief_en", "global_avoid_audio_en", "scale_table",
                    "global_avoid_variants_en", "global_avoid_audio_variants_en"):
            if not style.get(key):
                problems.error("style.json: missing or empty %r" % key)
        for key, wanted in (("global_avoid_variants_en", IMAGE_AVOID_PROFILES),
                            ("global_avoid_audio_variants_en", AUDIO_AVOID_PROFILES)):
            for name in wanted:
                if not (style.get(key) or {}).get(name):
                    problems.error("style.json: %s has no %r variant" % (key, name))
    return style, specs


# --------------------------------------------------------------------------- scale / pixel grid

def resolve_block_px(group, scale_table):
    """Pixel block of an image group. Owner decision 2026-10-13 ('Tat ca 1x1'): always 1, for every kind and size.
    A spec that still asks for another block (a group 'block_px', a scale-table row) is rejected by lint_pixel_scale."""
    return PIXEL_SCALE


def colour_limit(group):
    """Colour budget from the style block: 16 per object, hero 14, tiles 10."""
    if group.get("kind") == "tile":
        return 10
    if group.get("folder", "").startswith("content/player") or group.get("group_id", "").startswith("hero_"):
        return 14
    return 16


# --------------------------------------------------------------------------- avoid profiles

# The shared DO NOT line is written for ONE free-standing object on a transparent canvas. That is wrong for a file whose
# subject IS a surface (a tile, a ground piece) or IS a frame (a panel, a 9-patch, a border piece, a fence), so style.json
# carries named variants of it. Resolution order: the file's own avoid_profile, then the group's, then the default of its
# kind (tile -> surface, ui -> frame), else the plain global list.
DEFAULT_IMAGE_AVOID_PROFILE_BY_KIND = {"tile": "surface", "ui": "frame"}
IMAGE_AVOID_PROFILES = ("surface", "frame")
AUDIO_AVOID_PROFILES = ("child_voice", "ambient_life")


def image_avoid_profile(group, item):
    """Name of the DO NOT variant for one image file ('' = the plain global list)."""
    profile = (item or {}).get("avoid_profile") or group.get("avoid_profile")
    if profile:
        return profile
    return DEFAULT_IMAGE_AVOID_PROFILE_BY_KIND.get(group.get("kind"), "")


def image_avoid_text(style, profile):
    if not profile:
        return style["global_avoid_en"]
    return style["global_avoid_variants_en"][profile]


def audio_avoid_text(style, group):
    profile = group.get("avoid_profile")
    if not profile:
        return style["global_avoid_audio_en"]
    return style["global_avoid_audio_variants_en"][profile]


def is_opaque(group, item=None):
    """True when the file fills its canvas with opaque pixels (tiles, ground pieces, vista fills)."""
    if item is not None and "opaque" in item:
        return bool(item["opaque"])
    if "opaque" in group:
        return bool(group["opaque"])
    return group.get("kind") == "tile"


# --------------------------------------------------------------------------- palette references

# A text-only generator cannot follow "see the district palette" or "same as dialogue_boxes", so a palette line never points
# at another group. When a group (or one of its files) wants the colours of another group it writes the token
# {palette:<group_id>}; the build copies that group's real palette text, hex values included, into the PALETTE line of every
# prompt. A file may carry its own palette_en (the same tokens work there) to override the group's palette.
PALETTE_REF_RE = re.compile(r"\{palette:([a-z0-9_]+)\}")
PALETTE_POINTER_RE = re.compile(
    r"\bsee (?:the|above|below|also)\b|\bsame as\b|\b(?:each )?district'?s? palette\b|\bpalette of (?:the )?(?:room|district|group)\b"
    r"|\bdistrict tile groups?\b|\bas (?:in|for|on) the\b|\bsimilar to the\b", re.I)


AUDIO_POINTER_RE = re.compile(r"\bsee (?:per|the|character|stems|above|below|also)\b|\bsame as\b", re.I)


def palette_index(specs):
    """group_id -> raw palette_en of every group; an id used by two categories is ambiguous (None)."""
    index = {}
    for category in CATEGORIES:
        for group in specs.get(category, []):
            gid = group.get("group_id")
            index[gid] = None if gid in index else (group.get("palette_en") or "")
    return index


def resolve_palette(text, index, where, problems, depth=0):
    """Copy the palette text of every {palette:<group_id>} token into text (recursively, three levels at most)."""
    def expand(match):
        gid = match.group(1)
        if index.get(gid) is None:
            problems.error("%s: palette token {palette:%s} names no group (or a group id used by two categories)" % (where, gid))
            return ""
        if depth >= 3:
            problems.error("%s: palette tokens nest too deeply (a loop?) at {palette:%s}" % (where, gid))
            return ""
        return resolve_palette(index[gid], index, where, problems, depth + 1).strip().rstrip(".")
    return PALETTE_REF_RE.sub(expand, text or "")


# --------------------------------------------------------------------------- prompt composition

TILE_SEAM_EN = {
    "floor": ("Tileable on all four edges with the district's plain floor tiles: the pixels along each edge "
              "continue seamlessly into a neighbouring tile of the same district, so a grid of mixed variants "
              "shows no seams."),
    "chalk": ("Mid pieces join end to end seamlessly along the bridge axis; the open sides meet the neighbouring "
              "void or floor tiles of the district without a visible seam."),
    "corruption": ("Tileable on all four edges with neighbouring corruption tiles and with the district's floor "
                   "tiles."),
    "wall": ("Tileable left-right with other tiles of the same wall set; the top and bottom edges meet the "
             "neighbouring wall and floor tiles of the district without a visible seam."),
    "gap": ("Tileable on all four edges with the other gap tiles of the district, so a repeated gap area has no "
            "visible seam."),
    "leapable_block": ("A single solid one-cell block: its outer shape need not tile, but its base meets the "
                       "district floor without a visible seam at the cell border."),
}
TILE_SEAM_UNLESS_EN = " (unless the description above says this tile is a deliberate end, corner or cap)"


def tile_data_line(tile_data):
    kind = tile_data.get("kind", "?")
    solid = bool(tile_data.get("solid"))
    head = "TILE DATA: cell kind '%s', %s." % (kind, "solid (blocks movement)" if solid else "walkable (not solid)")
    seam = TILE_SEAM_EN.get(kind)
    if seam:
        return head + " " + seam.rstrip(".") + TILE_SEAM_UNLESS_EN + "."
    return head


def canvas_line(group, opaque):
    width, height = group["size"]
    if opaque:
        exception = ""
        if "except where this description says" in group.get("details_en", ""):
            exception = " (except the hole the description names, which shows the floor below)"
        return ("CANVAS: exactly %dx%d pixels, fully opaque%s - alpha 255 on every pixel, the art fills the canvas "
                "edge to edge with no transparent background, %s, no anti-aliasing." %
                (width, height, exception, GRID_PHRASE))
    return ("CANVAS: exactly %dx%d pixels, transparent background, %s, no anti-aliasing to transparency." %
            (width, height, GRID_PHRASE))


# Owner decision 2026-10-13 ("Tat ca 1x1"): the same wording on every image prompt, as the original brief asked.
GRID_PHRASE = "1 art pixel = 1 game pixel (every pixel of the canvas is placed individually at native size)"


def frame_subject(entry, group, reference_path, is_first_of_group):
    noun = {"sprite": "character", "tile": "tile", "prop": "object", "icon": "icon", "ui": "UI element",
            "portrait": "portrait", "vfx": "effect"}.get(group["kind"], "object")
    text = "frame %d of %d of the %s animation (%s, %d fps): %s" % (
        entry["frame"], entry["frames"], entry["clip"], "loop" if entry["loop"] else "one-shot",
        entry["fps"], entry["pose"].strip())
    if not text.endswith((".", "!", "?")):
        text += "."
    if is_first_of_group:
        text += (" This frame sets the look of the whole group: the %s, proportions, palette and canvas position "
                 "that every other frame of every clip must copy; only the pose changes between frames. Generate this "
                 "frame FIRST and keep it: it is the reference image that every later frame is generated from." % noun)
    else:
        text += (" Same %s, proportions, palette and canvas position as the reference image %s; only the pose changes. "
                 "REFERENCE: draw that reference file first, then attach it to the generator as the reference image "
                 "for this frame (a text-only tool cannot open a path)." % (noun, reference_path))
    return text


def compose_image_prompt(style, group, entry, reference_path, is_first_of_group):
    lines = [style["style_block_en"].rstrip(), ""]
    if entry["is_frame"]:
        lines.append("SUBJECT: " + group["subject_en"].strip())
        lines.append("THIS FRAME: " + frame_subject(entry, group, reference_path, is_first_of_group))
    else:
        lines.append("SUBJECT: " + group["subject_en"].strip())
        lines.append("THIS FILE: " + entry["what_en"].strip())
    if group.get("details_en", "").strip():
        lines.append("DETAILS: " + group["details_en"].strip())
    lines.append(canvas_line(group, entry["opaque"]))
    lines.append("ANCHOR: " + (group.get("anchor") or "none").strip())
    palette = (entry.get("palette_text") or "").strip()
    lines.append("PALETTE: " + (palette if palette else "the shared palette of the style above only; no extra colours."))
    if entry.get("tile_data"):
        lines.append(tile_data_line(entry["tile_data"]))
    lines.append("DO NOT: " + join_avoid(image_avoid_text(style, entry["avoid_profile"]), group.get("avoid_en")))
    return "\n".join(lines)


def join_avoid(global_text, group_text):
    """Global avoid list followed by the group's own list, as one sentence."""
    head = global_text.strip().rstrip(".")
    extra = (group_text or "").strip().rstrip(".")
    if not extra or extra.lower().startswith("only the global avoid list"):
        return head + "."  # 'Only the global avoid list applies' says nothing inside a prompt that already carries the list
    separator = ". " if extra[:1].isupper() else "; "
    return head + separator + extra + "."


def loop_phrase(is_loop, ext=".wav"):
    if is_loop and ext == ".ogg":
        # Godot reads no loop points out of an Ogg Vorbis file: the loop flag is an import setting, so the file stays plain.
        return ("LOOP: yes, seamless. The first and last samples are continuous, with no click, no fade and no audible seam, and the "
                "tail of the last bar flows into the first bar. Do not embed loop tags or a loop chunk: the engine switches "
                "looping on when it imports the file.")
    if is_loop:
        return ("LOOP: yes, seamless. Embed a smpl loop chunk spanning the whole file; the first and last samples are continuous, "
                "with no click, no fade and no audible seam.")
    return "LOOP: no. One-shot with a short natural tail, no click at the start or the end."


def compose_audio_prompt(style, group, entry):
    audio = group["audio"]
    lines = [style["sound_brief_en"].rstrip(), ""]
    lines.append("SOUND: " + group["subject_en"].strip())
    lines.append("THIS FILE: " + entry["what_en"].strip())
    if group.get("details_en", "").strip():
        lines.append("DETAILS: " + group["details_en"].strip())
    if (entry.get("palette_text") or "").strip():
        lines.append("SONIC PALETTE: " + entry["palette_text"].strip())
    lines.append("FORMAT: " + audio["format"].strip())
    lines.append("DURATION: about %s s (accepted range %s to %s s)." % (
        fmt_seconds(entry["duration_s"]), fmt_seconds(entry["duration_s"] * 0.9), fmt_seconds(entry["duration_s"] * 1.1)))
    lines.append(loop_phrase(entry["loop"], os.path.splitext(entry["path"])[1]))
    lines.append("LOUDNESS: " + audio["loudness"].strip())
    lines.append("MOOD: " + audio["mood_en"].strip())
    lines.append("MATERIALS: " + audio["materials_en"].strip())
    lines.append("REFERENCES: " + audio["references_en"].strip())
    if entry.get("take_count"):
        lines.append("VARIATION: take %d of %d - same event and same object as the other takes, slightly different "
                     "performance (see the take note in THIS FILE)." % (entry["take"], entry["take_count"]))
    lines.append("AVOID: " + join_avoid(audio_avoid_text(style, group), group.get("avoid_en")))
    return "\n".join(lines)


def compose_font_prompt(group, entry):
    lines = ["FONT FILE (the owner sources this file; nothing is drawn or generated): " + entry["title_vi"],
             "",
             "SUBJECT: " + group["subject_en"].strip(),
             "THIS FILE: " + entry["what_en"].strip()]
    if group.get("details_en", "").strip():
        lines.append("DETAILS: " + group["details_en"].strip())
    lines.append("FILE: save the font at exactly " + entry["path"])
    lines.append("PALETTE: " + ((entry.get("palette_text") or "").strip() or "n/a"))
    lines.append("DO NOT: " + ((group.get("avoid_en") or "").strip() or "use a font whose licence is not OFL or CC0 without the owner's approval."))
    return "\n".join(lines)


def compose_sourcing_prompt(group, entry):
    pack = group["sourcing"]
    lines = ["SOURCED FILE (nothing is drawn or generated; the owner copies and renames one file out of a CC0 pack): " + entry["title_vi"],
             "",
             "SUBJECT: " + group["subject_en"].strip(),
             "THIS FILE: " + entry["what_en"].strip()]
    if group.get("details_en", "").strip():
        lines.append("DETAILS: " + group["details_en"].strip())
    lines.append("PACK: %s by %s, %s, licence %s (%s). %s" % (pack["pack"], pack["author"], pack["url"], pack["licence"],
                                                              pack["licence_url"], pack["download_en"].strip()))
    lines.append("SOURCE FILE IN THE PACK: " + entry["source"].strip())
    lines.append("COVERAGE: " + SOURCING_COVERAGE_EN[entry["coverage"]])
    lines.append("COPY AND RENAME TO: " + entry["path"])
    lines.append("CANVAS: the pack tile is exactly %dx%d pixels with a transparent background, 1 art pixel = 1 game pixel; do not resize, recolour or smooth it." % tuple(group["size"]))
    lines.append("LATER: " + pack["later_en"].strip())
    lines.append("DO NOT: " + ((group.get("avoid_en") or "").strip() or "edit the Kenney tile beyond what COVERAGE says."))
    return "\n".join(lines)


SOURCING_COVERAGE = ("tile", "locate", "compose")
SOURCING_COVERAGE_EN = {
    "tile": "the exact tile is named above (its number comes from a community rename listing of the pack's Tiles folder, and on 2026-10-13 every number was re-read against the file name that listing gives it: the name is this key or button; the pack's own pictures were not opened); open the tile next to the pack's preview to confirm the picture before copying.",
    "locate": "the pack should contain this glyph but its tile number is not confirmed: find it on the pack's tilesheet or preview image (the candidate tiles are named above), then copy that tile; if you cannot find it, treat the file like a compose one.",
    "compose": "the pack has no ready-made tile for this glyph: do what the line above says (a stand-in tile or a quick edit), or leave the file out and let the game draw the name in the pixel font; a hand-drawn file at this path replaces it later.",
}


# --------------------------------------------------------------------------- acceptance text (Vietnamese)

TRANSLUCENT_HINT = re.compile(r"alpha|translucent|semi-transparent|semi transparent", re.I)
# A percentage is OPACITY unless the text names what it measures (style block: PERCENTAGES AND TRANSLUCENCY).
# These words after the number mean a size or a progress, so they do not switch the translucency allowance on.
OPACITY_PERCENT = re.compile(
    r"\d\s?(?:%|percent)(?!\s*(?:of\b|height|width|size|scale|progress|tall|wide|long|radius))", re.I)


def uses_translucency(text):
    return bool(TRANSLUCENT_HINT.search(text) or OPACITY_PERCENT.search(text))


def image_acceptance(group, entry):
    width, height = group["size"]
    bits = ["PNG RGBA 8-bit đúng %dx%d px" % (width, height)]
    if entry["opaque"]:
        extra = ""
        if "except where this description says" in group.get("details_en", ""):
            extra = " (trừ lỗ mà mô tả nêu rõ)"
        bits.append("mọi pixel alpha = 255%s, tile đặc, vẽ kín cạnh tới cạnh" % extra)
    else:
        text = " ".join([group.get("details_en", ""), group.get("subject_en", ""), entry.get("what_en") or "",
                         entry.get("pose") or ""])
        if uses_translucency(text):
            bits.append("nền trong suốt; alpha trung gian chỉ ở vùng tô mờ mà mô tả nêu rõ (phần trăm = độ đục; mỗi phần tử một giá trị "
                        "alpha = % x 255, tô phẳng), viền ngoài vẫn cứng")
        else:
            bits.append("có kênh alpha, nền trong suốt, alpha chỉ 0 hoặc 255 (không viền mờ)")
    bits.append("pixel 1x1 thật (một pixel vẽ = một pixel game), không phóng to, không nội suy, không có khối pixel lớn hơn")
    bits.append("tối đa %d màu khác nhau (cảnh báo, không chặn)" % colour_limit(group))
    anchor = (group.get("anchor") or "none").strip()
    if anchor.lower().startswith("none"):
        bits.append("không có điểm neo")
    else:
        bits.append("điểm neo: %s" % anchor)
    if entry["is_frame"]:
        bits.append("khung %d/%d của clip '%s': cùng canvas, cùng điểm neo (lệch ngang không quá 3 px), cùng bảng màu "
                    "với các khung khác của clip" % (entry["frame"], entry["frames"], entry["clip"]))
        if entry["frame"] == 1:
            bits.append("khung 01 cũng là ảnh tĩnh cho chế độ giảm chuyển động")
    return "; ".join(bits) + "."


def audio_acceptance(group, entry):
    audio = group["audio"]
    channels = "stereo" if "stereo" in audio["format"].lower() else "mono"
    peak_match = re.search(r"peak\s*(-?\d+(?:\.\d+)?)\s*dBFS", audio.get("loudness", ""))
    peak = peak_match.group(1) if peak_match else "-1"
    duration = entry["duration_s"]
    is_ogg = entry["path"].endswith(".ogg")
    if is_ogg:
        bits = ["OGG Vorbis 44.1 kHz %s (chất lượng khoảng 6, tức khoảng 192 kbps VBR; một bản phối hoàn chỉnh, không tách stem)" % channels]
    else:
        bits = ["WAV PCM 44.1 kHz 16-bit %s" % channels]
    bits += ["thời lượng %s s ±10%% (từ %s đến %s s)" % (fmt_seconds(duration), fmt_seconds(duration * 0.9), fmt_seconds(duration * 1.1)),
             "đỉnh ≤ %s dBFS%s, không clip, không click ở đầu và cuối" % (peak, " (đo sau khi mã hoá)" if is_ogg else "")]
    if entry["loop"] and is_ogg:
        bits.append("lặp liền mạch: mẫu đầu và cuối liên tục (không click, không fade ở điểm lặp), KHÔNG nhúng thẻ loop; game bật cờ lặp khi nhập file")
    elif entry["loop"]:
        bits.append("lặp liền mạch: có smpl loop chunk phủ cả file, mẫu đầu và cuối liên tục (không click, không fade ở điểm lặp)")
    else:
        bits.append("không lặp, đuôi tự nhiên ngắn")
    return "; ".join(bits) + "."


def sourcing_acceptance(group, entry):
    pack = group["sourcing"]
    coverage_vi = {
        "tile": "tile đã xác định số: chép đúng tile đó, mở cạnh ảnh xem trước của bộ để chắc đúng hình",
        "locate": "bộ có glyph này nhưng chưa xác nhận số tile: tìm trên tilesheet hoặc ảnh xem trước của bộ rồi chép tile đó",
        "compose": "bộ không có tile sẵn: làm theo hướng dẫn trong prompt (tile thay thế hoặc sửa nhanh), hoặc bỏ trống và để game vẽ tên phím bằng font pixel",
    }[entry["coverage"]]
    return ("PNG đúng %dx%d px, nền trong suốt, giữ nguyên pixel của bộ (không đổi cỡ, không đổi màu); đường dẫn đúng như mục File; %s; "
            "giấy phép %s, ghi bộ '%s' của %s vào THIRD_PARTY_NOTICES.md; có thể ghi đè bằng file vẽ tay cùng đường dẫn bất cứ lúc nào." % (
                group["size"][0], group["size"][1], coverage_vi, pack["licence"], pack["pack"], pack["author"]))


def font_acceptance():
    return ("file .ttf hoặc .otf hợp lệ, đặt đúng đường dẫn; giấy phép OFL hoặc CC0 và ghi vào THIRD_PARTY_NOTICES.md; "
            "chạy `python3 tools/asset_requests/build_requests.py --check-font <đường dẫn font>` (tự động đọc bảng cmap như "
            "FontFile.has_char, phải in PASS với đủ bộ ký tự tiếng Việt kể cả dấu chồng ệ, ẫ, ờ, ữ, ặ) rồi mới chốt; "
            "độ cao dòng và khoảng trống cho dấu ở cỡ chữ thật vẫn do anh nhìn bằng mắt.")


# --------------------------------------------------------------------------- font coverage (Vietnamese)

# The Google Fonts subset tag only says a subset is declared. This check reads the font's own cmap table (the table
# FontFile.has_char consults) and lists every Vietnamese code point the font lacks.
VIETNAMESE_BASES = "aăâeêioôơuưy"
VIETNAMESE_TONES = (0x0300, 0x0301, 0x0309, 0x0303, 0x0323)  # grave, acute, hook above, tilde, dot below
FONT_RECOMMENDED_PUNCTUATION = "‘’“”–—…•"
FONT_RECOMMENDED_COMBINING = tuple(VIETNAMESE_TONES)  # decomposed (NFD) input from a .po file
HUD_FONT_STEMS = ("ui_small_pixel",)  # digits-only HUD font: it only needs numerals and a few signs
HUD_FONT_CHARS = "0123456789.:%/+-x "


def vietnamese_letters():
    """The 134 non-ASCII precomposed letters of Vietnamese (67 lower case + 67 upper case), as characters."""
    letters = set()
    for base in VIETNAMESE_BASES + VIETNAMESE_BASES.upper():
        for tone in (None,) + VIETNAMESE_TONES:
            composed = unicodedata.normalize("NFC", base if tone is None else base + chr(tone))
            if len(composed) == 1 and ord(composed) > 127:
                letters.add(composed)
    letters.update("đĐ")
    return letters


def required_font_characters(stem):
    """Characters a font must have: (required, recommended)."""
    if stem in HUD_FONT_STEMS:
        return set(HUD_FONT_CHARS), set()
    ascii_part = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,:;!?'\"()-/%+*=<>&")
    required = ascii_part | vietnamese_letters()
    recommended = set(FONT_RECOMMENDED_PUNCTUATION) | {chr(c) for c in FONT_RECOMMENDED_COMBINING}
    return required, recommended


class FontReadError(Exception):
    pass


def _u16(data, offset):
    return struct.unpack_from(">H", data, offset)[0]


def _i16(data, offset):
    return struct.unpack_from(">h", data, offset)[0]


def _u32(data, offset):
    return struct.unpack_from(">I", data, offset)[0]


def font_cmap_subtables(data):
    """Return [(platform, encoding, absolute offset)] of the Unicode cmap subtables of an sfnt font."""
    head = data[:4]
    if head in (b"wOFF", b"wOF2"):
        raise FontReadError("WOFF/WOFF2 container: check the original .ttf or .otf instead")
    base = 0
    if head == b"ttcf":
        base = _u32(data, 12)  # first font of the collection
        head = data[base:base + 4]
    if head not in (b"\x00\x01\x00\x00", b"OTTO", b"true", b"typ1"):
        raise FontReadError("not a TrueType/OpenType font (unknown header %r)" % head)
    table_count = _u16(data, base + 4)
    cmap_offset = None
    for index in range(table_count):
        record = base + 12 + 16 * index
        if data[record:record + 4] == b"cmap":
            cmap_offset = _u32(data, record + 8)
            break
    if cmap_offset is None:
        raise FontReadError("the font has no cmap table")
    count = _u16(data, cmap_offset + 2)
    found = []
    for index in range(count):
        record = cmap_offset + 4 + 8 * index
        platform, encoding, offset = _u16(data, record), _u16(data, record + 2), _u32(data, record + 4)
        if platform == 0 or (platform == 3 and encoding in (1, 10)):
            found.append((platform, encoding, cmap_offset + offset))
    if not found:
        raise FontReadError("the font has no Unicode cmap subtable")
    return found


def cmap_has_codepoint(data, subtable_offset, codepoint):
    fmt = _u16(data, subtable_offset)
    if fmt == 4:
        if codepoint > 0xFFFF:
            return False
        seg_count = _u16(data, subtable_offset + 6) // 2
        ends = subtable_offset + 14
        starts = ends + 2 * seg_count + 2
        deltas = starts + 2 * seg_count
        range_offsets = deltas + 2 * seg_count
        for seg in range(seg_count):
            end = _u16(data, ends + 2 * seg)
            if codepoint > end:
                continue
            start = _u16(data, starts + 2 * seg)
            if codepoint < start:
                return False
            delta = _i16(data, deltas + 2 * seg)
            range_offset = _u16(data, range_offsets + 2 * seg)
            if range_offset == 0:
                return ((codepoint + delta) & 0xFFFF) != 0
            glyph_address = range_offsets + 2 * seg + range_offset + 2 * (codepoint - start)
            glyph = _u16(data, glyph_address)
            return glyph != 0 and ((glyph + delta) & 0xFFFF) != 0
        return False
    if fmt == 12:
        groups = _u32(data, subtable_offset + 12)
        for group in range(groups):
            record = subtable_offset + 16 + 12 * group
            start, end, glyph = _u32(data, record), _u32(data, record + 4), _u32(data, record + 8)
            if start <= codepoint <= end:
                return glyph + (codepoint - start) != 0
        return False
    if fmt == 6:
        first, count = _u16(data, subtable_offset + 6), _u16(data, subtable_offset + 8)
        if first <= codepoint < first + count:
            return _u16(data, subtable_offset + 10 + 2 * (codepoint - first)) != 0
        return False
    return False  # formats 0, 2, 13, 14 never carry the Vietnamese range of a usable UI font


def check_font_file(path):
    """Return (missing required chars, missing recommended chars). Raises FontReadError / OSError."""
    path = Path(path)
    if path.suffix.lower() not in FONT_EXT:
        raise FontReadError("expected a .ttf or .otf file")
    with open(path, "rb") as handle:
        data = handle.read()
    try:
        subtables = font_cmap_subtables(data)
        required, recommended = required_font_characters(path.stem)

        def covered(ch):
            return any(cmap_has_codepoint(data, offset, ord(ch)) for _, _, offset in subtables)

        return sorted(c for c in required if not covered(c)), sorted(c for c in recommended if not covered(c))
    except struct.error:
        raise FontReadError("truncated or corrupt font file")


def format_codepoints(chars, limit=40):
    shown = ["U+%04X %s" % (ord(c), c if c.isprintable() and not unicodedata.combining(c) else "(mark)") for c in chars[:limit]]
    more = "" if len(chars) <= limit else " ... and %d more" % (len(chars) - limit)
    return ", ".join(shown) + more


def run_font_check(paths, out=sys.stdout):
    """Print a PASS/FAIL line per font; return 0 when every font covers the required characters."""
    failed = 0
    for path in paths:
        try:
            missing, soft = check_font_file(path)
        except (FontReadError, OSError) as exc:
            print("FAIL %s: %s" % (path, exc), file=out)
            failed += 1
            continue
        stem = Path(path).stem
        what = "digits and HUD signs" if stem in HUD_FONT_STEMS else "the full Vietnamese set (134 precomposed letters + ASCII)"
        if missing:
            failed += 1
            print("FAIL %s: missing %d of %s: %s" % (path, len(missing), what, format_codepoints(missing)), file=out)
        else:
            print("PASS %s: covers %s" % (path, what), file=out)
        if soft:
            print("  note: also lacks recommended characters: %s" % format_codepoints(soft), file=out)
    if paths:
        print("Still an owner step: render the line height and the diacritic clearance at the real sizes (no script can judge that).", file=out)
    return 1 if failed else 0


def owner_font_paths(root):
    """Fonts of the fonts_ui group that already exist under the repo root (missing ones are simply not delivered yet)."""
    folder = Path(root) / "assets" / "fonts"
    names = ("ui_body_pixel.ttf", "ui_small_pixel.ttf", "ui_title_pixel.ttf", "child_hand.ttf")
    return [folder / name for name in names if (folder / name).is_file()]


# --------------------------------------------------------------------------- entries

def build_entries(style, specs, problems):
    """Expand every group into per-file entries. Returns (groups, entries) in spec order."""
    scale_table = style.get("scale_table", [])
    palettes = palette_index(specs)
    groups = []
    entries = []
    # Every still image path in the spec, so a clip can point at <folder>/body.png even when
    # that file belongs to a sibling group of the same folder (the hero bodies and hero clips).
    still_image_paths = set()
    for category in CATEGORIES:
        for group in specs.get(category, []):
            if group.get("kind") in IMAGE_KINDS:
                for item in group.get("files") or []:
                    if isinstance(item, dict) and item.get("name"):
                        still_image_paths.add("%s/%s" % ((group.get("folder") or "").strip().strip("/"), item["name"]))
    for category in CATEGORIES:
        seen_group_ids = set()
        for group in specs.get(category, []):
            gid = group.get("group_id", "?")
            where = "%s/%s" % (category, gid)
            if not GROUP_ID_RE.match(gid):
                problems.error("%s: group_id must match [a-z0-9_]+" % where)
            if gid in seen_group_ids:
                problems.error("%s: duplicate group_id in category" % where)
            seen_group_ids.add(gid)
            for required in ("title_vi", "kind", "folder", "needed_by", "priority", "subject_en"):
                if not group.get(required):
                    problems.error("%s: missing %r" % (where, required))
            kind = group.get("kind")
            folder = (group.get("folder") or "").strip().strip("/")
            media = ("image" if kind in IMAGE_KINDS else "audio" if kind in AUDIO_KINDS else "font" if kind in FONT_KINDS
                     else "sourcing" if kind in SOURCING_KINDS else None)
            if media is None:
                problems.error("%s: unknown kind %r" % (where, kind))
                continue
            if group.get("priority") not in PRIORITIES:
                problems.error("%s: bad priority %r" % (where, group.get("priority")))
            if not MILESTONE_RE.match(group.get("needed_by") or ""):
                problems.error("%s: bad needed_by %r" % (where, group.get("needed_by")))
            block_px = 0
            if media == "sourcing":
                pack = group.get("sourcing")
                if not isinstance(pack, dict):
                    problems.error("%s: sourcing group has no 'sourcing' block" % where)
                    continue
                for required in ("pack", "author", "url", "licence", "licence_url", "download_en", "later_en"):
                    if not pack.get(required):
                        problems.error("%s: sourcing block missing %r" % (where, required))
                if not str(pack.get("url", "")).startswith("https://"):
                    problems.error("%s: sourcing url must be an https address" % where)
            if media in ("image", "sourcing"):
                size = group.get("size")
                if not (isinstance(size, list) and len(size) == 2 and all(isinstance(v, int) and v > 0 for v in size)):
                    problems.error("%s: image group has no valid size (%r)" % (where, size))
                    continue
                block_px = resolve_block_px(group, scale_table)
            if media == "audio":
                audio = group.get("audio")
                if not isinstance(audio, dict):
                    problems.error("%s: audio group has no 'audio' block" % where)
                    continue
                for required in ("format", "loudness", "mood_en", "materials_en", "references_en"):
                    if not audio.get(required):
                        problems.error("%s: audio block missing %r" % (where, required))
                if not group.get("files"):
                    problems.error("%s: audio group has no files" % where)

            if media == "image":
                for label, profile in [("group", group.get("avoid_profile"))] + [
                        ("file " + str(item.get("name")), item.get("avoid_profile")) for item in (group.get("files") or [])]:
                    if profile and profile not in style.get("global_avoid_variants_en", {}):
                        problems.error("%s: %s has unknown avoid_profile %r (style.json has %s)" % (
                            where, label, profile, sorted(style.get("global_avoid_variants_en", {}))))
            elif media == "audio":
                profile = group.get("avoid_profile")
                if profile and profile not in style.get("global_avoid_audio_variants_en", {}):
                    problems.error("%s: unknown audio avoid_profile %r (style.json has %s)" % (
                        where, profile, sorted(style.get("global_avoid_audio_variants_en", {}))))

            group_file = "requests/%s/%s.md" % (category, gid)
            group_palette = resolve_palette(group.get("palette_en"), palettes, where, problems)
            file_list = group.get("files") or []
            clip_list = group.get("clips") or []
            if not file_list and not clip_list:
                problems.error("%s: group has neither files nor clips" % where)

            # Reference image for "same character as ..." in animation frames.
            reference_path = None
            reference_tile_data = None
            explicit_reference = (group.get("reference_image") or "").strip()
            if explicit_reference:
                if media != "image" or not clip_list:
                    problems.error("%s: reference_image only makes sense on an image group with clips" % where)
                elif explicit_reference not in still_image_paths:
                    problems.error("%s: reference_image %r is not a still image of any group" % (where, explicit_reference))
                else:
                    reference_path = explicit_reference
            if media == "image" and clip_list and reference_path is None:
                # Same character as <folder>/body.png when that file exists (in this or a sibling group),
                # else this group's first still, else the first frame of the first clip.
                chosen = None
                for item in file_list:
                    if item.get("name") == "body.png":
                        chosen = item
                        break
                if chosen is None and "%s/body.png" % folder in still_image_paths:
                    reference_path = "%s/body.png" % folder
                elif chosen is None and file_list:
                    chosen = file_list[0]
                if chosen is not None:
                    reference_path = "%s/%s" % (folder, chosen["name"])
                    reference_tile_data = chosen.get("tile_data")
                elif reference_path is None:
                    reference_path = "%s/anim/%s/01.png" % (folder, clip_list[0].get("clip"))

            group_info = {
                "category": category, "group_id": gid, "title_vi": group.get("title_vi", ""),
                "notes_vi": group.get("notes_vi", ""), "used_in": group.get("used_in", ""),
                "reference_files": list(group.get("reference_files") or []),
                "placeholder_now": group.get("placeholder_now") or "none", "kind": kind, "media": media,
                "folder": folder, "size": group.get("size") if media in ("image", "sourcing") else None,
                "anchor": group.get("anchor") if media in ("image", "sourcing") else None, "block_px": block_px,
                "group_file": group_file, "entry_ids": [],
            }
            groups.append(group_info)

            def new_entry(**fields):
                base = {
                    "category": category, "group_id": gid, "group_title_vi": group.get("title_vi", ""),
                    "kind": kind, "media": media, "folder": folder, "group_file": group_file,
                    "used_in": group.get("used_in", ""), "notes_vi": group.get("notes_vi", ""),
                    "reference_files": list(group.get("reference_files") or []),
                    "size": list(group["size"]) if media in ("image", "sourcing") else None,
                    "anchor": group.get("anchor") if media in ("image", "sourcing") else None,
                    "block_px": block_px if media in ("image", "sourcing") else None,
                    "source": None, "coverage": None,
                    "tile_data": None, "is_frame": False, "clip": None, "frame": None, "frames": None,
                    "loop": None, "fps": None, "pose": None, "what_en": None, "take": None, "take_count": None,
                    "event_id": None, "duration_s": None, "audio": None,
                    "opaque": False, "avoid_profile": "", "palette_text": group_palette,
                }
                base.update(fields)
                return base

            # ---- still files (and audio files, fonts)
            for item in file_list:
                name = item.get("name")
                if not name or not isinstance(name, str):
                    problems.error("%s: a file has no name" % where)
                    continue
                if name.startswith("/") or ".." in name.split("/"):
                    problems.error("%s: unsafe file name %r" % (where, name))
                path = "%s/%s" % (folder, name)
                priority = item.get("priority") or group.get("priority")
                needed_by = item.get("needed_by") or group.get("needed_by")
                if not item.get("what_en"):
                    problems.error("%s: file %s has no what_en" % (where, name))
                entry = new_entry(
                    id=("%s-%s-%s" % (category, gid, stem_of(name))).upper(),
                    title_vi=item.get("title_vi") or stem_of(name), path=path, name=name,
                    needed_by=needed_by, priority=priority, what_en=item.get("what_en", ""),
                    placeholder=item.get("placeholder_now") or group.get("placeholder_now") or "none",
                )
                if item.get("palette_en"):
                    entry["palette_text"] = resolve_palette(item["palette_en"], palettes, "%s file %s" % (where, name), problems)
                if media == "image":
                    entry["tile_data"] = item.get("tile_data")
                    entry["opaque"] = is_opaque(group, item)
                    entry["avoid_profile"] = image_avoid_profile(group, item)
                    if kind == "tile" and not item.get("tile_data"):
                        problems.error("%s: tile file %s has no tile_data" % (where, name))
                    entry["prompt"] = compose_image_prompt(style, group, entry, reference_path, False)
                    entry["acceptance"] = image_acceptance(group, entry)
                elif media == "audio":
                    audio = group["audio"]
                    duration = item.get("duration_s", audio.get("duration_s"))
                    if not isinstance(duration, (int, float)) or isinstance(duration, bool) or duration <= 0:
                        problems.error("%s: file %s has no valid duration_s" % (where, name))
                        continue
                    loop = item.get("loop", audio.get("loop", False))
                    take, take_count = item.get("take"), item.get("take_count")
                    if take_count and not (isinstance(take, int) and 1 <= take <= take_count):
                        problems.error("%s: file %s has take %r outside 1..%r" % (where, name, take, take_count))
                    entry.update(duration_s=float(duration), loop=bool(loop), take=take, take_count=take_count,
                                 event_id=item.get("event_id"), audio=dict(audio),
                                 avoid_profile=group.get("avoid_profile") or "")
                    entry["prompt"] = compose_audio_prompt(style, group, entry)
                    entry["acceptance"] = audio_acceptance(group, entry)
                elif media == "sourcing":
                    source, coverage = item.get("source"), item.get("coverage")
                    if not (isinstance(source, str) and source.strip()):
                        problems.error("%s: sourcing file %s has no 'source' (where to find it in the pack)" % (where, name))
                    if coverage not in SOURCING_COVERAGE:
                        problems.error("%s: sourcing file %s has coverage %r (use one of %s)" % (where, name, coverage, SOURCING_COVERAGE))
                        continue
                    entry.update(source=source or "", coverage=coverage, sourcing=dict(group["sourcing"]))
                    entry["prompt"] = compose_sourcing_prompt(group, entry)
                    entry["acceptance"] = sourcing_acceptance(group, entry)
                else:
                    entry["prompt"] = compose_font_prompt(group, entry)
                    entry["acceptance"] = font_acceptance()
                entries.append(entry)
                group_info["entry_ids"].append(entry["id"])

            # ---- animation frames
            seen_clips = set()
            for clip in clip_list:
                clip_name = clip.get("clip")
                cwhere = "%s clip %s" % (where, clip_name)
                if media != "image":
                    problems.error("%s: only image groups may have clips" % cwhere)
                    break
                if not clip_name or not re.fullmatch(r"[A-Za-z0-9_]+", clip_name):
                    problems.error("%s: bad clip name" % cwhere)
                    continue
                if clip_name in seen_clips:
                    problems.error("%s: duplicate clip name" % cwhere)
                seen_clips.add(clip_name)
                frames = clip.get("frames")
                poses = clip.get("poses_en")
                if not (isinstance(frames, int) and not isinstance(frames, bool) and frames >= 1):
                    problems.error("%s: 'frames' must be a positive integer, got %r" % (cwhere, frames))
                    continue
                if not isinstance(poses, list) or len(poses) != frames:
                    problems.error("%s: has %s poses but frames = %d" % (cwhere, len(poses) if isinstance(poses, list) else "no", frames))
                    continue
                if not all(isinstance(p, str) and p.strip() for p in poses):
                    problems.error("%s: a pose is empty" % cwhere)
                    continue
                fps = clip.get("fps")
                if not (isinstance(fps, int) and fps > 0):
                    problems.error("%s: bad fps %r" % (cwhere, fps))
                    continue
                priority = clip.get("priority") or group.get("priority")
                needed_by = clip.get("needed_by") or group.get("needed_by")
                for number in range(1, frames + 1):
                    first_of_group = (("%s/anim/%s/%02d.png" % (folder, clip_name, number)) == reference_path)
                    entry = new_entry(
                        id=("%s-%s-%s-%02d" % (category, gid, clip_name, number)).upper(),
                        title_vi="%s: clip %s, khung %d/%d" % (group.get("title_vi", gid), clip_name, number, frames),
                        path="%s/anim/%s/%02d.png" % (folder, clip_name, number),
                        name="anim/%s/%02d.png" % (clip_name, number), needed_by=needed_by, priority=priority,
                        is_frame=True, clip=clip_name, frame=number, frames=frames, loop=bool(clip.get("loop")),
                        fps=fps, pose=poses[number - 1], tile_data=reference_tile_data,
                        placeholder=group.get("placeholder_now") or "none",
                        opaque=is_opaque(group), avoid_profile=image_avoid_profile(group, None),
                    )
                    entry["prompt"] = compose_image_prompt(style, group, entry, reference_path, first_of_group)
                    entry["acceptance"] = image_acceptance(group, entry)
                    entries.append(entry)
                    group_info["entry_ids"].append(entry["id"])
    return groups, entries


# --------------------------------------------------------------------------- validation

def validate(style, groups, entries, gitignore_rules, problems):
    seen_paths = {}
    seen_paths_ci = {}
    seen_ids = {}
    style_block = style["style_block_en"]
    sound_brief = style["sound_brief_en"]
    for entry in entries:
        eid, path = entry["id"], entry["path"]
        if eid in seen_ids:
            problems.error("duplicate entry id %s (paths %s and %s)" % (eid, seen_ids[eid], path))
        seen_ids[eid] = path
        if path in seen_paths:
            problems.error("duplicate path %s (ids %s and %s)" % (path, seen_paths[path], eid))
        seen_paths[path] = eid
        lowered = path.lower()
        if lowered in seen_paths_ci and seen_paths_ci[lowered] != path:
            problems.error("paths differ only by case (breaks on macOS/Windows): %s and %s" % (seen_paths_ci[lowered], path))
        seen_paths_ci[lowered] = path
        if path.startswith("/") or ".." in path.split("/") or "\\" in path or " " in path:
            problems.error("%s: unsafe or non-portable path %r" % (eid, path))
        if not re.fullmatch(r"[A-Za-z0-9_./-]+", path):
            problems.error("%s: path has characters outside [A-Za-z0-9_./-]: %r" % (eid, path))
        if gitignore_rules is not None:
            hit = gitignored_by(gitignore_rules, path)
            if hit:
                problems.error("%s: path %s lies under a gitignored folder (.gitignore line: %s)" % (eid, path, hit))
        prompt = entry.get("prompt") or ""
        if not prompt.strip():
            problems.error("%s: empty prompt" % eid)
        if not MILESTONE_RE.match(entry.get("needed_by") or ""):
            problems.error("%s: bad needed_by %r" % (eid, entry.get("needed_by")))
        if entry.get("priority") not in PRIORITIES:
            problems.error("%s: bad priority %r" % (eid, entry.get("priority")))
        media = entry["media"]
        if media == "image":
            if not path.endswith(IMAGE_EXT):
                problems.error("%s: image path must end in .png: %s" % (eid, path))
            size = entry.get("size")
            if not (isinstance(size, list) and len(size) == 2 and all(isinstance(v, int) and v > 0 for v in size)):
                problems.error("%s: image entry has no size" % eid)
            if style_block not in prompt:
                problems.error("%s: prompt does not contain the style block" % eid)
            for label in ("SUBJECT:", "CANVAS:", "ANCHOR:", "PALETTE:", "DO NOT:"):
                if label not in prompt:
                    problems.error("%s: prompt lacks %s" % (eid, label))
            if entry["kind"] == "tile" and "TILE DATA:" not in prompt:
                problems.error("%s: tile prompt lacks the TILE DATA line" % eid)
            if entry["is_frame"] and "frame %d of %d of the %s animation" % (entry["frame"], entry["frames"], entry["clip"]) not in prompt:
                problems.error("%s: frame prompt lacks its frame statement" % eid)
        elif media == "sourcing":
            if not path.endswith(IMAGE_EXT):
                problems.error("%s: sourced glyph path must end in .png: %s" % (eid, path))
            if "SOURCED FILE" not in prompt or "SOURCE FILE IN THE PACK:" not in prompt or "COPY AND RENAME TO: " + path not in prompt:
                problems.error("%s: sourcing prompt lacks its header, source or target line" % eid)
        elif media == "audio":
            allowed = AUDIO_EXT_BY_KIND.get(entry["kind"], AUDIO_EXT)
            if not path.endswith(allowed):
                problems.error("%s: %s path must end in %s: %s" % (eid, entry["kind"], " or ".join(allowed), path))
            if sound_brief not in prompt:
                problems.error("%s: prompt does not contain the sound brief" % eid)
            for label in ("SOUND:", "FORMAT:", "DURATION:", "LOOP:", "LOUDNESS:", "MOOD:", "MATERIALS:", "REFERENCES:", "AVOID:"):
                if label not in prompt:
                    problems.error("%s: prompt lacks %s" % (eid, label))
            if entry.get("take_count") and "VARIATION: take %d of %d" % (entry["take"], entry["take_count"]) not in prompt:
                problems.error("%s: prompt lacks its variation line" % eid)
        else:
            if not path.endswith(FONT_EXT):
                problems.error("%s: font path must end in .ttf or .otf: %s" % (eid, path))
            if "FONT FILE" not in prompt:
                problems.error("%s: font prompt lacks its FONT FILE header" % eid)
        if media not in ("font", "sourcing"):
            dead = DEAD_REF_RE.search(prompt)
            if dead:
                lo = max(0, dead.start() - 50)
                problems.error("%s: prompt cites a document or id a generator cannot open (%r in ...%s...); write the rule inline" % (
                    eid, dead.group(0), prompt[lo:dead.end() + 30].replace("\n", " ")))
        if "{palette:" in prompt or "{" in "".join(line for line in prompt.splitlines() if line.startswith(("PALETTE:", "SONIC PALETTE:"))):
            problems.error("%s: the PALETTE line has an unresolved token" % eid)
        if "```" in prompt:
            problems.warn("%s: prompt contains a code fence; a longer fence is used when rendering" % eid)
        if re.search(r"\{[a-z_]+\}|\bNone\b|\bnull\b", "\n".join(
                line for line in prompt.splitlines() if line.startswith(("CANVAS:", "ANCHOR:", "TILE DATA:", "FORMAT:", "DURATION:", "LOOP:", "VARIATION:")))):
            problems.error("%s: prompt has an unresolved template value" % eid)
    # Each group must have produced its entries and every group file must be unique.
    group_files = Counter(g["group_file"] for g in groups)
    for gfile, count in group_files.items():
        if count > 1:
            problems.error("group file collision: %s" % gfile)


# --------------------------------------------------------------------------- spec lint (content rules)

HEX_RE = re.compile(r"#[0-9A-Fa-f]{6}\b")
# A prompt is read by a generator that cannot open the repository, so it never cites a document, a section or a plan id:
# "plan 10", "fx1", "pixel-art bible 7", "gdd", "docs/...", "section 6.10", requirement ids R<n> (R3 alone is the gamepad stick
# click), decision ids D-<nn> and story-beat ids S<nn> are dead links there. State the rule inline instead.
DEAD_REF_RE = re.compile(
    r"\bplan\s*§?\s*\d|\bpixel-art\s+bible\b|\b(?:fx|gp|au|an|ui|ld|art|nar)\d+\b|\bgdd\b|\bdocs/|\b\w+\.md\b"
    r"|\bsection\s+\d|§|\bR(?!3\b)\d{1,2}\b|\bD-\d{2}\b|\bS\d{2}\b|\breq#\d|\bAN\d\b", re.I)
# Loose piles of identical things are not one object (one file = one thing). A compound that IS one object (a rubble heap, a
# stack, a litter decal, a barricade) says so with "compound_ok": "<reason>" on the file.
CLUSTER_NAME_RE = re.compile(r"(^|[_/])(pile|heap|scatter|scattered|cluster|spilled|handful|bunch)([_/.]|$)")
CLUSTER_TEXT_RE = re.compile(r"^(?:An? |The )?(?:(?:small|little|big|loose|tiny|large)\s+)?(?:pile|heap|scatter|cluster|handful|bunch)\b", re.I)
TRANSLUCENCY_HEADING = "PERCENTAGES AND TRANSLUCENCY"
STANDARD_BLIP_EVENTS = ("blip", "blip_question", "blip_end")
NUMBER_WORD = {1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight"}
COMPOSITE_NAME_RE = re.compile(r"(^|[_/])(pair|pairs|both|couple|duo|trio)([_/.]|$)")
BIG_IMAGE_AREA = 128 * 96  # one object per file and nothing too big: the child's hand (192x144) is the only exception
BIG_IMAGE_ALLOWED = ("title_logo", "app_icon")  # one logo and the OS application icon are single objects that need their size


def lint_specs(style, specs, problems):
    """Content rules that the owner asked for and that the per-entry validation cannot see."""
    palettes = palette_index(specs)
    if TRANSLUCENCY_HEADING not in style["style_block_en"]:
        problems.error("style.json: the style block lost its %r paragraph (how a written percentage and a translucent fill are read)" % TRANSLUCENCY_HEADING)
    if TRANSLUCENCY_HEADING not in style["global_avoid_en"]:
        problems.error("style.json: global_avoid_en must point at the %r paragraph, otherwise the alpha rule and the percentages contradict" % TRANSLUCENCY_HEADING)
    for name, text in (style.get("global_avoid_variants_en") or {}).items():
        if TRANSLUCENCY_HEADING not in text:
            problems.error("style.json: the %r DO NOT variant must point at the %r paragraph too" % (name, TRANSLUCENCY_HEADING))
    # A DO NOT variant must stay as strict as the default on everything but the one clause it relaxes.
    for name, text in (style.get("global_avoid_variants_en") or {}).items():
        for must_keep in ("text, letters, numerals or watermark", "crayon blue anywhere except where the child made it",
                          "coral red anywhere except imminent damage", "pure white or pure black fills"):
            if must_keep not in text:
                problems.error("style.json: the %r DO NOT variant lost the clause %r" % (name, must_keep))
    for name, text in (style.get("global_avoid_audio_variants_en") or {}).items():
        for must_keep in ("generic fantasy combat", "gunshots", "clipping"):
            if must_keep not in text:
                problems.error("style.json: the %r audio avoid variant lost the clause %r" % (name, must_keep))
    for category, groups in specs.items():
        for group in groups:
            where = "%s/%s" % (category, group.get("group_id", "?"))
            kind = group.get("kind")
            # a palette line never points at another group (use {palette:<group_id>}, which the build expands)
            palette_texts = [("group", group.get("palette_en") or "")] + [
                ("file " + str(item.get("name")), item["palette_en"]) for item in (group.get("files") or [])
                if isinstance(item, dict) and item.get("palette_en")]
            for label, text in palette_texts:
                expanded = resolve_palette(text, palettes, where, problems)
                pointer = PALETTE_POINTER_RE.search(expanded)
                if pointer:
                    problems.error("%s: the palette of %s points elsewhere (%r); list the colours or use {palette:<group_id>}" % (where, label, pointer.group(0)))
            # an audio group never points at its files or stems for its materials, palette or references
            if kind in AUDIO_KINDS:
                for label, text in (("palette_en", group.get("palette_en") or ""), ("audio.materials_en", (group.get("audio") or {}).get("materials_en") or ""),
                                    ("audio.references_en", (group.get("audio") or {}).get("references_en") or "")):
                    pointer = AUDIO_POINTER_RE.search(text)
                    if pointer:
                        problems.error("%s: %s points elsewhere (%r); name the materials in the line itself" % (where, label, pointer.group(0)))
            # colour budget of a tile (the palette line is the palette of every tile of the group)
            if kind == "tile":
                colours = {m.upper() for m in HEX_RE.findall(resolve_palette(group.get("palette_en"), palettes, where, problems))}
                if len(colours) > colour_limit(group):
                    problems.error("%s: palette_en names %d colours but a tile may use at most %d" % (where, len(colours), colour_limit(group)))
            # one object per file, nothing too big
            for item in group.get("files") or []:
                if isinstance(item, dict) and COMPOSITE_NAME_RE.search(item.get("name", "")):
                    problems.warn("%s: file %s looks like a composite (pair/both/couple); one file should be one object" % (where, item["name"]))
                if (kind in ("prop", "tile", "sprite", "icon") and isinstance(item, dict) and not item.get("compound_ok")
                        and (CLUSTER_NAME_RE.search(item.get("name", "")) or CLUSTER_TEXT_RE.search(item.get("what_en", "")))):
                    problems.warn("%s: file %s looks like a loose pile or scatter; split it into single objects or mark it compound_ok with a reason" % (where, item["name"]))
            size = group.get("size")
            if kind in IMAGE_KINDS and isinstance(size, list) and len(size) == 2:
                if (size[0] * size[1] > BIG_IMAGE_AREA and "child_hand" not in (group.get("folder") or "")
                        and "hand" not in group.get("group_id", "") and group.get("group_id") not in BIG_IMAGE_ALLOWED):
                    problems.warn("%s: %dx%d is larger than 128x96; consider splitting it into smaller swappable parts" % (where, size[0], size[1]))
            # a voice-blip group must describe the takes it really has
            if kind == "voice_blip":
                by_event = {}
                for item in group.get("files") or []:
                    event = item.get("event_id")
                    by_event[event] = max(by_event.get(event, 0), item.get("take_count") or 1)
                declared = (group.get("audio") or {}).get("variations_by_event")
                if declared != by_event:
                    problems.error("%s: audio.variations_by_event %r does not match the files %r" % (where, declared, by_event))
                details = group.get("details_en") or ""
                for phrase, event in (("The %s plain blips", "blip"), ("the %s 'question' blips", "blip_question"), ("the %s 'end' blips", "blip_end")):
                    if event in by_event and phrase % NUMBER_WORD.get(by_event[event], str(by_event[event])) not in details:
                        problems.error("%s: details_en does not say %r for the %d %s takes" % (where, phrase % NUMBER_WORD.get(by_event[event]), by_event[event], event))
                for event, count in by_event.items():
                    if event not in STANDARD_BLIP_EVENTS and "`%s`" % event not in details:
                        problems.error("%s: details_en does not describe the extra set `%s` (%d takes)" % (where, event, count))
    lint_self_contained(specs, problems)
    lint_sibling_pointers(specs, problems)
    lint_pieces(style, specs, problems)
    lint_audio_formats(specs, problems)
    lint_sourcing(specs, problems)


CROSS_GROUP_TOKEN_RE = re.compile(r"\b[a-z][a-z0-9]*(?:_[a-z0-9]+)+\b")
STEM_RE = re.compile(r"\bstems?\b|AudioStreamSynchronized|synchroni[sz]ed set|layered cue", re.I)
SMPL_RE = re.compile(r"\bsmpl\b|unbound_march", re.I)


def prompt_texts(group):
    """Every free-text field of a group that ends up inside a prompt, as (label, text)."""
    out = []
    for key in ("subject_en", "details_en", "avoid_en", "palette_en"):
        if isinstance(group.get(key), str):
            out.append((key, group[key]))
    for item in group.get("files") or []:
        if isinstance(item, dict):
            for key in ("what_en", "palette_en", "source"):
                if isinstance(item.get(key), str):
                    out.append(("file %s %s" % (item.get("name"), key), item[key]))
    for clip in group.get("clips") or []:
        for index, pose in enumerate(clip.get("poses_en") or []):
            if isinstance(pose, str):
                out.append(("clip %s pose %d" % (clip.get("clip"), index + 1), pose))
    audio = group.get("audio")
    if isinstance(audio, dict):
        for key in ("mood_en", "materials_en", "references_en"):
            if isinstance(audio.get(key), str):
                out.append(("audio." + key, audio[key]))
    return out


def lint_self_contained(specs, problems):
    """A prompt is read by a tool that cannot open any other entry, so it never names another group (owner's quality rule:
    inline the colours or the description instead). {palette:<id>} tokens are fine: the build copies the palette text in."""
    group_ids = set()
    for groups in specs.values():
        for group in groups:
            group_ids.add(group.get("group_id"))
    for category, groups in specs.items():
        for group in groups:
            gid = group.get("group_id")
            for label, text in prompt_texts(group):
                plain = PALETTE_REF_RE.sub("", text)
                for match in CROSS_GROUP_TOKEN_RE.finditer(plain):
                    word = match.group(0)
                    if word in group_ids and word != gid:
                        problems.error("%s/%s: %s names another group (%r); write what the prompt needs inline instead" % (category, gid, label, word))
                        break


# A prompt is read by a tool that cannot open any other file, so it never points at a sibling FILE either: not by its name
# ("the same gate as gate_closed_h", "identical to prop_closed.png", "as path_pink_h"), not by "<clip> frame N" of another clip.
# Labels are fine: a group may name its own clips and files ("lane_channel is the loop while a lane grows") as long as no sentence
# says "same as", "matches", "identical to", "as", "like", "than" ... in front of the name.
SIBLING_EXT_RE = re.compile(r"\.(?:png|wav|ogg|ttf|otf)$")
SIBLING_FILE_RE = re.compile(r"(?<![A-Za-z0-9_])((?:[A-Za-z0-9_]+/)*[A-Za-z0-9_]+)\.(?:png|wav|ogg)\b")
SIBLING_CUE_RE = re.compile(
    r"(?:(?:same|identical(?:ly)?|match\w*|equal|similar|copy|copies|mirror\w*|reus\w+|continu\w+|exactly|unchanged|follows?)"
    r"(?:\s+(?:to|as|with|in|from|of))?|as|like|than|frame(?:\s+of)?|of)\s+(?:the\s+|this\s+|that\s+|a\s+)?(?:last\s+|first\s+)?['`(\"]?$", re.I)
SIBLING_FRAME_RE = re.compile(r"\b([A-Za-z][A-Za-z0-9_]*) frame \d+\b|\bframe \d+ of (?:the )?([A-Za-z][A-Za-z0-9_]*)\b")
SIBLING_PAREN_RE = re.compile(r"\(([a-z0-9]+(?:_[a-z0-9]+)+)\)")
SIBLING_NO_LINT_KINDS = ("sourcing", "font")


def sibling_names(specs):
    """Every name another entry answers to: file stems (and the folders inside a file name), folder basenames, clip names."""
    names = {}
    clip_names = set()
    for groups in specs.values():
        for group in groups:
            gid = group.get("group_id")
            base = (group.get("folder") or "").rstrip("/").split("/")[-1]
            names.setdefault(base, set()).add(gid)
            for item in group.get("files") or []:
                name = item.get("name", "")
                names.setdefault(SIBLING_EXT_RE.sub("", name).split("/")[-1], set()).add(gid)
                for part in name.split("/")[:-1]:
                    names.setdefault(part, set()).add(gid)
            for clip in group.get("clips") or []:
                names.setdefault(clip.get("clip"), set()).add(gid)
                clip_names.add(clip.get("clip"))
    return names, clip_names


def sibling_slots(group):
    """(label, text, own names) for every free-text field of a group; group-level text has no own names."""
    base = (group.get("folder") or "").rstrip("/").split("/")[-1]
    for key in ("subject_en", "details_en", "avoid_en", "palette_en"):
        if isinstance(group.get(key), str):
            yield key, group[key], set()
    for item in group.get("files") or []:
        name = item.get("name", "")
        own = {SIBLING_EXT_RE.sub("", name).split("/")[-1], base} | set(name.split("/")[:-1])
        for key in ("what_en", "palette_en"):
            if isinstance(item.get(key), str):
                yield "file %s %s" % (name, key), item[key], own
    for clip in group.get("clips") or []:
        for index, pose in enumerate(clip.get("poses_en") or []):
            if isinstance(pose, str):
                yield "clip %s pose %d" % (clip.get("clip"), index + 1), pose, {clip.get("clip"), base}


def lint_sibling_pointers(specs, problems):
    names, clip_names = sibling_names(specs)
    underscored = sorted((n for n in names if n and "_" in n and len(n) >= 5), key=len, reverse=True)
    if not underscored:
        return
    name_re = re.compile(r"(?<![A-Za-z0-9_/.-])(" + "|".join(re.escape(n) for n in underscored) + r")(?![A-Za-z0-9_])")
    lower_clips = {c.lower() for c in clip_names if c}
    for category, groups in specs.items():
        for group in groups:
            if group.get("kind") in SIBLING_NO_LINT_KINDS:
                continue
            gid = group.get("group_id")
            skip = {gid, (group.get("folder") or "").rstrip("/").split("/")[-1]}
            for label, text, own in sibling_slots(group):
                plain = PALETTE_REF_RE.sub("", text)
                found = None
                for match in SIBLING_FILE_RE.finditer(plain):
                    stem = match.group(1).split("/")[-1]
                    if stem in own or stem in skip:
                        continue
                    found = "a file name (%r)" % match.group(0)
                    break
                if not found:
                    for match in name_re.finditer(plain):
                        name = match.group(1)
                        if name in own or name in skip:
                            continue
                        before = plain[max(0, match.start() - 45):match.start()]
                        if SIBLING_CUE_RE.search(before) or (plain[match.end():match.end() + 1] == ")" and before.endswith("(")):
                            found = "the name of another entry (%r) after a 'same as / matches / as / like' cue" % name
                            break
                if not found:
                    for match in SIBLING_FRAME_RE.finditer(plain):
                        word = (match.group(1) or match.group(2) or "").lower()
                        own_clip = {o.lower() for o in own}
                        if word in lower_clips and word not in own_clip:
                            found = "a frame of another clip (%r)" % match.group(0)
                            break
                if found:
                    problems.error("%s/%s: %s points at %s; describe what it looks like inline instead" % (category, gid, label, found))


def lint_pieces(style, specs, problems):
    """Owner decision 2026-10-12: a chess piece is smaller than its cell. Every piece is drawn on the 32x32 canvas of one cell."""
    rows = {row.get("id"): row for row in style.get("scale_table", [])}
    for piece_class in PIECE_CLASSES:
        row = rows.get("piece_%s_32" % piece_class)
        if row is None:
            problems.error("style.json: scale_table has no row 'piece_%s_32' (one row per chess-piece class)" % piece_class)
        elif list(row.get("size", [])) != PIECE_CANVAS:
            problems.error("style.json: scale row piece_%s_32 must be %s, it is %s" % (piece_class, PIECE_CANVAS, row.get("size")))
    for row in style.get("scale_table", []):
        size = row.get("size") or [0, 0]
        if (row.get("kind") == "sprite" and (size[0] > 32 or size[1] > 32)
                and row.get("id") not in ("boss_engine_96x80", "child_hand_192x144")):
            problems.error("style.json: scale row %s is a %s sprite larger than one cell; chess pieces and their overlays fit 32x32" % (row.get("id"), size))
    for category, groups in specs.items():
        for group in groups:
            gid = group.get("group_id")
            piece_class = group.get("piece_class")
            size = group.get("size")
            if piece_class is not None:
                if piece_class not in PIECE_CLASSES:
                    problems.error("%s/%s: piece_class %r is not one of %s" % (category, gid, piece_class, PIECE_CLASSES))
                if size != PIECE_CANVAS:
                    problems.error("%s/%s: a chess piece is smaller than its cell; the canvas must be %s, it is %s" % (category, gid, PIECE_CANVAS, size))
                if "CELL FIT" not in (group.get("details_en") or ""):
                    problems.error("%s/%s: a piece group must carry the CELL FIT paragraph in details_en" % (category, gid))
            elif (category == "characters" and group.get("kind") in ("sprite", "prop") and isinstance(size, list) and len(size) == 2
                  and (size[0] > 32 or size[1] > 32) and gid not in NON_PIECE_LARGE_SPRITES):
                problems.error("%s/%s: %sx%s is larger than one cell; a piece is drawn on 32x32 (set piece_class) or the group is a non-piece (NON_PIECE_LARGE_SPRITES)" % (
                    category, gid, size[0], size[1]))


def lint_audio_formats(specs, problems):
    """Owner decision 2026-10-12: SFX and voice blips are WAV, music and ambience are OGG, one complete track per area (no stems)."""
    for group in specs.get("audio", []):
        gid, kind = group.get("group_id"), group.get("kind")
        fmt = ((group.get("audio") or {}).get("format") or "").lower()
        if kind in ("music", "ambience") and not fmt.startswith("ogg"):
            problems.error("audio/%s: %s is delivered as OGG, the format line says %r" % (gid, kind, fmt))
        if kind in ("sfx", "voice_blip") and not fmt.startswith("wav"):
            problems.error("audio/%s: %s is delivered as WAV, the format line says %r" % (gid, kind, fmt))
        if kind in ("music", "ambience"):
            for label, text in prompt_texts(group):
                if STEM_RE.search(text) or SMPL_RE.search(text):
                    problems.error("audio/%s: %s still talks about stems or an smpl loop chunk; one complete OGG track per area" % (gid, label))
                    break
            if kind == "music" and any(re.search(r"\blayers?\b", text, re.I) for _label, text in prompt_texts(group)):
                problems.error("audio/%s: music is one complete track, no layer files" % gid)


def lint_sourcing(specs, problems):
    """The input glyphs are sourced from the Kenney CC0 pack, never drawn: no ui group may sit in assets/ui/glyphs."""
    for category, groups in specs.items():
        for group in groups:
            folder = (group.get("folder") or "")
            if folder.startswith("assets/ui/glyphs") and group.get("kind") not in SOURCING_KINDS:
                problems.error("%s/%s: the glyph folder is filled from the CC0 pack (kind 'sourcing'), not drawn" % (category, group.get("group_id")))
            if group.get("kind") in SOURCING_KINDS:
                for item in group.get("files") or []:
                    if not item.get("source") or item.get("coverage") not in SOURCING_COVERAGE:
                        problems.error("%s/%s: file %s needs 'source' and a coverage of %s" % (category, group.get("group_id"), item.get("name"), SOURCING_COVERAGE))


# --------------------------------------------------------------------------- 1x1 pixel scale (owner decision 2026-10-13)

# Owner decision 2026-10-13 ("Tat ca 1x1"): EVERY image is drawn at 1x1 pixels on the native 640x360: pieces, tiles, props, world
# effects, UI, icons, portraits. There is no 2x2 chunky world scale any more. A prompt that still talks about blocks of pixels, a
# half-size grid, upscaling, "chunky" art, art pixels as a unit of its own or "world" versus "fine" pixels is stale and would make
# an image tool draw the wrong density, so the build fails on it. The rules read the words an author writes about the pixel scale;
# a count of CELLS ("a 2x2-cell emblem", "the 2x2 hub emblem", "a 2x2 round table") and the plain adjective "fine" for a material
# are not pixel talk and pass; any other bare "2x2" (a 2x2 dot, 2x2 fragments) must be restated ("2 px square").
STALE_PIXEL_SCALE_RULES = (
    ("a 2x2 block of pixels", re.compile(
        r"\b2\s*[x\u00d7]\s*2\b(?![ -]*(?:cells?|emblem|hub|rug|table|drum|footprint|centre|center|round|quarters?))", re.I)),
    ("chunky art", re.compile(r"\bchunk(?:y|ier|iest|iness)\b", re.I)),
    ("half-resolution or half-size drawing", re.compile(
        r"\bhalf[- ](?:size|sized|resolution|res|scale|scaled|grid|density)\b|\b(?:low|reduced|coarse)[- ]res(?:olution)?\b", re.I)),
    ("upscaling or doubling", re.compile(
        r"\bup[- ]?scal\w*|\bdoubl(?:e|ed|ing)\s+(?:it|up|the size|the grid|each pixel|every pixel)\b|\benlarged?\s+(?:2x|twice|by 2)\b", re.I)),
    ("art pixels counted as their own unit", re.compile(r"\b\d+\s*(?:[x\u00d7]\s*\d+\s*)?art[- ]pixels?\b(?!\s*=)", re.I)),
    ("a block of identical pixels", re.compile(
        r"\b(?:pixel|px)[- ]blocks?\b|\bblocks? of (?:identical|\d+\s*[x\u00d7]\s*\d+|\d+ ?px|game|delivered|\d+ pixels)"
        r"|\bidentical (?:game |delivered )?pixels\b|\bdraw(?:n)? on a \d+\s*[x\u00d7]\s*\d+ grid\b", re.I)),
    ("even-step or canvas-pixel measures", re.compile(
        r"\bsteps? of 2\b|\b2 canvas pixels?\b|\bmultiples? of (?:the )?2 px\b|\ba 2 px art pixel\b", re.I)),
    ("two pixel scales (world versus fine)", re.compile(
        r"\btwo pixel scales\b|\b(?:world|chess|chunky) pixels\b|(?-i:\bFINE\b)|\btwice as fine\b|\btwice the pixel density\b"
        r"|\bfiner pixel work\b|\bfine pixels?\b|\bpixel density of the\b", re.I)),
)


def stale_pixel_scale_hits(text):
    """Every stale pixel-scale phrase of one text as (rule name, matched text)."""
    hits = []
    for name, pattern in STALE_PIXEL_SCALE_RULES:
        for match in pattern.finditer(text):
            hits.append((name, match.group(0)))
    return hits


# Sample texts for --self-test: each of the first group must be caught by the named rule, none of the second may be.
PIXEL_SCALE_LINT_MUST_FAIL = (
    ("a 2x2 block of pixels", "every art pixel is a 2x2 block of identical delivered pixels"),
    ("a 2x2 block of pixels", "a 2x2 px gold dot with one white pixel"),
    ("a 2x2 block of pixels", "drawn on a 2x2 pixel grid"),
    ("a 2x2 block of pixels", "three 2x2 yellow fragments fly out"),
    ("a 2x2 block of pixels", "a rosette (2x2 ivory/charcoal squares)"),
    ("chunky art", "Chunky machine pixel art with a near-black outline"),
    ("chunky art", "a chunkier burst"),
    ("half-resolution or half-size drawing", "draw on a half-size grid"),
    ("half-resolution or half-size drawing", "drawn at half resolution"),
    ("upscaling or doubling", "then upscale 2x with nearest-neighbour"),
    ("art pixels counted as their own unit", "body box 18x22 px (9x11 art pixels)"),
    ("art pixels counted as their own unit", "a 4x4 art-pixel disc"),
    ("a block of identical pixels", "each pixel is a block of 2x2 pixels"),
    ("even-step or canvas-pixel measures", "rounded to steps of 2"),
    ("two pixel scales (world versus fine)", "Two pixel scales exist"),
    ("two pixel scales (world versus fine)", "drawn in chunky world pixels"),
    ("two pixel scales (world versus fine)", "UI is FINE"),
)
PIXEL_SCALE_LINT_MUST_PASS = (
    "1 art pixel = 1 game pixel (every pixel of the canvas is placed individually at native size)",
    "a 2x2-cell emblem split into four 32x32 quarters",
    "Nw/ne/sw/se is the quarter's position in the 2x2 hub emblem",
    "the footprint is 2x2 cells",
    "a round tea-party table (four 32x32 quarters forming a 2x2 table)",
    "the pawn silhouette is cut exactly at the 2x2 centre",
    "plain meadow-green felt with fine fibres",
    "a sturdy wooden toy block and a thick painted post",
    "a 2 px square dot, 4 px by 2 px specks and a 1 px outline",
    "the chess-piece body is 18x22 px",
)


def run_pixel_scale_lint_self_test(out=sys.stdout):
    """Prove the stale-pixel-scale rules catch what they must and spare what they must: exit code 0 or 1."""
    failures = 0
    for rule, sample in PIXEL_SCALE_LINT_MUST_FAIL:
        names = {name for name, _text in stale_pixel_scale_hits(sample)}
        if rule not in names:
            failures += 1
            print("SELF-TEST FAIL: rule %r did not catch %r (caught: %s)" % (rule, sample, sorted(names) or "nothing"), file=out)
    for sample in PIXEL_SCALE_LINT_MUST_PASS:
        hits = stale_pixel_scale_hits(sample)
        if hits:
            failures += 1
            print("SELF-TEST FAIL: %r must pass but the lint flags %s" % (sample, hits), file=out)
    if failures:
        return 1
    print("pixel-scale lint self-test OK: %d stale samples caught, %d clean samples passed" % (
        len(PIXEL_SCALE_LINT_MUST_FAIL), len(PIXEL_SCALE_LINT_MUST_PASS)), file=out)
    return 0


def lint_pixel_scale(style, specs, entries, problems):
    """Owner decision 2026-10-13 ('Tat ca 1x1'): one pixel scale for every image, and no prompt talks about another one."""
    block = style.get("style_block_en", "")
    if "RESOLUTION AND PIXEL SCALE" not in block or "1x1" not in block:
        problems.error("style.json: the style block must keep its RESOLUTION AND PIXEL SCALE paragraph and say that every image is drawn at 1x1")
    for row in style.get("scale_table", []):
        if row.get("block_px") != PIXEL_SCALE:
            problems.error("style.json: scale row %s has block_px %r; every image is drawn at 1x1 (block_px %d)" % (
                row.get("id"), row.get("block_px"), PIXEL_SCALE))
    for category, groups in specs.items():
        for group in groups:
            if "block_px" in group and group["block_px"] != PIXEL_SCALE:
                problems.error("%s/%s: block_px %r; every image is drawn at 1x1" % (category, group.get("group_id"), group["block_px"]))
    # The style block and the shared DO NOT lines are read once; every image prompt is the style block plus its own text.
    shared = [("style block", block), ("global_avoid_en", style.get("global_avoid_en", ""))]
    shared += [("avoid variant %s" % name, text) for name, text in (style.get("global_avoid_variants_en") or {}).items()]
    for label, text in shared:
        for rule, found in stale_pixel_scale_hits(text):
            problems.error("style.json: %s still talks about the old pixel scale (%s: %r)" % (label, rule, found))
    reported = set()
    for entry in entries:
        if entry["media"] != "image":
            continue
        prompt = entry["prompt"]
        if GRID_PHRASE not in prompt:
            problems.error("%s: the CANVAS line must say %r" % (entry["id"], GRID_PHRASE))
        own = prompt[len(block.rstrip()):] if prompt.startswith(block.rstrip()) else prompt
        for rule, found in stale_pixel_scale_hits(own):
            key = (entry["category"], entry["group_id"], rule)
            if key in reported:
                continue
            reported.add(key)
            problems.error("%s/%s: the prompt of %s still mentions the old pixel scale (%s: %r); every image is 1x1, restate it in pixels" % (
                entry["category"], entry["group_id"], entry["path"], rule, found))


# --------------------------------------------------------------------------- statistics

def collect_stats(groups, entries):
    stats = {
        "total": len(entries), "groups": len(groups),
        "by_category": Counter(e["category"] for e in entries),
        "groups_by_category": Counter(g["category"] for g in groups),
        "by_kind": Counter(e["kind"] for e in entries),
        "by_priority": Counter(e["priority"] for e in entries),
        "by_milestone": Counter(e["needed_by"] for e in entries),
        "by_media": Counter(e["media"] for e in entries),
        "frames": sum(1 for e in entries if e["is_frame"]),
        "category_priority": Counter((e["category"], e["priority"]) for e in entries),
        "kind_priority": Counter((e["kind"], e["priority"]) for e in entries),
        "milestone_priority": Counter((e["needed_by"], e["priority"]) for e in entries),
        "major_priority": Counter((major_milestone(e["needed_by"]), e["priority"]) for e in entries),
        "category_milestone": Counter((e["category"], e["needed_by"]) for e in entries),
    }
    return stats


def sorted_milestones(counter_keys):
    return sorted(set(counter_keys), key=milestone_key)


# --------------------------------------------------------------------------- rendering: group files

def render_entry(entry):
    prompt = entry["prompt"]
    fence = fence_for(prompt)
    if entry["media"] == "image":
        width, height = entry["size"]
        anchor = (entry["anchor"] or "none").strip()
        spec = "%dx%d px, lưới %dx%d, neo: %s" % (width, height, entry["block_px"], entry["block_px"], anchor)
        if entry["is_frame"]:
            spec += " · khung %d/%d clip %s (%s, %d fps)" % (entry["frame"], entry["frames"], entry["clip"],
                                                             "lặp" if entry["loop"] else "một lần", entry["fps"])
    elif entry["media"] == "audio":
        audio = entry["audio"]
        loop_text = ("lặp liền mạch (không thẻ loop)" if entry["path"].endswith(".ogg") else "lặp liền mạch (smpl loop)")
        spec = "%s, %s s, %s" % (audio["format"].strip(), fmt_seconds(entry["duration_s"]), loop_text if entry["loop"] else "không lặp")
        if entry.get("take_count"):
            spec += ", bản %d/%d" % (entry["take"], entry["take_count"])
    elif entry["media"] == "sourcing":
        spec = "%dx%d px, chép từ bộ %s của %s (%s) · nguồn: %s · mức chắc chắn: %s" % (
            entry["size"][0], entry["size"][1], entry["sourcing"]["pack"], entry["sourcing"]["author"], entry["sourcing"]["licence"],
            entry["source"], entry["coverage"])
    else:
        spec = "file font do anh cung cấp (.ttf/.otf), không có canvas"
    out = [
        '<a id="%s"></a>' % entry["id"],
        "",
        "### %s · %s" % (entry["id"], entry["title_vi"]),
        "- **File:** `%s`" % entry["path"],
        "- **Spec:** %s · **Cần từ:** %s · **Ưu tiên:** %s · **Placeholder:** %s" % (
            spec, entry["needed_by"], entry["priority"], entry["placeholder"]),
        "- **Prompt:**",
        "  %stext" % fence,
    ]
    for line in prompt.split("\n"):
        out.append("  " + line if line else "")
    out.append("  " + fence)
    out.append("- **Kiểm tra:** %s" % entry["acceptance"])
    out.append("")
    return "\n".join(out)


def render_group_file(group, entries_of_group):
    sourcing = entries_of_group[0].get("sourcing") if entries_of_group and group["media"] == "sourcing" else None
    frames = sum(1 for e in entries_of_group if e["is_frame"])
    stills = len(entries_of_group) - frames
    pr = Counter(e["priority"] for e in entries_of_group)
    lines = ["# %s" % group["title_vi"], ""]
    lines.append("- **Danh mục:** `%s` · **Nhóm:** `%s` · **Loại:** %s · **Thư mục:** `%s`" % (
        group["category"], group["group_id"], group["kind"], group["folder"]))
    if group["media"] in ("image", "sourcing"):
        lines.append("- **Canvas:** %dx%d px, lưới pixel %dx%d · **Neo:** %s" % (
            group["size"][0], group["size"][1], group["block_px"], group["block_px"], (group["anchor"] or "none").strip()))
    lines.append("- **Số file:** %d (%d file tĩnh, %d khung hoạt ảnh) · must %d · should %d · could %d" % (
        len(entries_of_group), stills, frames, pr["must"], pr["should"], pr["could"]))
    if group["notes_vi"]:
        lines.append("- **Ghi chú:** %s" % group["notes_vi"].strip())
    if group["used_in"]:
        lines.append("- **Dùng ở:** %s" % group["used_in"].strip())
    if group["reference_files"]:
        lines.append("- **File tham chiếu:**")
        for ref in group["reference_files"]:
            lines.append("  - `%s`" % ref)
    if sourcing:
        lines.append("- **Bộ nguồn:** %s của %s · %s · giấy phép %s (%s)" % (
            sourcing["pack"], sourcing["author"], sourcing["url"], sourcing["licence"], sourcing["licence_url"]))
        lines.append("- **Cách lấy:** %s" % sourcing["download_en"].strip())
    lines.append("- **Placeholder hiện tại:** %s" % group["placeholder_now"])
    lines.append("")
    lines.append("---")
    lines.append("")
    for entry in entries_of_group:
        lines.append(render_entry(entry))
    return "\n".join(lines).rstrip() + "\n"


# --------------------------------------------------------------------------- rendering: index, milestones

def render_index(groups, entries_by_group):
    lines = ["# Mục lục các nhóm yêu cầu", "",
             "Mỗi nhóm là một file Markdown trong thư mục cùng tên danh mục. Tổng %d nhóm." % len(groups), ""]
    for category in CATEGORIES:
        subset = [g for g in groups if g["category"] == category]
        if not subset:
            continue
        lines.append("## %s (%d nhóm, %d file)" % (category, len(subset), sum(len(entries_by_group[(g["category"], g["group_id"])]) for g in subset)))
        lines.append("")
        lines.append("| Nhóm | Tên | Loại | File | Mốc | must | should | could |")
        lines.append("|---|---|---|---:|---|---:|---:|---:|")
        for g in subset:
            es = entries_by_group[(g["category"], g["group_id"])]
            pr = Counter(e["priority"] for e in es)
            milestones = sorted_milestones(e["needed_by"] for e in es)
            span = milestones[0] if len(milestones) == 1 else "%s..%s" % (milestones[0], milestones[-1])
            lines.append("| [`%s`](%s/%s.md) | %s | %s | %d | %s | %d | %d | %d |" % (
                g["group_id"], category, g["group_id"], md_cell(g["title_vi"]), g["kind"], len(es), span,
                pr["must"], pr["should"], pr["could"]))
        lines.append("")
    return "\n".join(lines)


def render_by_milestone(entries, stats):
    labels = sorted_milestones(e["needed_by"] for e in entries)
    lines = ["# Danh sách asset theo mốc (milestone)", "",
             "Làm theo thứ tự mốc từ nhỏ đến lớn; trong mỗi mốc làm `must` trước, rồi `should`, rồi `could` (`could` là phần hoãn lại, 'để sau': luôn nằm cuối mỗi mốc, "
             "và phần lớn dồn ở M14). "
             "Mỗi dòng là một file duy nhất: id, đường dẫn đặt file, và liên kết tới nhóm có prompt đầy đủ.", "",
             "| Mốc | Tổng | must | should | could |", "|---|---:|---:|---:|---:|"]
    for label in labels:
        lines.append("| [%s](#%s) | %d | %d | %d | %d |" % (
            label, label.lower(), stats["by_milestone"][label], stats["milestone_priority"][(label, "must")],
            stats["milestone_priority"][(label, "should")], stats["milestone_priority"][(label, "could")]))
    lines.append("| **Tổng** | **%d** | **%d** | **%d** | **%d** |" % (
        stats["total"], stats["by_priority"]["must"], stats["by_priority"]["should"], stats["by_priority"]["could"]))
    lines.append("")
    by_label = defaultdict(list)
    for entry in entries:
        by_label[entry["needed_by"]].append(entry)
    for label in labels:
        bucket = by_label[label]
        lines.append('<a id="%s"></a>' % label.lower())
        lines.append("")
        lines.append("## %s · %d file · must %d · should %d · could %d" % (
            label, len(bucket), stats["milestone_priority"][(label, "must")],
            stats["milestone_priority"][(label, "should")], stats["milestone_priority"][(label, "could")]))
        lines.append("")
        for priority in PRIORITIES:
            subset = [e for e in bucket if e["priority"] == priority]
            if not subset:
                continue
            lines.append("### %s · %s (%d)" % (label, priority, len(subset)))
            lines.append("")
            current_group = None
            for entry in subset:
                key = (entry["category"], entry["group_id"])
                if key != current_group:
                    if current_group is not None:
                        lines.append("")
                    current_group = key
                    lines.append("**%s** (`%s/%s`)" % (entry["group_title_vi"], entry["category"], entry["group_id"]))
                    lines.append("")
                lines.append("- [`%s`](%s#%s) · `%s`" % (entry["id"], entry["group_file"], entry["id"], entry["path"]))
            lines.append("")
    return "\n".join(lines)


# --------------------------------------------------------------------------- rendering: README, STYLE

def table(headers, rows, aligns=None):
    aligns = aligns or ["---"] * len(headers)
    out = ["| " + " | ".join(headers) + " |", "|" + "|".join(aligns) + "|"]
    for row in rows:
        out.append("| " + " | ".join(md_cell(c) for c in row) + " |")
    return out


def scale_table_rows(style):
    rows = []
    for item in style["scale_table"]:
        size = item.get("size") or [0, 0]
        if item["kind"] == "font":
            size_text, grid_text = "file, không có canvas", "-"
        elif item["id"] == "ui_free":
            size_text, grid_text = "tự do, cạnh chẵn từ 4 đến 384 px", "1x1"
        else:
            size_text = "%dx%d" % tuple(size)
            grid_text = "%dx%d" % (item["block_px"], item["block_px"])
        rows.append(["`%s`" % item["id"], item["kind"], size_text, grid_text, item["anchor"], item["use"]])
    return rows


def render_style_md(style):
    lines = ["# STYLE — phong cách và quy tắc giao file", "",
             "File này được tự sinh từ `style.json`. Mọi prompt ảnh bắt đầu bằng đúng khối phong cách dưới đây; "
             "mọi prompt âm thanh bắt đầu bằng đúng bản tóm tắt âm thanh.", ""]
    lines += ["## Khối phong cách (style block) — chép vào đầu mọi prompt ảnh", "", "```text",
              style["style_block_en"].rstrip(), "```", ""]
    lines += ["## Điều không được vẽ (global avoid)", "", "```text", style["global_avoid_en"].rstrip(), "```", ""]
    descriptions = {
        "surface": "Biến thể `surface` (mọi tile, nền bản đồ, ô giấy lặp, mảnh vista đặc): vật được vẽ CHÍNH LÀ mặt sàn/tường nên cho phép "
                   "vẽ kín canvas tới cạnh, không còn cấm 'nền, sàn, khung, viền' của mặt đó.",
        "frame": "Biến thể `frame` (mọi UI/9-patch/khung/bảng/phím, mảnh khung bản đồ, hàng rào và khung ảnh): vật được vẽ CHÍNH LÀ "
                 "khung/viền/bảng nên không bị cấm vẽ khung/viền của nó, 9-patch được phép chạy tới cạnh canvas.",
    }
    for name, text in style.get("global_avoid_variants_en", {}).items():
        lines += ["### Điều không được vẽ, biến thể `%s`" % name, "", descriptions.get(name, ""), "", "```text", text.rstrip(), "```", ""]
    lines += ["## Bản tóm tắt âm thanh (sound brief) — chép vào đầu mọi prompt âm thanh", "", "```text",
              style["sound_brief_en"].rstrip(), "```", ""]
    lines += ["## Điều không được làm trong âm thanh (global avoid, audio)", "", "```text",
              style["global_avoid_audio_en"].rstrip(), "```", ""]
    audio_descriptions = {
        "child_voice": "Biến thể `child_voice` (nhóm tiếng thở, hát khẽ, thở dài, hít mũi, cười khúc khích của bé): cho phép đúng những âm thanh người mà nhóm yêu cầu.",
        "ambient_life": "Biến thể `ambient_life` (nền buổi sáng có chim xa): cho phép tiếng chim hót xa mà mô tả file nêu.",
    }
    for name, text in style.get("global_avoid_audio_variants_en", {}).items():
        lines += ["### Điều không được làm trong âm thanh, biến thể `%s`" % name, "", audio_descriptions.get(name, ""), "", "```text", text.rstrip(), "```", ""]
    lines += ["## Bảng kích thước (scale table)", "",
              "Mọi canvas và điểm neo trong danh sách khớp một hàng của bảng này. Cột lưới: mọi hàng là `1x1` (quyết định của anh, "
              "2026-10-13): một pixel vẽ = một pixel game ở độ phân giải gốc 640x360, không có khối pixel lớn hơn ở đâu cả.", ""]
    lines += table(["Lớp", "Loại", "Canvas", "Lưới", "Điểm neo", "Dùng cho"], scale_table_rows(style))
    lines += ["", "## Quy tắc giao file", ""]
    for rule in style.get("delivery_rules_vi", []):
        lines.append("- %s" % rule)
    lines.append("")
    return "\n".join(lines)


def render_readme(style, groups, stats, spec_link):
    lines = ["# Danh sách yêu cầu asset — The Unbound Pawn", "",
             "> File này và mọi file trong `requests/` được **tự sinh** bởi `tools/asset_requests/build_requests.py` "
             "từ các file spec (`style.json`, `characters.json`, `world.json`, `ui_story.json`, `vfx.json`, `audio.json`). "
             "Đừng sửa tay; sửa spec rồi chạy lại.", "", "> Repo chỉ giữ spec, script, README này, `STYLE.md` và `by-milestone.md`. Thư mục `requests/` (khoảng 100 MB prompt) và `asset-manifest.json` không được commit — tạo lại bằng một lệnh: `python3 tools/asset_requests/build_requests.py`.", "",
             "Tổng cộng **%d file** trong **%d nhóm**: %d ảnh (trong đó %d khung hoạt ảnh), %d âm thanh (SFX và giọng là `.wav`, nhạc và ambience là `.ogg`), "
             "%d font và %d glyph phím/tay cầm chép từ bộ CC0 của Kenney (không vẽ)." % (
                 stats["total"], stats["groups"], stats["by_media"]["image"], stats["frames"], stats["by_media"]["audio"],
                 stats["by_media"]["font"], stats["by_media"]["sourcing"]),
             ""]
    lines += ["## 1. Cách hoạt động", "",
              "- **Một file = một vật.** Một tile 32x32, một vật cảnh, một biểu tượng, một phần giao diện, một cảm xúc "
              "chân dung, một KHUNG HÌNH hoạt ảnh, một âm thanh. Không gộp sheet, atlas, dải, ảnh nhiều vật hay tranh cả căn phòng.",
              "- **Mỗi mục có một prompt đầy đủ, tự đủ ý.** Chép nguyên khối trong ô `text` vào công cụ vẽ hoặc thu âm; "
              "không cần ghép thêm gì (khối phong cách đã nằm sẵn trong prompt).",
              "- **Đặt file đúng đường dẫn ghi ở mục `File`.** Ghi đè lên file placeholder cùng đường dẫn thì game tự dùng, "
              "không cần sửa code. Ghi đè là cách thay asset thật cho placeholder.",
              "- **Công cụ lo phần ghép.** Atlas, sprite sheet, tileset, cảnh phòng và vista đều do tool dựng từ các file đơn; "
              "anh chỉ giao từng mảnh nhỏ.",
              "- **Asset không bao giờ chặn việc build.** Chưa có file thật thì game dùng placeholder; thứ tự làm theo mốc "
              "`Cần từ` và ưu tiên must, should, could.",
              "- **Hoạt ảnh** lưu từng khung ở `<thư mục>/anim/<clip>/NN.png`, NN bắt đầu từ 01. Mọi khung của một clip "
              "cùng canvas, cùng điểm neo, cùng bảng màu.",
              "- **Thứ tự vẽ hoạt ảnh (quan trọng với công cụ vẽ chỉ nhận chữ):** vẽ file tham chiếu TRƯỚC (ảnh tĩnh `body.png`, `prop.png`... hoặc "
              "khung 01 của nhóm, prompt của từng khung ghi rõ đường dẫn), duyệt nó, rồi ĐÍNH KÈM chính file đó làm ảnh tham chiếu khi tạo "
              "mọi khung còn lại. Công cụ chỉ nhận chữ không mở được đường dẫn nên sẽ vẽ lệch nhân vật nếu thiếu bước đính kèm này.",
              "- **Dòng `DO NOT` có biến thể theo loại file.** Mặc định dành cho MỘT vật đứng riêng trên nền trong suốt. Tile, nền bản đồ và mảnh "
              "vista đặc dùng biến thể `surface` (vẽ kín canvas, mặt sàn/tường chính là vật cần vẽ); UI, 9-patch, khung, hàng rào dùng biến thể `frame` "
              "(khung/viền chính là vật cần vẽ); nhóm âm thanh người của bé và nền buổi sáng có chim dùng biến thể âm thanh riêng. Xem `STYLE.md`.",
              "- **Mỗi mục có dòng `Kiểm tra`**: tiêu chí nghiệm thu tự động (kích thước đúng, RGBA có alpha, lưới pixel, điểm neo; "
              "với âm thanh: định dạng, thời lượng ±10%, đỉnh, điểm lặp).",
              "- **Mọi ảnh vẽ pixel 1x1 (quyết định của anh, 2026-10-13: \"Tất cả 1×1\").** Quân cờ, boss, tile, vật cảnh, hiệu ứng thế giới, giao diện, "
              "icon, chân dung và bàn tay của bé đều là một pixel vẽ = một pixel game ở độ phân giải gốc 640x360: không vẽ trên lưới nhỏ rồi phóng to, "
              "không có khối pixel lớn hơn ở đâu cả. Canvas 32x32 nghĩa là có đủ 32x32 pixel thật để vẽ chi tiết (đinh tán, mũi khâu, thớ gỗ, điểm sáng một pixel).",
              "- **Quân cờ nhỏ hơn ô (quyết định của anh, 2026-10-12).** Mọi quân cờ (pawn của anh, mọi kẻ địch và biến thể, quân trắng được cứu, Vua trắng đã ngã, "
              "sáu boss) vẽ trên canvas 32x32 = đúng một ô, thân quân nằm gọn bên trong và chừa ít nhất 2 px trống mỗi cạnh: không bằng ô, không cao hơn ô. "
              "Chiều cao theo bộ cờ thật: Tốt thấp nhất, rồi Mã/Tượng/Xe, rồi Hậu, Vua cao nhất. Bảng cỡ ở mục 4 ghi từng hạng quân.",
              "- **Nhạc: một bài cho mỗi khu, không tách stem.** Mỗi vùng (title, Act 1, hub, năm khu, cảnh kết) và mỗi boss có đúng một bản phối hoàn chỉnh `.ogg`; "
              "đổi giai đoạn boss dùng thêm một tiếng 'phase sting' `.wav`. SFX và tiếng blip giọng là `.wav`.",
              "- **Glyph phím/tay cầm không vẽ.** Nhóm `glyphs_kenney` chỉ ghi file nào của bộ CC0 'Input Prompts Pixel' (Kenney) cần chép vào đường dẫn nào; "
              "file vẽ tay đặt đúng đường dẫn ấy sẽ thay được bất cứ lúc nào.", ""]
    lines += ["## 2. Cách duyệt danh sách", "",
              "- [`by-milestone.md`](by-milestone.md): tất cả id và đường dẫn theo mốc M2 đến M14, `must` trước.",
              "- [`requests/INDEX.md`](requests/INDEX.md): mục lục 5 danh mục và %d nhóm, mỗi nhóm một file." % stats["groups"],
              "- `requests/<danh mục>/<nhóm>.md`: đầu trang là mô tả nhóm (ghi chú, nơi dùng, file tham chiếu, placeholder), "
              "tiếp theo là từng mục với prompt.",
              "- [`STYLE.md`](STYLE.md): khối phong cách, điều cấm, bản tóm tắt âm thanh, bảng kích thước, quy tắc giao file.",
              "- [`asset-manifest.json`](asset-manifest.json): toàn bộ mục ở dạng máy đọc được (kèm prompt).", ""]
    if spec_link:
        lines += ["- Quyết định thẩm mỹ và các câu hỏi còn mở: [`%s`](%s) (mục 8)." % (spec_link, spec_link), ""]

    lines += ["## 3. Danh sách kiểm tra khi giao file", "",
              "1. File đúng đường dẫn và đúng tên ghi ở mục `File` (chữ thường, không dấu cách).",
              "2. Ảnh: PNG RGBA 8-bit, đúng kích thước canvas, nền trong suốt (tile, nền bản đồ và mảnh vista đặc thì đặc hoàn toàn), không làm mờ, không răng cưa.",
              "3. Mọi ảnh vẽ pixel 1x1 (quyết định của anh, 2026-10-13): quân cờ, boss, tile, vật cảnh, hiệu ứng thế giới, giao diện, icon, "
              "chân dung và bàn tay của bé đều là một pixel vẽ = một pixel game ở độ phân giải gốc 640x360, không phóng to, không khối pixel lớn hơn.",
              "4. Điểm neo (chân/đế) đúng toạ độ ghi trong `Spec`; các khung của một clip không lệch ngang quá 3 px. Mọi khung sau được tạo từ "
              "ảnh tham chiếu đã duyệt (xem mục 1), không vẽ rời từng khung.",
              "5. Không có chữ hoặc số trong ảnh (trừ logo và phím); đỏ san hô chỉ cho sát thương sắp xảy ra.",
              "6. Âm thanh: SFX và giọng là WAV 44.1 kHz 16-bit (mono hoặc stereo theo `Spec`), đỉnh -1 dBFS, không clip, không click; "
              "SFX lặp có smpl loop chunk liền mạch. Nhạc và ambience là OGG Vorbis 44.1 kHz stereo (chất lượng khoảng 6), một bản phối hoàn chỉnh "
              "cho mỗi khu/boss, bản lặp có mẫu đầu và cuối liên tục, KHÔNG nhúng thẻ loop (game bật cờ lặp khi nhập). "
              "Các biến thể `_01`, `_02`... nghe như cùng một vật.",
              "7. Font: file `.ttf` hoặc `.otf` giấy phép OFL/CC0. Chạy `python3 tools/asset_requests/build_requests.py --check-font <file>` "
              "(đọc bảng cmap giống `FontFile.has_char`, báo mọi chữ tiếng Việt còn thiếu, kể cả dấu chồng) trước khi chốt; độ cao dòng và "
              "khoảng trống cho dấu ở cỡ chữ thật vẫn là bước nhìn bằng mắt.",
              "7b. Glyph phím/tay cầm: chép đúng tile của bộ Kenney 'Input Prompts Pixel' (CC0) vào đường dẫn ghi ở mục `File`, thêm bộ này vào "
              "THIRD_PARTY_NOTICES.md; không vẽ lại, không đổi cỡ.",
              "8. Không đặt file trong thư mục bị gitignore (`assets/_generated/`, `build/`, `.godot/`): mọi thứ trong đó có thể bị máy ghi đè.",
              "9. Giao theo mốc: xong hết `must` của một mốc rồi mới sang `should`; mốc nhỏ trước.",
              "10. Phần trăm trong mô tả (ví dụ 'vòng 88 px ở 70%') là ĐỘ ĐỤC của phần tử, không phải kích thước hay tiến độ, trừ khi câu chữ nói "
              "rõ nó đo cái gì; vẽ bằng một màu phẳng với một giá trị alpha (alpha = % x 255), viền cứng. Tile đặc dùng lưới caro 1 pixel hoặc "
              "trộn màu sẵn. Không dùng gradient (xem đoạn PERCENTAGES AND TRANSLUCENCY trong `STYLE.md`).", ""]

    lines += ["## 4. Bảng kích thước", ""]
    lines += table(["Lớp", "Loại", "Canvas", "Lưới", "Điểm neo", "Dùng cho"], scale_table_rows(style))
    lines.append("")

    lines += ["## 5. Số lượng", "", "### Theo danh mục", ""]
    rows = []
    for category in CATEGORIES:
        rows.append([category, stats["groups_by_category"][category], stats["by_category"][category],
                     stats["category_priority"][(category, "must")], stats["category_priority"][(category, "should")],
                     stats["category_priority"][(category, "could")]])
    rows.append(["**Tổng**", stats["groups"], stats["total"], stats["by_priority"]["must"], stats["by_priority"]["should"], stats["by_priority"]["could"]])
    lines += table(["Danh mục", "Nhóm", "File", "must", "should", "could"], rows, ["---", "---:", "---:", "---:", "---:", "---:"])
    lines += ["", "### Theo loại (kind)", ""]
    kinds = sorted(stats["by_kind"], key=lambda k: (-stats["by_kind"][k], k))
    rows = [[k, stats["by_kind"][k], stats["kind_priority"][(k, "must")], stats["kind_priority"][(k, "should")],
             stats["kind_priority"][(k, "could")]] for k in kinds]
    lines += table(["Loại", "File", "must", "should", "could"], rows, ["---", "---:", "---:", "---:", "---:"])
    lines += ["", "### Theo ưu tiên", ""]
    rows = [[p, stats["by_priority"][p]] for p in PRIORITIES]
    lines += table(["Ưu tiên", "File"], rows, ["---", "---:"])
    lines += ["", "### Theo mốc (milestone)", ""]
    labels = sorted_milestones(stats["by_milestone"])
    rows = [[label, stats["by_milestone"][label], stats["milestone_priority"][(label, "must")],
             stats["milestone_priority"][(label, "should")], stats["milestone_priority"][(label, "could")]] for label in labels]
    lines += table(["Mốc", "File", "must", "should", "could"], rows, ["---", "---:", "---:", "---:", "---:"])
    majors = sorted({major_milestone(l) for l in labels}, key=milestone_key)
    lines += ["", "Gộp theo mốc lớn (M8a, M8b, M8c thành M8...):", ""]
    rows = []
    for major in majors:
        total = sum(stats["by_milestone"][l] for l in labels if major_milestone(l) == major)
        rows.append([major, total, stats["major_priority"][(major, "must")], stats["major_priority"][(major, "should")],
                     stats["major_priority"][(major, "could")]])
    lines += table(["Mốc lớn", "File", "must", "should", "could"], rows, ["---", "---:", "---:", "---:", "---:"])
    lines += ["", "### Theo danh mục và mốc", ""]
    rows = []
    for label in labels:
        rows.append([label] + [stats["category_milestone"][(c, label)] for c in CATEGORIES] + [stats["by_milestone"][label]])
    lines += table(["Mốc"] + CATEGORIES + ["Tổng"], rows, ["---"] + ["---:"] * (len(CATEGORIES) + 1))
    lines.append("")

    lines += ["## 6. Cấu trúc thư mục đầu ra", "", "```text",
              "README.md                  file này",
              "STYLE.md                   khối phong cách, điều cấm, bản tóm tắt âm thanh, bảng kích thước, quy tắc giao file",
              "by-milestone.md            id và đường dẫn theo mốc, must trước",
              "asset-manifest.json        toàn bộ mục (kèm prompt) cho công cụ",
              "requests/INDEX.md          mục lục các nhóm",
              "requests/<danh mục>/<nhóm>.md   các mục của một nhóm", "```", ""]

    lines += ["## 7. Tạo lại danh sách", "", "```bash",
              "python3 tools/asset_requests/build_requests.py",
              "# hoặc chỉ định thư mục:",
              "python3 tools/asset_requests/build_requests.py --spec docs/assets/spec --out docs/assets",
              "# kiểm tra font có đủ tiếng Việt (không cần spec):",
              "python3 tools/asset_requests/build_requests.py --check-font assets/fonts/ui_body_pixel.ttf",
              "# hoặc kiểm tra mọi font đã giao khi sinh danh sách (font chưa giao thì bỏ qua):",
              "python3 tools/asset_requests/build_requests.py --check-fonts .",
              "```", "",
              "Script chỉ dùng thư viện chuẩn của Python 3, kiểm tra spec (xem mục 8) và thoát với mã 1 nếu có lỗi, "
              "khi đó không ghi gì. Kết quả giống hệt nhau giữa các lần chạy (không có dấu thời gian). "
              "Mỗi prompt lặp lại khối phong cách nên toàn bộ đầu ra rất nặng (hơn 100 MB); "
              "thêm `--slim-manifest` để `asset-manifest.json` không chứa prompt (nhẹ hơn nhiều).", ""]

    lines += ["## 8. Kiểm tra tự động khi sinh danh sách", "",
              "- Đường dẫn là duy nhất (kể cả khi bỏ phân biệt chữ hoa thường) và id là duy nhất.",
              "- Mọi mục ảnh có kích thước hợp lệ, có đuôi `.png`; SFX và giọng có đuôi `.wav`, nhạc và ambience có đuôi `.ogg`.",
              "- Mọi ảnh vẽ pixel 1x1: khối phong cách còn đoạn RESOLUTION AND PIXEL SCALE, mọi hàng bảng cỡ có `block_px` 1, mọi dòng CANVAS ghi "
              "'1 art pixel = 1 game pixel', và không prompt ảnh nào còn nhắc khối pixel 2x2, chữ 'chunky', vẽ nửa kích thước hoặc nửa độ phân giải, "
              "'upscale', 'art pixel' làm đơn vị riêng hay hai thang pixel 'world' và 'fine' (build thất bại, nêu nhóm và cụm từ). "
              "`python3 tools/asset_requests/build_requests.py --self-test` chứng minh luật bắt được những cụm đó và bỏ qua số ô như '2x2 cells'.",
              "- Mọi quân cờ (nhóm có `piece_class`) vẽ trên canvas 32x32, có đoạn CELL FIT trong mô tả và đúng một hàng trong bảng cỡ; không sprite nào của "
              "lane nhân vật lớn hơn một ô trừ bàn tay của bé và Cỗ máy Luật (không phải quân cờ).",
              "- Prompt tự đủ ý: không prompt nào nêu tên nhóm khác (id kiểu `ten_nhom`); thứ cần từ nhóm khác phải được viết thẳng vào prompt (màu thì dùng `{palette:<id>}`).",
              "- Prompt cũng không được chỉ tới một file anh em bằng tên ('giống gate_closed_h', 'y hệt prop_closed.png', 'như path_pink_h', 'khung 1 của clip idle'): "
              "hình dạng, kích thước và màu cần có phải được mô tả thẳng trong prompt. Script bắt tên file có đuôi, tên file/thư mục/clip của mục khác đứng sau từ so sánh "
              "(same/identical/matches/as/like/than...) và kiểu '<clip> frame N' của một clip khác; chỉ gọi tên như nhãn ('lane_channel là vòng lặp khi vệt mọc') thì được.",
              "- Nhạc là một bản hoàn chỉnh cho mỗi khu/boss: không còn chữ stem, lớp (layer) hay smpl trong nhóm nhạc/ambience; nhóm nhạc và ambience khai định dạng `ogg`, nhóm SFX và blip khai `wav`.",
              "- Nhóm `sourcing` (glyph Kenney) mỗi file có `source` và mức chắc chắn `coverage` (tile / locate / compose); thư mục `assets/ui/glyphs` không còn nhóm vẽ tay.",
              "- Mỗi clip có đúng `frames` tư thế (pose) mô tả.",
              "- Mọi prompt chứa nguyên khối phong cách (ảnh) hoặc bản tóm tắt âm thanh (âm thanh).",
              "- Không có đường dẫn nào nằm trong thư mục bị `.gitignore`.",
              "- Tile phải có `tile_data`; mốc `needed_by` và `priority` hợp lệ.",
              "- `avoid_profile` của nhóm/file phải là một biến thể có trong `style.json`; mọi biến thể `DO NOT` vẫn trỏ tới đoạn PERCENTAGES AND TRANSLUCENCY "
              "và giữ nguyên các điều cấm không liên quan (chữ, xanh crayon, đỏ san hô, trắng/đen tuyền); `reference_image` của nhóm phải là một ảnh tĩnh có thật.",
              "- Bảng màu của nhóm tile không nêu quá 10 màu; khối phong cách còn đoạn PERCENTAGES AND TRANSLUCENCY và danh sách cấm trỏ tới nó.",
              "- Nhóm blip giọng nói khai đúng số bản thu của từng bộ (`variations_by_event`) và `details_en` mô tả mọi bộ phụ.",
              "- Dòng `PALETTE` của mọi prompt tự đủ ý: nhóm không được ghi 'xem bảng màu của khu' hay 'giống nhóm khác'. Khi một nhóm dùng màu của nhóm khác, "
              "spec ghi `{palette:<group_id>}` và script chép nguyên danh sách màu (kèm mã hex) của nhóm đó vào từng prompt; file có thể có `palette_en` riêng.",
              "- Prompt không được dẫn tới tài liệu mà công cụ vẽ không mở được ('plan 10', 'fx1', 'pixel-art bible 7', 'gdd', 'docs/...', 'section 6.10', "
              "mã yêu cầu R<n>, mã quyết định D-<nn>, mã cảnh S<nn>): luật phải được viết thẳng trong prompt, nếu không build thất bại.",
              "- Cảnh báo (không chặn): tên file kiểu cặp đôi (`pair`, `both`...), mô tả một đống/nhóm vật rời (`pile`, `scatter`, `heap`...; vật ghép mà chính nó là MỘT vật, ví dụ đống đổ nát, thì đánh dấu `compound_ok` kèm lý do) hoặc ảnh lớn hơn 128x96 (trừ logo, icon ứng dụng, bàn tay của bé).",
              "- Khi dùng `--check-fonts <thư mục gốc repo>`: font đã giao trong `assets/fonts` phải phủ đủ bộ ký tự tiếng Việt, nếu không build thất bại.", ""]
    lines += ["### Ngoại lệ của kiểm tra", ""]
    for note in RELAXED_VI:
        lines.append("- %s" % note)
    lines.append("")
    return "\n".join(lines)


# --------------------------------------------------------------------------- output

def safe_to_wipe(out_dir, spec_dir, gitignore_path):
    """True when the whole out folder may be deleted (it holds nothing but generated files)."""
    out = out_dir.resolve()
    if out == Path(out.anchor) or out == Path.home().resolve():
        return False
    protected = [spec_dir.resolve(), SCRIPT_PATH, Path.cwd().resolve()]
    if gitignore_path is not None:
        protected.append(Path(gitignore_path).resolve())
    for item in protected:
        try:
            item.relative_to(out)
            return False  # the out folder contains something that must survive
        except ValueError:
            pass
    if (out / ".git").exists():
        return False
    return True


def clean_output(out_dir, spec_dir, gitignore_path):
    if out_dir.exists():
        if safe_to_wipe(out_dir, spec_dir, gitignore_path):
            shutil.rmtree(out_dir)
            mode = "wiped and recreated"
        else:
            shutil.rmtree(out_dir / "requests", ignore_errors=True)
            for name in ("README.md", "STYLE.md", "by-milestone.md", "asset-manifest.json"):
                target = out_dir / name
                if target.exists():
                    target.unlink()
            mode = "regenerated in place (the folder also holds the spec, so only generated files were replaced)"
    else:
        mode = "created"
    out_dir.mkdir(parents=True, exist_ok=True)
    return mode


def write_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def manifest_record(entry, include_prompt):
    record = OrderedDict()
    for key in ("id", "category", "group_id", "kind", "media", "title_vi", "path", "folder", "name", "needed_by",
                "priority", "placeholder", "size", "anchor", "block_px", "tile_data", "is_frame", "clip", "frame",
                "frames", "loop", "fps", "pose", "what_en", "event_id", "duration_s", "take", "take_count", "audio",
                "used_in", "notes_vi", "reference_files", "group_title_vi", "group_file", "acceptance", "opaque",
                "avoid_profile", "source", "coverage"):
        record[key] = entry.get(key)
    if include_prompt:
        record["prompt"] = entry["prompt"]
    return record


def write_manifest(path, entries, stats, include_prompt):
    path.parent.mkdir(parents=True, exist_ok=True)
    summary = {
        "total": stats["total"], "groups": stats["groups"],
        "by_category": dict(stats["by_category"]), "by_kind": dict(stats["by_kind"]),
        "by_priority": dict(stats["by_priority"]),
        "by_milestone": {k: stats["by_milestone"][k] for k in sorted_milestones(stats["by_milestone"])},
    }
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write('{\n"version": 1,\n"generator": "tools/asset_requests/build_requests.py",\n')
        handle.write('"prompts_included": %s,\n' % ("true" if include_prompt else "false"))
        handle.write('"counts": %s,\n' % json.dumps(summary, ensure_ascii=False))
        handle.write('"entries": [\n')
        last = len(entries) - 1
        for index, entry in enumerate(entries):
            handle.write(json.dumps(manifest_record(entry, include_prompt), ensure_ascii=False))
            handle.write(",\n" if index != last else "\n")
        handle.write("]\n}\n")


def write_outputs(out_dir, style, groups, entries, stats, spec_link, include_prompt):
    entries_by_group = defaultdict(list)
    for entry in entries:
        entries_by_group[(entry["category"], entry["group_id"])].append(entry)
    for group in groups:
        key = (group["category"], group["group_id"])
        write_text(out_dir / group["group_file"], render_group_file(group, entries_by_group[key]))
    write_text(out_dir / "requests" / "INDEX.md", render_index(groups, entries_by_group))
    write_text(out_dir / "by-milestone.md", render_by_milestone(entries, stats))
    write_text(out_dir / "STYLE.md", render_style_md(style))
    write_text(out_dir / "README.md", render_readme(style, groups, stats, spec_link))
    write_manifest(out_dir / "asset-manifest.json", entries, stats, include_prompt)


# --------------------------------------------------------------------------- main

def default_repo_root():
    parents = SCRIPT_PATH.parents
    if len(parents) > 2 and (parents[2] / "docs").is_dir():
        return parents[2]
    return None


def print_summary(stats):
    def line(title, counter, order=None):
        keys = order if order is not None else sorted(counter, key=lambda k: (-counter[k], str(k)))
        print("%-12s %s" % (title, "  ".join("%s=%d" % (k, counter[k]) for k in keys)))
    print("TOTAL files=%d  groups=%d  (images=%d of which animation frames=%d, audio=%d, fonts=%d, sourced glyphs=%d)" % (
        stats["total"], stats["groups"], stats["by_media"]["image"], stats["frames"], stats["by_media"]["audio"], stats["by_media"]["font"],
        stats["by_media"]["sourcing"]))
    line("category", stats["by_category"], CATEGORIES)
    line("kind", stats["by_kind"])
    line("priority", stats["by_priority"], PRIORITIES)
    line("milestone", stats["by_milestone"], sorted_milestones(stats["by_milestone"]))


def main(argv=None):
    root = default_repo_root()
    parser = argparse.ArgumentParser(description="Build the owner-facing asset request list.")
    parser.add_argument("--spec", help="folder with style.json and the five category specs "
                                       "(default: <repo>/docs/assets/spec)")
    parser.add_argument("--out", help="output folder (default: <repo>/docs/assets)")
    parser.add_argument("--gitignore", help="the repo .gitignore used for the 'no path in an ignored folder' check "
                                            "(default: <repo>/.gitignore)")
    parser.add_argument("--skip-gitignore-check", action="store_true", help="do not check paths against .gitignore")
    parser.add_argument("--slim-manifest", action="store_true", help="leave the prompt text out of asset-manifest.json "
                                                                      "(it is about as large as all the Markdown together)")
    parser.add_argument("--quiet", action="store_true", help="only print problems")
    parser.add_argument("--self-test", action="store_true",
                        help="do nothing else: prove that the 1x1 pixel-scale lint catches 2x2 blocks, chunky art, half-size grids "
                             "and the other stale phrases, and spares plain cell counts, then exit 0 (or 1 on a miss)")
    parser.add_argument("--check-font", nargs="+", metavar="FONT",
                        help="do nothing else: check that each .ttf/.otf covers the full Vietnamese set (reads the font's cmap table, "
                             "the table FontFile.has_char reads) and exit 1 when a character is missing")
    parser.add_argument("--check-fonts", metavar="REPO_ROOT",
                        help="while building, also run the Vietnamese coverage check on every font of the fonts_ui group that already "
                             "exists under <REPO_ROOT>/assets/fonts (fonts not delivered yet are skipped); a failing font fails the build")
    args = parser.parse_args(argv)

    if args.self_test:
        return run_pixel_scale_lint_self_test()
    if args.check_font:
        return run_font_check(args.check_font)

    # Outside a repo checkout (for example while the spec still lives in /tmp/asset_spec) the script falls back to the
    # folder it sits in: that folder is the spec, its sibling "asset_requests" is the output.
    standalone_spec = SCRIPT_PATH.parent if (SCRIPT_PATH.parent / "style.json").is_file() else None

    def pick(value, relative, label, fallback):
        if value:
            return Path(value).expanduser()
        if root is not None:
            return root / relative
        if fallback is not None:
            return fallback
        parser.error("%s not given and this script is not inside a repo checkout; pass --%s" % (label, label))

    spec_dir = pick(args.spec, "docs/assets/spec", "spec", standalone_spec)
    out_dir = pick(args.out, "docs/assets", "out", spec_dir.parent / "asset_requests" if standalone_spec else None)
    gitignore_path = None
    if not args.skip_gitignore_check:
        if args.gitignore:
            gitignore_path = Path(args.gitignore).expanduser()
        elif root is not None:
            gitignore_path = root / ".gitignore"
        elif (Path.cwd() / ".gitignore").is_file() and (Path.cwd() / "docs" / "game-base-plan.md").is_file():
            gitignore_path = Path.cwd() / ".gitignore"  # run from the project root
        else:
            print("note: the .gitignore check is skipped (no --gitignore given and the working folder is not the project root)", file=sys.stderr)

    problems = Problems()
    style, specs = load_specs(spec_dir, problems)
    gitignore_rules = None
    if gitignore_path is not None:
        if gitignore_path.is_file():
            gitignore_rules = parse_gitignore(gitignore_path.read_text(encoding="utf-8"))
        else:
            problems.error("cannot read .gitignore at %s" % gitignore_path)
    if style is None or problems.errors:
        return report_failure(problems)

    groups, entries = build_entries(style, specs, problems)
    validate(style, groups, entries, gitignore_rules, problems)
    lint_specs(style, specs, problems)
    lint_pixel_scale(style, specs, entries, problems)
    if args.check_fonts:
        for font in owner_font_paths(args.check_fonts):
            try:
                missing, _soft = check_font_file(font)
            except (FontReadError, OSError) as exc:
                problems.error("font %s: %s" % (font, exc))
                continue
            if missing:
                problems.error("font %s lacks %d required Vietnamese/ASCII characters: %s" % (font, len(missing), format_codepoints(missing, 12)))
    if problems.errors:
        return report_failure(problems)

    stats = collect_stats(groups, entries)
    out_resolved = out_dir.resolve()
    spec_link = None
    direction = spec_dir.resolve() / "direction.md"
    if direction.is_file() and out_resolved in direction.parents:
        spec_link = os.path.relpath(direction, out_resolved)

    mode = clean_output(out_dir, spec_dir, gitignore_path)
    write_outputs(out_dir, style, groups, entries, stats, spec_link, not args.slim_manifest)

    if not args.quiet:
        print("output %s: %s" % (mode, out_dir))
        print_summary(stats)
        if problems.warnings:
            print("warnings (%d):" % len(problems.warnings))
            for item in problems.warnings[:20]:
                print("  - " + item)
        print("relaxed validations:")
        for note in RELAXED:
            print("  - " + note)
        print("validation OK")
    return 0


def report_failure(problems):
    print("VALIDATION FAILED: %d problem(s)" % len(problems.errors), file=sys.stderr)
    for item in problems.errors[:200]:
        print("  - " + item, file=sys.stderr)
    if len(problems.errors) > 200:
        print("  ... and %d more" % (len(problems.errors) - 200), file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
