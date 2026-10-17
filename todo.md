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

- The project currently implements five areas and exports Web and Windows. The
  roadmap leaves the sixth and final area unplanned; the story and campaign are
  incomplete for the confirmed release direction.
- Progression and preferences have separate saves, and purchases persist before
  spending. Those systems still need release-build and recovery verification.
- The Steam listing, final Windows build, and supported OS/device list were not
  reviewed in this pass.

## Agent work

### Complete the campaign

- [ ] Draft the abbey plan in `docs/` using `docs/MAP_ROADMAP.md`: one distinct
  mechanic, an opening that works with the carried build, local progression,
  and the Pope as the final encounter. Treat any new mechanic as a proposal
  until accepted; make the King's approval open the audience with the Pope.
- [ ] Implement the abbey as area six: world and audiences, balance data, a
  bounded local upgrade circle, boss/encounter progression, travel gate, and
  save migration from schema 7. Preserve older saves and current area data.
- [ ] Add the Pope encounters and a clear final campaign ending. Update title
  level selection, progression catalogs and access validation for the abbey;
  show the final ending only after the Pope is defeated.
- [ ] Make Rosecourt's completion copy reflect the King's state: before victory,
  direct the player to win his approval; after victory, point to the abbey.
  Remove any remaining demo-ending copy from the full-game path.
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
