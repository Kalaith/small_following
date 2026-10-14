# Quillmoor University: the fourth map - proposal, 2026-10-14

## 0. Scope and decision status

- **Confirmed (user, 2026-10-14):**
  - **Map order:** Bramblewick, Bellmarket, the
    [Lantern Fair](LANTERN_FAIR_PLAN.md), **Quillmoor University**,
    [Rosecourt](ROSECOURT_PLAN.md), then the abbey as the final map.
  - **Theme:** academics and people who are very good at debating.
  - **Mechanic: prepared arguments** (option B of the first draft).
  - **Four bosses:** the Debate Captain, the Logician, the Astronomer and the
    Rector. The name **Quillmoor** is kept.
- **Provisional:** each boss's habit, the faculty list, slot counts, layout,
  thresholds, prices and round counts. Numbers go in `data/balance.json` and
  `data/upgrades.json`; the game reads them from there.
- **Entry build:** everything from the village, market and fair carries in.
  Fair-only effects (Interest, stages) stay at the fair.
- **Not in scope:** changes to earlier maps, Rosecourt's whispers, the
  abbey.

## 1. High concept

The cult's growing reputation has reached Quillmoor, and the academics are
not impressed. You can't win over a logician with poetry, or a chaplain with
star charts. Before each round the cultist **prepares their case**, choosing
which kinds of argument to bring, and then routes through the parts of the
university that case can win.

Each map so far has asked a different question:

| Map | Its question |
| --- | --- |
| Bellmarket | What have you bought? |
| The fair | Are you loud enough? |
| Quillmoor | Did you bring the right argument? |
| Rosecourt | Who have you already talked to today? |

Quillmoor is the first map where the key decision is made **before** the
round.

## 2. The mechanic: prepared arguments

### Faculties and arguments

| Faculty | Moved by | Example academics | Where |
| --- | --- | --- | --- |
| Logic | **Proof** | Logician, mathematician | Old Court |
| Natural Philosophy | **Evidence** | Astronomer, alchemist | New Court, observatory |
| Theology | **Scripture** | Chaplain, theologian | Chapel, New Court |
| Rhetoric | **Eloquence** | Orator, debating students | Debating chamber, Old Court |

Students, porters and staff have **no faculty**. They listen to any argument
and keep repeatable income open, as Bellmarket's open listeners do.

### Argument slots

- The cultist has **argument slots**: one at the start, up to four with
  Quillmoor upgrades.
- Between rounds, on the ritual screen, the player fills the slots by
  tapping argument cards. Changing them costs nothing.
- The chosen loadout is remembered for the next round, so a player who
  doesn't want to change anything just presses Next round.

### During the round

- Speech stays automatic. An academic whose faculty is in the loadout
  listens normally.
- An academic whose faculty isn't prepared **rebuts everything**. They show a
  crossed-out speech bubble with their faculty icon, and the cultist's
  phrases move on to the next listener who can be won.
- Unprepared academics are **skipped**, exactly as Bellmarket's locked
  listeners are skipped. They never block the rest of the group, and they
  bank no conviction. This reuses the existing eligibility rule; the
  difference is that eligibility comes from this round's loadout, not a
  permanent purchase.
- Groups mix students with academics from one or two faculties. Every group
  is partly workable with any loadout, and fully workable only with the right
  one.
- The helper uses the same loadout.

### The decision

With one slot you can work one corner of the university well. Pick Proof and
the Old Court logicians open up; pick Scripture and the chapel does. Each new
slot visibly opens another route, so each purchase changes the route rather than only a number.
With all four, you can sweep the campus. Even then, the faculty strength
upgrades (section 5) make a focused case pay more.

### Readability

- Each academic wears a small **faculty badge** (scroll, star, candle,
  quill), with shape and text, not colour alone.
- The HUD shows the current loadout as the same badges.
- Inspecting an academic shows, for example, "Logician - needs Proof (not
  prepared)".
- On the ritual screen, each argument card lists how many academics in the
  university it opens, so the choice is informed.

## 3. Bosses

Bosses work like Bramblewick's debate opponents. They arrive in order, each
an encounter with a big conviction requirement, a habit, a reward and
followers who join as ordinary listeners from the next round. Each one
**demands particular arguments**.

| Order | Boss | Needs prepared | Habit | Followers |
| --- | --- | --- | --- | --- |
| 1 | **The Debate Captain** | Eloquence | Answers the first phrases of each visit (rebuttals), like the Town Guard | Debating students (Eloquence) |
| 2 | **The Logician** | Proof | Highest rebuttals so far: patient, precise, hard to start | Logic students (Proof) |
| 3 | **The Astronomer** | Evidence **and** Proof | Loses conviction while unattended (decay), drifting back to the stars | Stargazers (Evidence) |
| 4 | **The Rector** (finale) | **All four** | Rebuttals and decay, like the Priest; arrives late | - |

- The Astronomer is the first boss who needs two slots, so the player must
  have bought a second slot and give up flexibility to face him.
- The Rector needs every slot filled with every argument. The finale
  requires the full slot path, and winning it means walking into the
  observatory with nothing else in the loadout.
- Winning the Rector is the university's lasting victory. Its completed
  circle opens Rosecourt.

## 4. Layout

| Place | Feel | Faculties |
| --- | --- | --- |
| Gatehouse Lawn | Students, porters, a bookseller; the easy opening | None (anyone listens) |
| Old Court | Lecturers between classes | Logic, Rhetoric |
| Library Walk | Long covered path of shelves linking the courts | Mixed, a few of each |
| New Court | Lawns around the chapel and laboratories | Natural Philosophy, Theology |
| Debating chamber | Off Old Court; the Debate Captain | Rhetoric |
| Observatory | Tower at the top of the map; the Rector | Natural Philosophy; finale |

