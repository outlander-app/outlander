# Outlander Macro Preferences UI Specification

This document captures the requirements for rebuilding Outlander's macro
preferences so they match the Avalon macOS client UX while fitting the existing
Outlander data model (`MacroLoader`, `#macro` commands, `macros.cfg` files).

## Menu Topology
- Update `App → Settings` menu to match Avalon:
  - `General Preferences…`
  - `Highlights…`
  - `Macros ▸` sub-menu with:
    - `A–Z Macros`
    - `Keypad Macros`
    - `Function Macros`
- Selecting any macro entry opens the corresponding editor window. The submenu
  stays open to allow quick switching.
- Keep “Choose Settings Directory…” elsewhere in the menu (current behaviour).

## Shared Window Chrome
- Each macro editor is a modal sheet or floating panel with:
  - Title reflecting the category (`A–Z Macros`, `Keypad Macros`, `Function Macros`).
  - Segmented control across the top for modifier groups (varies per category).
  - Editable table view with two columns: `Key` (static label) and `Macro`
    (editable text).
  - Footer help text (identical wording across screens):
    ```
    \n - Send the command.  \p - Pause 1 second before continuing.
    \x - Delete the contents of the command line before starting.
    @  - Place the insertion marker here when done.
    \? - Replace this with the contents of the command line before starting.
    ```
  - Primary button `OK` saves and dismisses. Provide `Cancel` if we choose a
    non-modal window.
- Reserved keys show `Reserved` in the Macro column and are read-only/greyed out.
- Changes are stored in-memory immediately, persisted only when the user clicks
  `OK`.

## A–Z Macros Window
- Keys: fixed list `A` … `Z` (26 rows).
- Modifier segments: `Command`, `Option`, `Control`. Each segment displays the
  macro assigned to `modifier + key`.
- Reserved keys (per Avalon: B, C, etc.) must block edits; display “Reserved”.
- Editing the Macro cell accepts plain text, supporting escape sequences listed
  above. Empty string means “no macro”.
- On save, apply changes to `GameContext.macros`, then call
  `MacroLoader.save(...)` to update `macros.cfg`.

## Keypad Macros Window
- Keys: keypad `+`, `-`, `/`, `*`, digits `0–9`, `.`, and optionally `enter`,
  `clear` if supported.
- Modifier segments: `None`, `Command`, `Option`, `Control`, `Shift`.
  - `None` shows macros for the unmodified key (movement commands in Avalon).
  - Other segments show the modifier+key variations.
- Macro column permits multiline sequences (entered using `\n`). Consider an
  inline multi-line editor or accept literal `\n` tokens.
- Saving mirrors the A–Z flow.

## Function Macros Window
- Keys: `Esc`, `F1`…`F12` (optionally extend to `F20` for full keyboards).
- Modifier segments: `None`, `Command`, `Option`, `Control`, `Shift`.
- Include a macro-set selector in the lower-right corner:
  - Drop-down labeled “Macro Set 1” with stepper arrows to switch between sets.
  - Support creating additional sets (e.g., “Macro Set 2”) and persisting each set
    independently.
  - Switching sets replaces the table contents with that set’s macros.
- Same help footer as other windows.

## Editing Workflow
- Table allows inline edits; pressing Return commits the value.
- Provide visual differentiation for populated rows (bold key label or icon).
- Validate entries on save:
  - Warn if an escape sequence uses an unknown flag.
  - Prevent edits on reserved keys.
- Offer optional `Revert`/`Cancel` to discard unsaved modifications.

## Data Model & Persistence Updates
- Extend `MacroLoader` and supporting structs to treat macros as:
  - Category (A–Z, Keypad, Function).
  - Modifier group (None/Command/Option/Control/Shift).
  - Key identifier.
  - Optional macro-set identifier (for Function Macros).
- Maintain backwards compatibility with existing `#macro` syntax:
  - Continue writing entries like `#macro {\u{2318}F1} {command}`.
  - Introduce metadata for macro sets if required (e.g., grouping entries by set name).
- Ensure UI updates trigger `MacroLoader.save(...)` so `#macro reload` and `#macro save`
  still operate correctly.
- After saving, re-register macros (`GameViewController.registerMacros`) so new
  bindings take effect immediately.

## Validation & UX Enhancements
- Display status text showing count of defined macros in the active view/set.
- Add search/filter box (optional, stretch goal).
- Consider tooltip or popover explaining escape sequences on hover.
- Log to the main window (`context.events2.echoText("Macros saved")`) when a save
  succeeds, matching CLI command feedback.

## Integration Checklist
1. Build reusable view controller handling segmented modifiers, table editing,
   and save/cancel.
2. Wire new menu commands to present each window.
3. Update `MacroLoader`/`GameContext` to expose data in a form convenient for the UI.
4. Add unit tests covering load/save with modifiers, sets, and reserved keys.
5. Confirm legacy `macros.cfg` loads without loss; verify upgraded file still
   works with `#macro reload`.
