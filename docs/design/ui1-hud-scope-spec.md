# UI.1 Spec - HUD Scope

**Status:** draft for owner review  
**Linked lane:** UI, UX, And Tutorial  
**Checklist gate:** `UI.1`

## Purpose

The HUD should tell the player only what they need to make decisions. It should
never cover the active combat grid.

## Required HUD Elements

| Element | First Chain? | Purpose |
|---|---:|---|
| Courage / health | yes | Shows remaining mistakes allowed |
| Equipped weapon | yes | Confirms sword/pickup state |
| Skill cooldown | later | Needed when Pencil/Rule Step unlocks |
| Believe / child help | foreshadow later | Needed when child intervention unlocks |
| Status prompt | yes | Short contextual guidance |
| Enemy count | optional | Useful for room-clear objective |
| Rule Book prompt | later | Review enemy rules |

## First-Chain HUD Rule

Keep the first-chain HUD minimal:

```text
Courage
Current weapon
Short status prompt
Optional enemy count
```

Do not show child meter before the child system matters.

## Tutorial Text Rules

- Prompts should be short.
- Prompts should teach one thing at a time.
- Prompts should not interrupt active combat.
- Control prompts should disappear once learned.

## Completion Requirements

`UI.1` can be approved only if:

- the HUD scope is minimal and useful,
- first-chain HUD does not reveal future systems too early,
- prompts support learning without long text,
- and UI never covers combat-critical cells.

## Cannot Approve If

- HUD becomes a dashboard of unused systems,
- tutorial text pauses the opening too often,
- important prompts are unclear,
- or UI hides the battlefield.

