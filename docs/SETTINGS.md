# Small Following settings - 2026-10-03

## Scope and decision status

Requested: a settings page containing sound controls and a fullscreen toggle,
plus an extra key mapping tab and a fix for horizontal arrow movement.
Implemented on the Godot 4.2.2 / Compatibility baseline. Separate channel
sliders, saved preferences, Esc/F11 shortcuts and the layout below are local
implementation choices. Keyboard/gamepad traversal, gamepad rebinding and further
accessibility settings remain outside this pass. No export or publishing is
included; browser fullscreen behavior needs separate exported verification.

## Screen brief

The player's decision is how loud the game should be, whether to use the
whole display, and which keys to use. The primary action is to adjust a control,
then return to play. A centered violet panel has **Sound & display** and
**Key mapping** tabs, with a persistent
Back to game button and the requested Exit Game button. Scrollable contents keep both actions reachable on
shorter viewports. Percentage labels and switch positions show current values.
Save status appears below the controls. The village or ritual remains visible
behind a dimmed backdrop; no upgrade information is duplicated here.

The key tab presents action names beside primary/alternate buttons. Its list
scrolls independently, keeping capture feedback, Restore default keys, navigation
help and the footer visible. Click a binding, press a key, and read the new label
or conflict message. Esc or Cancel key choice cancels; changing tabs or closing
settings also cancels. These layout and conflict policies are implementation
choices, while the additional tab and arrow correction were requested.

The small Settings button appears below the village counters and in the ritual
header's unused right-hand space. It disappears while the page is open.

## Transitions and controls

| Action | Result |
| --- | --- |
| Settings button / Esc | Opens over the current village or ritual |
| Back to game / Esc | Closes and returns to the underlying current phase |
| Exit Game | Attempts to flush preferences and progression, then closes the desktop game |
| Tab between rounds | Closes settings and reveals the village |
| Fullscreen switch / F11 by default | Toggles the actual game window mode |
| M / V by default | Toggles all audio / speech; switches stay synchronized |
| Assigned movement keys / left stick | Continues direct movement |

The scene tree and timer keep running. If time expires, the ritual opens
underneath settings. Enter/U cannot start a hidden round or purchase an upgrade
while settings is open. The backdrop blocks clicks reaching the ritual graph.
Settings controls leave movement input active and release keyboard focus from
the underlying ritual. The timer behavior is explained on the page.

## Keyboard mapping

Four movement directions, next round, buy upgrade, mute all, mute speech and
fullscreen each have a required primary key and an optional alternate. Defaults
come from `project.godot`: WASD/arrows, Enter, U, M, V and F11. Left and Right
now use the engine's correct physical key codes; End no longer moves the cultist.
Existing gamepad events remain on the same Input Map actions.

Assignments use single physical keys, so letter labels describe keyboard
positions. Modifier chords, duplicate assignments and reserved Esc/Tab are
rejected with a message; the previous binding remains. Clear removes only an
alternate. To exchange occupied keys, first move one action to an unused key.
Restore default keys resets all nine actions without changing audio/display.

Esc remains settings/back and cancels an active key choice first. Tab remains
village/ritual navigation; between rounds it cancels capture and reveals the
village. Captured keys cannot trigger one-shot game shortcuts. Direct movement
and round time continue even during capture, as stated on the page. HUD,
ritual and sound/display shortcut hints follow changed keys. Settings and graph
controls still use the mouse; keyboard/gamepad UI traversal is future work.

Exit Game (requested 2026-10-03) shares the fixed footer with Back to game and
has no keyboard shortcut, so Esc continues to mean return. Exiting preserves
the existing fresh-round-on-relaunch policy. Save writes use the existing
failure policies and are best effort; quitting does not bypass validation.
In browser builds the exit button is disabled with a tooltip explaining that
the browser tab must be closed instead; the game cannot close a user-owned tab.

## Sound and display rules

Master, music, footsteps and speech sliders range from 0% to 100%. Their
defaults preserve the prior mix. Effective channel gain is master times
channel volume, applied relative to the existing baseline dB level. Zero
silences a channel; mute switches retain chosen volumes for unmuting.
Music playback continues while muted and while browsing settings.

Fullscreen restores the saved preference on native startup. Browser startup
does not automatically request fullscreen: it must follow a user gesture.
The switch reflects actual window mode, including external fullscreen exits.
No resolution, rendering backend or export setting is changed.

## Storage and ownership

`settings_store.gd` validates `user://settings.json`, separately from
progression. It stores four finite 0-1 volumes and boolean mute/fullscreen
preferences plus optional `key_bindings`: all nine supported action IDs, each
with two integer key codes (zero means an unassigned alternate). Validation
rejects missing/unknown actions, malformed slots, nonintegral or unknown
codes, duplicate assignments and reserved keys before applying anything.

Schema 1 shipped the original six `values` keys; schema 2 (2026-10-07)
validates only the keys actually present in a saved file and defaults any
absent one from `DEFAULTS` on load, so adding a new preference cannot by
itself invalidate an existing file. Saving always writes the current schema
with every key populated. `CURRENT_SCHEMA` in `settings_store.gd` is the single
place that both bounds and names the accepted range; raise it again the same
way the next time a new key needs defaulting.

Saves stage and reread a temporary file before promoting it, retaining a
valid prior file as `.bak`. A damaged main can recover from backup; the
damaged original is preserved as `.corrupt` before a later save, and an
existing `.corrupt` file is left untouched rather than overwritten by a second
incident, mirroring `progression.gd`'s recovery-archive policy. Unsupported
future versions or unrecoverable files are preserved and writes blocked, with
a notice that adjustments last this session. Ordinary write failures also show
a notice.

Changes apply immediately, save after 0.4 seconds without further edits and
flush on closing settings or exiting the scene. `game_audio.gd` owns actual
volume application; `settings_screen.gd` emits user intents; `main.gd`
coordinates saving and actual window mode. `key_bindings.gd` validates physical
keys, supplies project defaults and replaces only keyboard Input Map events.
`settings_store.gd` owns binding edits. No economy or progression schema changes.
Isolated scenes disable preference persistence alongside progression; save
integration scenes require a separate explicit settings path to enable it.

## Acceptance and remaining evidence

Verify sliders, mute shortcuts, preference recovery, visible notices, movement,
round expiry, Tab return, hidden-action protection and actual fullscreen/window
transitions. Render the page over village and ritual at base and compact sizes.
`tests/test_key_mapping.gd` checks physical movement events, capture/conflicts,
shortcut dispatch, restart, old preferences, malformed saves and recovery.
`tests/test_settings.gd` additionally checks the schema-2 migration: a
schema-1 file missing a newer key defaults it instead of failing, a present
but out-of-range key still fails, a migrated file saves forward at the
current schema, and an existing `.corrupt` file blocks a second overwrite.
The display run additionally clicks the actual binding control. For targeted
captures, run `tests/capture_starter.gd` with `--settings-only` after `--`.
See [verification](VERIFICATION.md) for measured results and limitations.
