# Title image

Generated with the built-in imagegen tool on 26 October 2026. The Alchemy Tower
example supplied by the owner informed the level of painterly detail; each scene
was composed for this game's setting and live menu. Text remains native Godot UI.

Asset: `assets/art/ui/title_screen.png`. Original artwork remains preserved.

## Generation prompt

Use case: stylized-concept. Original polished hand-painted title background for Small Following, wide landscape 16:9 1920x1080. A tiny friendly mysterious cultist with broad soft purple robe, tall pointed hood and two warm golden eyes in a dark face opening, at LEFT foreground on a village cobbled lane, speaking animatedly to a handful of curious townspeople of varied ages, each a distinct silhouette. Cozy timber houses, bunting, flower pots and lanterns, a market and university roofs in background, twilight plum sky. A subtle chalk occult circle and a few lavender motes around robe hem, whimsical mischievous social magic, no horror or menace, no sacrifice or combat. Premium storybook illustration with richly painted architecture and foliage, velvet purple, lavender, warm gold, soft cinematic light. Main figure x=24%, town and listeners on left 55%; RIGHT 40 percent soft dark purple shaded trees and wall with quiet low-detail space for live menu. Leave upper-left sky calm enough for live heading. No text, letters, logo, UI, borders or watermark. Save image locally and return path.

## Integration and verification

- The title uses this project-local image with aspect-preserving cover scaling.
- Text, focus, settings, saves and start actions remain native Godot UI.
- Godot 4.7.2 headless editor import completed successfully.
- Silent automated windowed capture ran on the OpenGL Compatibility renderer;
  the rendered title was visually inspected at one fixed size.
- Capture: `docs/verification/title.png`. Reproduce with
  `Godot --path . --audio-driver Dummy --script res://tools/capture_title.gd`.
- `-- --details` also captures `title_new_game.png`; the expanded creator or
  save-replacement confirmation was inspected without starting over or saving.
- Capture exited with code 0 and reported ObjectDB/resource cleanup warnings
  during shutdown. These remain unresolved; title rendering succeeded.
- No gameplay simulation suite, export, browser/touch pass or human playtest
  was run for this title-art change. Nothing was pushed or published.
