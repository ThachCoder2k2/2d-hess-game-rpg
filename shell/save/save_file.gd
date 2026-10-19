class_name SaveFile
extends RefCounted

## The bytes of a save file (docs/game-base-plan.md 9.3): how a ConfigFile gets onto the disk without a
## crash or a full disk ever leaving a half-written save behind, and how a file that was damaged anyway is
## recognised BEFORE anything tries to parse it. Pure file work: it knows nothing about what a save
## contains, and nothing outside shell/save/ calls it (SaveService is its one user;
## tests/architecture/test_save_written_only_by_save_service.gd holds that).
##
## A save file is the text of a ConfigFile followed by one comment line, the integrity footer:
##
##     [meta]
##     version=3
##     ...
##     ; integrity sha256=<hex digest of every byte above this line>
##
## The footer is a ConfigFile comment, so the file stays a plain ConfigFile that any reader and any
## editor opens. Its job is the damaged file: a truncated, zeroed or garbled file fails the digest check
## and is reported as damaged. ConfigFile.load() on such a file prints an engine ERROR line and gives up
## with no reason, which is why the check comes first and the parser only ever sees text that was
## written by encode(). A file with no footer (hand-written, or written by the retired WorldState) is
## damaged to this class; the one reader of those, the v2 migration, uses read_unchecked().
##
## Writing is write-temp, verify, keep the old one as .bak, rename:
##   1. the new text goes to <path>.tmp and is read back and verified;
##   2. the current file, if it is a good save, becomes <path>.bak (a damaged one becomes <path>.corrupt
##      instead, so it can never push a good .bak out);
##   3. <path>.tmp is renamed to <path>.
## A crash between 2 and 3 leaves no <path>, the previous save as <path>.bak and the NEW save, complete and
## verified, as <path>.tmp. The loader must not fall back to the .bak and forget the .tmp: it is the player's
## latest progress. read_unfinished_write() hands the loader that .tmp when it is not older than the .bak, and
## finish_unfinished_write() completes step 3 by rename, so the disk is back to the ordinary layout. A crash
## before step 2 leaves the old file in place and a .tmp nobody needs: the old file wins and the next write
## overwrites the .tmp. The file a newer game wrote is never replaced (write returns ERR_LOCKED).

const TEMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"
const DAMAGED_SUFFIX := ".corrupt"
const INTEGRITY_PREFIX := "; integrity sha256="

const META_SECTION := "meta"
const VERSION_KEY := "version"

## read() found a file that passes the integrity check and parses.
const STATUS_READABLE := &"readable"
## read() found no file at all.
const STATUS_MISSING := &"missing"
## read() found a file that fails the integrity check or does not parse.
const STATUS_DAMAGED := &"damaged"


## What read() found at a path.
class Reading:
	extends RefCounted

	## One of the STATUS_ constants above.
	var status: StringName = STATUS_MISSING
	## The parsed file; set only when the status is STATUS_READABLE.
	var config: ConfigFile = null
	## The format version the file declares in [meta], or -1 when it cannot be found. Filled in
	## for a damaged file too (when its [meta] text can still be read), because a file written by a NEWER
	## game may fail this build's integrity check and must still be recognised as newer, not as garbage.
	var version := -1
	## Why the status is not readable, in words for the log. Empty when it is readable.
	var reason := ""

	func is_readable() -> bool:
		return status == STATUS_READABLE


## The text of `config` as it is written to disk: the ConfigFile text and its integrity footer.
static func encode(config: ConfigFile) -> String:
	var body := config.encode_to_text()
	if not body.ends_with("\n"):
		body += "\n"
	return body + INTEGRITY_PREFIX + body.sha256_text() + "\n"


