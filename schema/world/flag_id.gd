class_name FlagId
extends RefCounted

## How a world flag id is spelled (docs/game-base-plan.md 14.2, WorldFlags): lowercase words joined by `_`, in
## groups joined by `.`, so a flag reads as `boss.knight_captain` or `prompt.move`. One definition, so a lock, a
## state variant and a trigger all spell flags the same way and a typo is caught where it is written.

## A flag id: one lowercase word, then any number of `.group` parts. Digits and `_` may follow the first letter.
const PATTERN := "^[a-z][a-z0-9_]*(\\.[a-z0-9_]+)*$"


static func is_valid(flag_id: StringName) -> bool:
	return RegEx.create_from_string(PATTERN).search(String(flag_id)) != null