The Gatehouse can be cleared with the carried build and no Quillmoor ranks,
as at the fair. Old Court and New Court sit on opposite sides, so a
one-slot loadout means choosing a side.

## 5. Economy and progression

- **Opening target:** the carried build clears the Gatehouse students, plus
  the academics of one prepared faculty that sit close to it.
- **Circle:** about 36 nodes in six paths with its own seal (an astrolabe /
  open book motif in the purple palette):
  - **Commonplace Book:** argument slots 2, 3 and 4, spread through the path
    so each costs more.
  - **Mastery:** per-faculty conviction or donation bonuses, rewarding a
    focused case.
  - **Teaching Assistant:** the helper's reach and pace at Quillmoor.
  - **Running**, **phrase frequency** and **conviction**, the familiar three.
- Quillmoor effects apply only at Quillmoor.
- **Access:** completing the fair's circle adds *Travel to Quillmoor*.
  Quillmoor's completed circle opens Rosecourt. The password list shows every
  implemented area.
- **Saves:** add `"university"` to `AREA_IDS` with a schema bump. Store the
  loadout as a validated list of argument IDs. On load, if it holds more
  arguments than owned slots, or unknown IDs, drop the extras rather than
  rejecting the save. Boss progress is stored like encounter progress,
  scoped to the area.
- **Pacing target:** about as long as Bellmarket, judged by playing.

## 6. Implementation notes

- **`gathering.gd`:** add a `faculty` field per slot. Extend the existing
  eligibility check (the one Bellmarket's locks use) with "faculty is empty
  or in the loadout". It stays inside the recruitment authority, so the
  player and helper can't bypass it.
- **`progression.gd`:** owns the loadout, validates it against owned slots,
  saves it, and exposes it to `main.gd` and `helper.gd`.
- **`ritual_screen.gd`:** a row of argument cards beside the circle. It emits
  a "set loadout" intent only; progression decides. Cards must work by
  keyboard, mouse, touch and pad.
- **`encounter.gd`:** a "needs arguments" list per boss, checked like the
  faculty rule, plus the existing rebuttal and decay habits.

## 7. Delivery slices

| Slice | Outcome | Check by playing |
| --- | --- | --- |
| 1. Faculty rule | Faculty on academics, a loadout, player and helper, on a greybox | Matching academics convert; unprepared ones are skipped and bank nothing; students always listen; the helper obeys the loadout |
| 2. Loadout UI and save | Argument cards on the ritual screen; loadout saved | Cards work by keyboard, mouse, touch and pad; an over-full or unknown loadout is trimmed on load; slots come from purchases |
| 3. Area and travel | Greybox campus, schema bump, travel from the completed fair and on to Rosecourt | Travel both ways; an old save still loads; a failed save keeps the current area |
| 4. Roster and circle | Groups in `balance.json`, about 36 nodes | The Gatehouse converts with no Quillmoor ranks; each slot opens new routes |
| 5. Bosses | Debate Captain, Logician, Astronomer, Rector | Required arguments, habits, order and followers; the Rector can be won with all four prepared |
| 6. Pacing | Tune prices and thresholds | Quillmoor takes about as long as Bellmarket |

This branch carries no tests and agents must not add any (see
`AGENTS.md`). Check each slice by running the game (`Run.ps1`, plus
`--headless --editor --quit` as an import/parse check) and playing the
checks above, using a password start to reach the map quickly. Earlier
maps must play as before.

## 8. Set aside

- **Public debates:** academics push conviction back while you talk, and
  students watching a won debate gain conviction. The spectator idea could
  return later as a Quillmoor upgrade on top of prepared arguments.
- **Library evidence:** books picked up in the stacks clear objections.
  Rejected because of the risk of fetch-quest chores.

## 9. As built (2026-10-14)

All slices are implemented: `scripts/university.gd` (campus, props, people),
`uni_boss.gd` (the four bosses), `uni_hud.gd` (the prepared arguments),
`argument_badge.gd` (scroll, star, candle and quill badges),
`ritual_argument_cards.gd` (the cards), the faculty rule in `gathering.gd`,
schema 6 with `uni_stage` and `uni_loadout` in `progression.gd`, and 36
`university` nodes in `upgrades.json`. Where the build differs from the text
above:

- **Loadout:** it starts empty, so a first round with nothing prepared
  reaches only students and staff. Tapping a card while every slot is full
  replaces the earliest choice. Keys 1-4 toggle a card; a pad's bumpers move
  the highlight and Y toggles it. A key or button the player has bound to an
  action keeps that action.
- **Bosses** stand at their own spots from the first round, in order; no
  circle node unlocks them. A boss whose arguments are not all prepared
  rebuts everything, and gives way to any group the cultist can win nearby.
  The Rector arrives 3 seconds into the round.
- **Mastery** (one conviction node and one endowment node per faculty) also
  adds to the bosses who need that argument; the Commonplace Book's
  conviction nodes apply to everyone who needs a prepared argument.
- **Teaching Assistant** tunes the teal helper only (conviction, walking
  speed, phrase speed); no new helper joins at Quillmoor.
- **Opening tuning:** with the full village, market and fair build, a
  one-slot round earns about 720-830 donations and 23-24 recruits whichever
  argument is prepared (measured headlessly). The Debate Captain falls to
  the carried build in one round; the Rector was only tested with the full
  circle. The whole circle costs 59,800 donations. Pacing against
  Bellmarket has not been judged by playing yet.

## 10. Open decisions

None from the user at present. Faculty mixes per group, slot prices and boss
thresholds are settled in playtests.
