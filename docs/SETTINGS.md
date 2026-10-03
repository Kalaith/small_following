# Small Following settings - 2026-10-03

## Scope and decision status

Requested: a settings page containing sound controls and a fullscreen toggle.
Implemented on the Godot 4.2.2 / Compatibility baseline. Separate channel
sliders, saved preferences, Esc/F11 shortcuts and the layout below are local
implementation choices. Keyboard/gamepad traversal, rebinding and further
accessibility settings remain outside this pass. No export or publishing is
included; browser fullscreen behavior needs separate exported verification.

## Screen brief

The player's decision is how loud the game should be and whether to use the
whole display. The primary action is to adjust a control, then return to play.
A centered violet panel contains Sound and Display sections, with a persistent
Back to game button and the requested Exit Game button. Scrollable contents keep both actions reachable on
shorter viewports. Percentage labels and switch positions show current values.
Save status appears below the controls. The village or ritual remains visible
behind a dimmed backdrop; no upgrade information is duplicated here.

The small Settings button appears below the village counters and in the ritual
header's unused right-hand space. It disappears while the page is open.

## Transitions and controls

| Action | Result |
| --- | --- |
| Settings button / Esc | Opens over the current village or ritual |
| Back to game / Esc | Closes and returns to the underlying current phase |
| Exit Game | Attempts to flush preferences and progression, then closes the desktop game |
| Tab between rounds | Closes settings and reveals the village |
| Fullscreen switch / F11 | Toggles the actual game window mode |
| M / V | Toggles all audio / speech; switches stay synchronized |
| WASD / arrows / left stick | Continues direct movement |

The scene tree and timer keep running. If time expires, the ritual opens
underneath settings. Enter/U cannot start a hidden round or purchase an upgrade
while settings is open. The backdrop blocks clicks reaching the ritual graph.
Settings controls do not capture movement arrows or leave keyboard focus on
the underlying ritual. The timer behavior is explained on the page.

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

`settings_store.gd` validates schema-1 `user://settings.json`, separately from
progression. It stores four finite 0-1 volumes and boolean mute/fullscreen
preferences. Saves stage and reread a temporary file before promoting it,
retaining a valid prior file as `.bak`. A damaged main can recover from backup;
the damaged original is preserved as `.corrupt` before a later save. Unsupported
versions or unrecoverable files are preserved and writes blocked, with a notice
that adjustments last this session. Ordinary write failures also show a notice.

Changes apply immediately, save after 0.4 seconds without further edits and
flush on closing settings or exiting the scene. `game_audio.gd` owns actual
volume application; `settings_screen.gd` emits user intents; `main.gd`
coordinates saving and actual window mode. No economy or save schema changes.
Isolated scenes disable preference persistence alongside progression; save
integration scenes require a separate explicit settings path to enable it.

## Acceptance and remaining evidence

Verify sliders, mute shortcuts, preference recovery, visible notices, movement,
round expiry, Tab return, hidden-action protection and actual fullscreen/window
transitions. Render the page over village and ritual at base and compact sizes.
See [verification](VERIFICATION.md) for measured results and limitations.
