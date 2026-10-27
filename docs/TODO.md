# Small Following commercial readiness

Reviewed 2026-10-17 from source and release configuration. This is a static
review; no fresh export, runtime session, storefront review, or player playtest
was completed.

## Confirmed release direction

- Complete story through the hilltop abbey and the Pope encounters.
- Steam release at $5. Base currency is not yet specified.
- Owner confirms all bundled audio, icon/art, and toolkit assets are cleared for
  commercial use.

## Assessment

- The project implements all six areas, ending with the hilltop abbey and the
  Pope, and exports Web and Windows. The abbey has not been played by a person
  yet, only by a bot and by screenshots.
- Progression and preferences have separate saves, and purchases persist before
  spending. Those systems still need release-build and recovery verification.
- The Steam listing, final Windows build, and supported OS/device list were not
  reviewed in this pass.

## Agent work

### Complete the campaign

- [x] Draft the abbey plan: the procession (everyone won walks to the Pope and
  pleads), built and recorded in `docs/MAP_ROADMAP.md`.
- [x] Implement the abbey as area six: world and audiences, balance data, a
  36-node local circle, the Pope, travel gate, and save schema 8 (schema 7 saves
  load unchanged).
- [x] Add the Pope and the final campaign ending; title level selection,
  catalogs and access validation know the abbey; the ending shows only after the
  Pope is won.
- [x] Rosecourt's completion copy reflects the King's state. The old demo-ending
  copy is gone from Bramblewick's circle.
- [ ] Play the abbey by hand and retune `abbey.pope.conviction`, the plea
  strengths and the helper stats. A bot with a full circle wins at about 24 of 30
  seconds; a circle without its last tier falls short (95%); followers alone
  reach about a third.
- [ ] Resolve the 20-phrase-per-second speech cap question in
  `docs/MAP_ROADMAP.md`. Quillmoor's later talking ranks can be clipped while
  Rosecourt turns excess rate into stronger phrases. Make the rule consistent
  across maps and update balance data and previews.

### Prepare the Steam release

- [ ] Replace the prototype project description with copy for the complete
  campaign. Add Steam-specific build metadata alongside the existing WebHatchery
  and itch settings; do not break those existing targets.
- [ ] Create a reproducible, version-labeled Windows Steam build/package and
  document the SteamPipe inputs an owner must supply. Keep uploads and store
  changes separate from local build preparation.
- [ ] Check shipped third-party license terms and include any required notices.
  The owner has confirmed commercial clearance for the bundled assets.
- [ ] Build and launch a release candidate from one commit. Manually check the
  campaign from a fresh save through the Pope ending, return play, purchases,
  save recovery, keyboard/gamepad navigation, window resizing, and Steam launch
  behavior. Record build hashes and OS/Steam client versions; do not publish.
- [ ] Prepare Steam store copy and a review checklist for screenshots, trailer,
  content description, supported platforms, accessibility notes, support
  contact, and the $5 price.

## Release metadata still needed

- Version label and release date.
- Base currency for the $5 price.
- Supported Steam operating systems beyond the current Windows export.
- Support contact.

Project constraint: do not add automated test suites or fixtures. Follow
`AGENTS.md` for parse/import and visual/runtime verification.
