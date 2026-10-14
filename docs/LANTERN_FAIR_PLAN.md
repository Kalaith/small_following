# The Lantern Fair: the third map - proposal, 2026-10-14

## 0. Scope and decision status

- **Requested (user, 2026-10-14):** plan the fair as the next map.
  - The fair is full of distractions and interesting things to do. If the
    cultist isn't interesting enough, people won't listen: their pleas fall
    on deaf ears.
  - A few easier groups at the very start can be convinced without
    upgrades.
  - Add clowns and other performers. The last person to convince is the
    **Ringmaster**.
- **Confirmed (user, 2026-10-14):**
  - **"Without upgrades" means without fair upgrades.** The cultist arrives
    with the full village and market build, as Bellmarket balances around.
  - **Hard threshold.** For example, with Interest 10 against Distraction 11
    the cultist never makes progress, however long they talk. At 15 they do.
  - **Fast drain.** Walk away and a listener's conviction drops really fast.
  - **Clowns and performers are ordinary groups on the map.** The debate-style
    bosses follow Bramblewick's pattern: **Performer, Clown, Mime, Ringmaster**.
  - **The Mime needs the cultist to stand completely still.**
  - **The Ringmaster needs the cultist to move through hoops while staying in
    his speaking range.**
  - **The Ringmaster needs all three earlier bosses' Interest bonuses** to
    be heard.
  - **Many ways over the threshold:** Showmanship ranks, stages, converting
    performers, timing shows and bosses all count, so the player chooses how
    to take over the fair.
  - **Steal the audience:** performers gather nearby fair-goers into a crowd.
    Convert the performer, and that crowd is briefly easier to win.
  - **A new follower in moss green**, after Bramblewick's teal and
    Bellmarket's amber.
  - **Drain applies while deaf too**, even if the cultist stays put: the
    listener is watching the show instead.
  - **Map order:** Bramblewick, Bellmarket, the fair, the university
    ([UNIVERSITY_PLAN](UNIVERSITY_PLAN.md)), Rosecourt
    ([ROSECOURT_PLAN](ROSECOURT_PLAN.md)), then the abbey as the final map,
    where the last person to convince is the Pope.
- **Provisional:** every name, number, layout position and round count below.
  Numbers go in `data/balance.json` / `data/upgrades.json`; the game reads
  them from there.
- **Not in scope:** changes to Bramblewick or Bellmarket, Rosecourt's whisper
  mechanic, idle income, prestige, a new art pipeline.

## 1. High concept

A travelling lantern fair has set up in the fields outside Bellmarket. There
are strings of lanterns, a carousel, game stalls, food carts and a striped big
top in the middle. Everyone is busy having fun. The little cult has to be
**more interesting than the fair** before anyone stops to listen, and has to
keep them listening, because the moment the cultist walks off they wander
back to the fun.

Map 2 asked "is this person allowed to listen?". The fair asks "**is this
person paying attention to you?**".

## 2. The mechanic: Interest against Distraction

### The two numbers

- The cultist has an **Interest** rating. It rises with fair upgrades, stages
  and convinced bosses (below). The carried build gives a base value, set so
  the Ticket Gate is already reachable.
- Every fair group has a **Distraction** rating, set by what is around it: a
  family at the ticket gate has almost none, while a crowd beside the carousel
  has a lot.

### The rule (hard threshold)

- **Interest >= Distraction:** speech works normally.
- **Interest < Distraction:** phrases **fall on deaf ears**. The cultist
  still speaks, but listeners show a little "..." or glance away, and no
  conviction is gained. Being short by one point is the same as being short
  by ten. Nothing else is lost, and the cultist is never stopped.

The threshold is checked on every phrase, so an Interest change during a
round takes effect at once. Stepping onto a stage, or a show ending, can open
a group immediately.

### Distracted again: fast drain

- Fair listeners don't keep their place. A fair-goer whose conversation stops
  **loses partial conviction fast**: starting point 4 conviction per second,
  roughly twice a Bramblewick Devotee's rate.