## Reads the file at `path` as the reverse of encode(). Never prints an engine error and never throws.
static func read(path: String) -> Reading:
	var reading := Reading.new()
	if not FileAccess.file_exists(path):
		reading.reason = "no file at %s" % path
		return reading
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		reading.status = STATUS_DAMAGED
		reading.reason = "cannot open %s (error %d)" % [path, FileAccess.get_open_error()]
		return reading
	var bytes := file.get_buffer(file.get_length())
	file.close()
	if not is_valid_utf8(bytes):
		# Decoding such bytes as text would print a line of engine error for every bad byte (dozens for a zeroed or
		# random file), so a file that is not text is reported here, in one sentence, before anything decodes it.
		reading.status = STATUS_DAMAGED
		reading.reason = "%s is not text (it holds bytes no text can hold: damaged or not written by the game)" % path
		return reading
	var text := bytes.get_string_from_utf8()
	reading.version = version_declared_in(text)

	var footer_start := text.rfind("\n" + INTEGRITY_PREFIX)
	if footer_start == -1:
		reading.status = STATUS_DAMAGED
		reading.reason = "%s has no integrity footer (empty, truncated or not written by the game)" % path
		return reading
	var body := text.substr(0, footer_start + 1)
	var recorded_digest := text.substr(footer_start + 1 + INTEGRITY_PREFIX.length()).strip_edges()
	if recorded_digest != body.sha256_text():
		reading.status = STATUS_DAMAGED
		reading.reason = "%s fails its integrity check (damaged after it was written)" % path
		return reading
	var config := ConfigFile.new()
	if config.parse(body) != OK:
		reading.status = STATUS_DAMAGED
		reading.reason = "%s passes its integrity check but does not parse" % path
		return reading
	var declared: Variant = config.get_value(META_SECTION, VERSION_KEY) if config.has_section_key(META_SECTION, VERSION_KEY) else null
	if not (declared is int or declared is float):
		reading.status = STATUS_DAMAGED
		reading.reason = "%s declares no [meta] version" % path
		return reading
	reading.version = int(declared)
	reading.config = config
	reading.status = STATUS_READABLE
	return reading


## Whether `bytes` are well-formed UTF-8 (what the game writes, since a save is the text of a ConfigFile): every
## lead byte is a real one, each is followed by the continuation bytes it needs, and no sequence is a longer form of a
## shorter one, a surrogate or past U+10FFFF. A file is a few kilobytes, so the walk costs nothing.
static func is_valid_utf8(bytes: PackedByteArray) -> bool:
	var index := 0
	var size := bytes.size()
	while index < size:
		var lead := bytes[index]
		if lead < 0x80:
			index += 1
			continue
		var continuation_count := 0
		var lowest_second := 0x80
		var highest_second := 0xBF
		if lead >= 0xC2 and lead <= 0xDF:
			continuation_count = 1
		elif lead >= 0xE0 and lead <= 0xEF:
			continuation_count = 2
			if lead == 0xE0:
				lowest_second = 0xA0
			elif lead == 0xED:
				highest_second = 0x9F
		elif lead >= 0xF0 and lead <= 0xF4:
			continuation_count = 3
			if lead == 0xF0:
				lowest_second = 0x90
			elif lead == 0xF4:
				highest_second = 0x8F
		else:
			return false
		if index + continuation_count >= size:
			return false
		var second := bytes[index + 1]
		if second < lowest_second or second > highest_second:
			return false
		for offset in range(2, continuation_count + 1):
			if (bytes[index + offset] & 0xC0) != 0x80:
				return false
		index += continuation_count + 1
	return true


## Reads a ConfigFile that carries no footer (the v2 WorldState save at user://world_state.cfg, which
## predates it). The one caller is the v2 migration. A file the parser rejects prints the engine's own
## error line; nothing the game writes ever takes this path.
static func read_unchecked(path: String) -> Reading:
	var reading := Reading.new()
	if not FileAccess.file_exists(path):
		reading.reason = "no file at %s" % path
		return reading
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK:
		reading.status = STATUS_DAMAGED
		reading.reason = "%s does not parse (error %d)" % [path, load_error]
		return reading
	var declared: Variant = config.get_value(META_SECTION, VERSION_KEY, 0)
	reading.version = int(declared) if (declared is int or declared is float) else 0
	reading.config = config
	reading.status = STATUS_READABLE
	return reading


