# Small Following commercial readiness

Reviewed 2026-10-17 from the project source and release configuration. This is a
static review: no fresh exports, runtime session, storefront review, or player
playtest was completed.

## Assessment

- The project has Web and Windows export presets, five implemented areas, saved
  progression and preferences, and settings for sound, movement, keyboard and
  gamepad input. Purchases write before charging.
- The current story is a five-area demo. The roadmap names the hilltop abbey and
  the Pope as the next and final map, but that map has no plan or implementation.
  The end-of-demo wording remains in the game. This is not ready to be described
  as a complete campaign until the release scope is settled.
- A source review cannot establish that either export loads, saves, or feels
  good on target devices. The release scripts and available ignored build output
  were not exercised or treated as current release evidence.
- No asset credits or license register was found in tracked project files. Asset
  ownership and permitted commercial use need to be recorded before sale.

## Agent work

### Release blockers

- [ ] Confirm the intended edition with the owner: release the five-area demo,
  or complete the campaign through the abbey and Pope. If it is the full game,
  draft the abbey plan under `docs/` using the shared rules in
  `docs/MAP_ROADMAP.md`, then implement its map, progression, ending, save
  migration, and title/level selection. Keep any unapproved mechanic provisional.
- [ ] Fix Rosecourt's completed-circle message after the King is won. The
  completion copy currently still tells the player to win his approval. Show a
  clear demo ending for a demo release, or the next destination/final ending for
  a complete campaign.
- [ ] Resolve the speech-rate cap question in `docs/MAP_ROADMAP.md`: Quillmoor's
  later talking ranks can be clipped at 20 phrases per second, while Rosecourt
  converts excess rate into stronger phrases. Make the rule intentional and
  update the balance data and player-facing previews consistently.
- [ ] Inventory every shipped asset and embedded third-party component, record
  its source, creator, license, and required notice, then add the applicable
  credits/notices to the project. Do not guess rights for entries with missing
  provenance; return those to the owner for confirmation.

### Release preparation

- [ ] Replace the prototype wording in `project.godot` and the generic
  `publish.json` description with copy that matches the approved edition. Add a
  release version and make the Web and Windows artifacts identify that version.
- [ ] Decide whether the title-screen travel password is an intentional player
  feature for the commercial edition. If it is review access, document that
  purpose and ensure it does not grant unintended persistent progression.
- [ ] Build Web and Windows candidates from the same commit with the pinned
  Godot 4.2.2 standard editor. Launch both and manually check a fresh save,
  return play, purchases, save recovery, keyboard/gamepad navigation, touch
  movement in Web, window resizing, and the final completion flow. Record build
  hashes and target/browser versions; do not publish as part of this work.
- [ ] Review the public storefront materials against the approved edition:
  screenshots, trailer, content description, supported platforms, accessibility
  notes, support contact, price, and refund terms. The storefront page was not
  reviewed in this pass.

## Owner decisions needed

- Is the commercial product the existing five-area demo or a complete story
  through the abbey and Pope?
- Which price, version, release date, supported browser/device list, and support
  contact should the storefront and build metadata use?
- Are all bundled audio, icon/art, and toolkit assets cleared for commercial use?

Project constraint: keep the game free of automated test suites and test
fixtures. Follow `AGENTS.md` for parse/import and visual/runtime verification.