- Drain applies whenever the listener isn't receiving phrases that count.
  That covers walking out of range, the helper retargeting, or turning deaf
  mid-conversation because the cultist stepped off a stage or a show started.
- Converted listeners stay converted for the round. Only partial progress
  drains.

Together the two rules mean the fair rewards **committing**: get loud enough,
then stay until the person is won. Hopping between groups loses everything
that was half done.

### Many ways over the threshold (confirmed)

The threshold stays hard, but a gap should never leave "farm donations until
the next rank" as the only answer. If the player can see the carousel crowd
but can't reach it, there should be several ways to close the gap. Choosing
between them is how each player takes over the fair. Starting values:

| Action | Effect | Lasts |
| --- | --- | --- |
| Buy a Showmanship rank | +2 Interest | Permanent |
| Stand on a stage | +3 Interest | While on the stage |
| Convert nearby performers (clowns, jugglers, acrobats) | -2 local Distraction | Rest of the round |
| Wait for a performance to finish | -3 Distraction (the show's +3 ends) | Until the next show |
| Steal the audience (below) | A further -3 for the stolen crowd | A few seconds |
| The Barker (moss-green follower) works the group | -1 Distraction for that group | While the Barker speaks there |
| Convert a headline performer (a boss) | +1 Interest | Permanent |

At a busy crowd the choice is: save for an upgrade, use a stage, remove the
performers distracting it, or time the shows. The threshold never moves; the
player's decisions do.

- **Stages.** Crates, a bandstand and a busker's spot sit around the fair.
  Groups within a stage's reach can be spoken to from it. Stand on the stage
  near the big crowds, or walk to the quiet groups.
- **Shows.** Performer groups run shows on a fixed, signposted schedule. A
  bell rings and lights flash, and while the show runs, nearby Distraction is
  +3. Gate and Food Row groups are never in a show cycle, so there is always
  someone to talk to.
- **Performers.** Clown, juggler and acrobat groups are both attractions and
  audiences (section 3). Converting one ends their act for the round, so
  Distraction around them drops by 2 until the next round.

### Steal the audience (confirmed)

- **Gathering a crowd.** When a performer's show bell rings, nearby
  fair-goers and lone wanderers within a set radius walk over and form a
  ring of spectators. This reuses the wanderer pull from Bramblewick's
  Beckoning Call. While watching, the crowd has the show's +3 Distraction.
- **Stealing it.** Convert the performer while their crowd is gathered and
  the show stops mid-act. The crowd turns to the cultist and is **stolen**:
  for a short window (starting point 4 s) their Distraction drops 3 below
  normal. Their bars show a small sparkle and a countdown ring.
- **Afterwards.** When the window ends, they return to normal Distraction and
  drift back to the lanes. Anyone recruited during the window stays recruited.
- **The chain reaction:** convert the juggler, then sweep the crowd that was
  watching. Better still, start on the juggler just before the bell, so the
  crowd has gathered by the time the juggler is won. Followers can work a
  stolen crowd too.
- **Bosses with shows** (the Performer, and the Ringmaster's ring) also gather
  crowds. Winning one mid-show steals the biggest audience of all.

### Permanent Interest

- **Showmanship upgrades:** Bright Robes, Tambourine, Sparkler Sigils and so
  on, +2 each.
- **Convinced bosses** join the act (section 4): +1 each, and each quietens
  their own corner for the rest of the save.

### Readability

- Each group shows its Distraction as a number with **lantern pips**. The HUD
  shows the cultist's current Interest the same way, including any stage
  bonus. If you have fewer lanterns than they do, they won't hear you.
- Deaf-ears feedback appears on the listeners themselves (the "..." and
  glance), not only as a colour change. A draining bar visibly shrinks.
- Inspecting a group shows, for example, "Distraction 11 (carousel) - your
  Interest 10" without spending time.

### Followers: the Barker joins (confirmed)

Each map adds a follower in a new robe colour. Bramblewick has the teal
helper, and Bellmarket has the amber Market Hand (implemented).
The fair adds a **moss-green follower, the Barker**.

- **The Barker** is a fair-only follower unlocked from the fair's circle.
  - **Recruiting:** like the others, it walks to listeners and recruits them,
    with its own Interest, pace and conviction from `balance.json`.
  - **Working the crowd:** drawing a crowd is its trade. While it speaks to a
    group, that group's Distraction is 1 lower for everyone, including the
    cultist.
  - **Teaming up:** sending the Barker to a group just above your Interest and
    joining it there is one more way over the threshold.
- **The teal helper** travels to the fair, as it does to Bellmarket, with its
  own small Interest. **The amber Market Hand** stays in Bellmarket, since its
  upgrades are scoped there.
- Every follower uses the same threshold and drain rules. Quiet groups suit
  the teal helper, and the Barker suits the edge of a busy crowd.

## 3. Clowns and performers on the map

Clowns and performers are **ordinary groups** placed around the fair, not
encounters. Each is both an attraction and an audience.

| Group | Where | As an attraction | As an audience |
| --- | --- | --- | --- |
| Clowns (3-4) | Midway | Raise Midway Distraction while performing | High Distraction; good donations |
| Jugglers | Juggling stage | Run the stage's show schedule | Can only hear you between shows |
| Acrobats | Near the carousel | Raise carousel-side Distraction | High thresholds |
| Stilt-walkers | Wander the lanes (`wanderers.gd`) | Raise Distraction where they pass | Single listeners to catch |

Converting a performer group **ends their act for this round**, which lowers
Distraction around them by 2. If their crowd is gathered at that moment, the
crowd is **stolen** (section 2). This is the fair's version of "who first?":
win the jugglers just as their show starts, then sweep the crowd that was
watching. Like every audience, performers reset next round.

## 4. Bosses: Performer, Clown, Mime, Ringmaster

Bosses work like Bramblewick's debate opponents. Each is an encounter with a
big conviction requirement, a habit, a donation reward and a lasting effect
once won, and they arrive in order. Each also has a Distraction value, so the
cultist must be interesting enough to be heard at all. Because every fair
listener already drains fast, bosses drain faster still.

| Order | Boss | Habit (reuses existing rules where possible) | Once convinced |
| --- | --- | --- | --- |
| 1 | **The Performer** (headline busker) | Show schedule: deaf to you while performing, open between acts | +1 Interest; stage bonus +1 |
| 2 | **The Head Clown** | Pranks: answers the first phrases of each visit with a honk (rebuttals) | +1 Interest; Midway Distraction drops for good |
| 3 | **The Mime** | Speaks only in gestures: gains conviction only while the cultist stands completely still, and drains fastest of the first three | +1 Interest; the mime troupe stops miming at the crowds, so lane Distraction drops |
| 4 | **The Ringmaster** (finale) | Highest Distraction; listens only right after the cultist goes through a hoop inside his range; fastest drain | Lasting victory; the fair's finale |

The Mime's rule asks the player to stop and commit, which is the fair's
whole lesson in its purest form. Any movement input that moves the cultist
breaks the gesture: his phrases stop counting and his conviction starts to
drain. The game never stops the cultist; the player chooses to stand.

- Each boss brings **new fans** as ordinary fair-goers from the next round, as
  Bramblewick's opponents bring Doubters, the Town watch and Devotees.
  Examples: busker's crowd, clown fans who honk back, mime watchers who only
  listen while you stand still.
- **The Ringmaster** stands in the centre ring with the Distraction of the
  whole show behind him. You need nearly the full Showmanship path and all
  three earlier bosses' bonuses to be heard at all; his Distraction is tuned
  so that missing any one of them leaves you short. Then you have to **put on a
  show**:
  - Hoops stand around the ring, all inside his speaking range. One hoop is
    lit at a time, and the next lights when it is used, so the path is shown
    rather than guessed.
  - Running through the lit hoop earns a "Bravo!". For a short window after
    it (starting point 1.5 s) the Ringmaster hears your phrases normally.
  - Outside that window he is deaf and drains, as is leaving his range. So
    you keep circling the ring from hoop to hoop without straying out of
    range.
  - He is the Mime's opposite: the Mime wants you still, the Ringmaster wants
    you moving. Running speed and phrase frequency both matter in the finale.
  - Hoops are markers on the ground, not collision, and never move or steer
    the cultist. Missing one only costs time.

## 5. Layout and groups

Radial lanes around the big top, as first sketched for the fair in the
original level roadmap.

| Place | Distraction | Notes |
| --- | --- | --- |
| Ticket Gate | At or below the carried base | Entrance: tired parents, ticket queue, a lantern seller. **Convinced with no fair upgrades.** |
| Food Row | Base + 1-2 | Pie cart, cider stall. Opens after one or two Showmanship ranks or from a stage. |
| Midway Games | Base + 3-5 | Ring toss, coconut shy, the clowns |
| Carousel | Base + 5-7 | Busy and loud; acrobats; a stage just outside |
| Juggling stage | Base + 4-6 (shows) | Opens and closes with the schedule |
| Big top ring | Highest | The Ringmaster. Endgame only |

Start with about six fair-goer groups of four or five, the performer groups
above and a few lone wanderers. The two Ticket Gate groups are the opening
route. Gate fair-goers have low thresholds and small donations, so the first
fair upgrade comes within a couple of rounds.

| Role | Examples | Notes |
| --- | --- | --- |
| Fair-goer | Parent, child, farmhand, sweetheart | Ordinary thresholds; Distraction comes from their location |
| Stallholder | Pie seller, ring-toss keeper | Higher donation; next to their own attraction |
| Performer | Clown, juggler, acrobat, stilt-walker | Attraction and audience (section 3) |
| Boss's fans | Clown fans, mime watchers | Arrive after their boss is convinced |

## 6. Economy and progression

- **Opening target:** the carried build converts the gate groups and nothing
  past Food Row until the first Showmanship rank or a stage.
- **Circle:** about 36 nodes with its own seal (a striped tent / carousel
  motif in the same purple palette). Paths:
  - **Showmanship:** Interest.
  - **Stagecraft:** stage bonus and stage reach.
  - **Captivating:** slower drain on the listener you just left.
  - **Fair Followers:** unlock the moss-green Barker, then its pace, its
    Distraction reduction and the teal helper's fair Interest.
  - **Showstopper:** a longer stolen-audience window and a wider crowd
    radius.
  - **Running**, **phrase frequency** and **conviction**, the familiar three.
- Each Showmanship rank should open a visibly new part of the fair, so a
  purchase changes the route rather than only a number.
- Fair effects apply only at the fair. Village and market stats and the helper
  travel in.
- **Access:** completing Bellmarket's circle adds a deliberate *Travel to the
  fair* action at its centre. The fair's completed centre offers continued
  play and return. The password list shows every implemented area.
- **Saves:** add `"lantern_fair"` to `AREA_IDS` with a schema bump (5). Boss
  progress is stored like village encounter progress, scoped to the fair.
  Interest from bosses is derived from that progress, not stored separately.
  Stage, show, deaf and drain state are transient.
- **Pacing target:** about as long as Bellmarket, judged by playing.

## 7. Implementation notes

- **`gathering.gd`:**
  - Add `distraction` and an "is hearing" check next to the existing
    eligibility check, inside the recruitment authority, so neither the
    player nor the helper can bypass it.
  - Deaf phrases add no conviction and bank no overflow.
  - Add per-listener drain while not receiving counted phrases. Bramblewick's
    Devotee decay is the model.
- **`main.gd`:**
  - Compute current Interest (base + upgrades + bosses + stage) on each
    phrase.
  - Pick the nearest group that can hear you, so a deaf crowd nearby doesn't
    steal speech from a quiet group in range.
- **Shows:** a schedule per attraction in `balance.json`, on a deterministic
  clock from round start so routes are repeatable. A converted performer
  group cancels its own show for the round.
- **Stages:** areas in the fair scene giving an Interest bonus and a speaking
  reach override while the player stands inside.
- **Bosses:** reuse `encounter.gd` habits (rebuttals, decay) and add the
  Distraction check. New habits:
  - The Performer uses the show schedule.
  - The Mime counts phrases only while the player's velocity is zero.
  - The Ringmaster counts phrases only during a window opened by crossing
    the lit hoop. Hoops are `Area2D` triggers in the ring, positioned inside
    his speaking range in `balance.json`.
- **Followers:** extend `helper.gd`, as it already does for the amber
  Market Hand, with a moss-green robe and a `fair.helper.moss` block in
  `balance.json`. Every follower uses the same hearing check and drain. The
  Barker's -1 is a local Distraction modifier on the group it targets.
- **Steal the audience:** each performer group gets a crowd radius and a show
  schedule. On the bell, the existing wanderer pull walks nearby fair-goers
  over. On conversion mid-show, `gathering.gd` marks the gathered listeners
  as stolen until the window ends. The window runs on the same deterministic
  round clock as the shows.

## 8. Delivery slices

| Slice | Outcome | Check by playing |
| --- | --- | --- |
| 1. Hearing rule | Distraction on groups, Interest on the cultist, deaf phrases and drain; a few sample groups on a greybox | One point short gives no progress; deaf phrases bank no overflow; bars drain fast when you leave or go deaf; the teal helper obeys both |
| 2. Stages, shows, performers | One stage, one show and one performer group with a crowd | The stage bonus switches at its edge; shows keep time; converting performers lowers local Distraction by 2; converting mid-show steals the crowd for the window and no longer |
| 2b. The Barker | Moss-green follower | It recruits under the same rules; its group is 1 less distracted while it speaks; it can work a stolen crowd |
| 3. Area and travel | Greybox fair, schema 5, travel from completed Bellmarket and back, password list | Travel both ways; an old save still loads; a failed save keeps the current area |
| 4. Roster and circle | Groups in `balance.json`, about 36 nodes in `upgrades.json` | The gate converts with no fair ranks; each Showmanship rank opens new groups |
| 5. Bosses | Performer, Head Clown, Mime, then fans arriving | Each habit (the Mime stops counting on any movement), the order, lasting effects, Interest from bosses |
| 6. Ringmaster and pacing | Hoops and the finale | Only the lit hoop opens the window; the window expires; leaving range drains; a route through the hoops wins; the fair takes about as long as Bellmarket |

This branch carries no tests and agents must not add any (see
`AGENTS.md`). Check each slice by running the game (`Run.ps1`, plus
`--headless --editor --quit` as an import/parse check) and playing the
checks above, using a password start to reach the map quickly. Earlier
maps must play as before.

## 9. As built (2026-10-14)

All slices are implemented: `scripts/fair.gd` (ground, props, stages,
hoops), `fair_director.gd` (round clock, shows, crowds, stolen windows,
Distraction), `fair_boss.gd` (the four headliners), `fair_hud.gd` (Interest
pips), hearing and drain in `gathering.gd` and `helper.gd`, schema 5 and
`fair_stage` in `progression.gd`, and 36 `lantern_fair` nodes in
`upgrades.json`. Where the build differs from the text above:

- **Ringmaster:** Distraction 19 = base 4 + all six Showmanship ranks + the
  three headliners. "Missing any one leaves you short" needs the *full*
  path, not "nearly" full.
- **Headliners** stand at their own spots from the first round, in order;
  no circle node unlocks them.
- **Crowds:** groups inside a running show's radius count as watching (+3);
  only lone fair-goers walk over on the bell. Stolen spectators stay where
  they are until the next round's scatter rather than drifting back.
- **The Performer** gathers a crowd (+3) but cannot be won mid-show, since
  he is deaf while performing, so he has no steal.
- **Drain** is a share of the current listener's threshold per second
  (`fair.drain_share_per_second`, 0.6); headliners drain at their own
  absolute rates. Captivating multiplies both.
- **Opening tuning:** with the full village and market build, a first round
  on the gate and lone fair-goers earns about 230 donations and 12 recruits
  (measured headlessly), so the first fair rank comes in round one.

## 10. Open decisions

None from the user at present. Tuning (Distraction values, drain rate, the
Bravo window) is settled in playtests.