## What an interrupted write left as <path>.tmp (see the class comment), for the loader to use when <path> is
## missing or damaged: the .tmp's reading when it exists and is not older than the .bak. A .tmp is always
## written after the file that became the .bak, so equal modification times (the clock counts whole seconds, and
## two saves can fall in the same second) mean the .tmp is the newer. A .bak that cannot be read cannot be newer
## than anything, so it never keeps a good .tmp out. The returned reading may be damaged or from a newer game:
## the loader judges it like any other file. A reading with STATUS_MISSING means there is nothing to recover.
static func read_unfinished_write(path: String) -> Reading:
	var temp_path := path + TEMP_SUFFIX
	var temp := read(temp_path)
	if temp.status == STATUS_MISSING:
		return temp
	var backup_path := path + BACKUP_SUFFIX
	if read(backup_path).is_readable() and FileAccess.get_modified_time(temp_path) < FileAccess.get_modified_time(backup_path):
		return Reading.new()
	return temp


## Finishes an interrupted write: <path>.tmp becomes <path> by rename, step 3 of write(). A damaged file in the
## way is set aside as .corrupt first (never deleted, never allowed to push a good .bak out). Returns OK or the
## error; whatever happens nothing is deleted.
static func finish_unfinished_write(path: String) -> Error:
	if FileAccess.file_exists(path):
		set_aside(path, DAMAGED_SUFFIX)
	return DirAccess.rename_absolute(path + TEMP_SUFFIX, path)


## The version a file's [meta] section declares, found in the raw text, or -1. Used on text that may be
## damaged or from a newer game, so it never parses.
static func version_declared_in(text: String) -> int:
	var meta_start := text.find("[%s]" % META_SECTION)
	if meta_start == -1:
		return -1
	var pattern := RegEx.create_from_string("(?m)^%s\\s*=\\s*(-?\\d+)\\s*$" % VERSION_KEY)
	var found := pattern.search(text, meta_start)
	return int(found.get_string(1)) if found != null else -1


## Writes `config` to `path` the safe way (see the class comment). Creates the folder. Returns OK, ERR_LOCKED
## when the file there was written by a newer format than this config (never replaced), or the error of the
## step that failed; whatever happened, the file at `path` is either the old save or the new one.
static func write(path: String, config: ConfigFile) -> Error:
	var made := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if made != OK:
		return made
	var current := read(path)
	var writing_version := int(config.get_value(META_SECTION, VERSION_KEY, 0))
	if current.version > writing_version:
		return ERR_LOCKED

	var temp_path := path + TEMP_SUFFIX
	var temp_file := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		return FileAccess.get_open_error()
	temp_file.store_string(encode(config))
	var store_error := temp_file.get_error()
	temp_file.close()
	if store_error != OK:
		DirAccess.remove_absolute(temp_path)
		return store_error
	if not read(temp_path).is_readable():
		DirAccess.remove_absolute(temp_path)
		return ERR_FILE_CORRUPT

	if current.status != STATUS_MISSING:
		var keep_as := path + (BACKUP_SUFFIX if current.is_readable() else DAMAGED_SUFFIX)
		var kept := DirAccess.rename_absolute(path, keep_as)
		if kept != OK:
			DirAccess.remove_absolute(temp_path)
			return kept
	var renamed := DirAccess.rename_absolute(temp_path, path)
	if renamed != OK:
		DirAccess.remove_absolute(temp_path)
	return renamed


## Moves the file at `path` out of the way to `path + suffix`, replacing an earlier one with that name,
## so nothing is deleted. True when there was a file and it moved.
static func set_aside(path: String, suffix: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	return DirAccess.rename_absolute(path, path + suffix) == OK
