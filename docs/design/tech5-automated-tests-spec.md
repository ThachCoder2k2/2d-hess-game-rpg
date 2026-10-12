# TECH.5 Spec - Automated Tests

**Status:** draft for owner review  
**Linked lane:** Technical Architecture  
**Checklist gate:** `TECH.5`

## Purpose

Automated tests catch broken core systems while parallel production changes many
lanes at once.

## Required Coverage Areas

- project/import smoke check,
- movement/grid logic,
- combat/telegraph events,
- room transition graph validation,
- resource reference validation,
- critical scene boot checks.

## Completion Requirements

`TECH.5` can be approved only if tests cover core runtime risks and can be run
repeatably before owner review.

## Cannot Approve If

- tests only check files exist,
- room travel can break silently,
- or manual play is the only verification path.

