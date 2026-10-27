# Map roadmap

The order of maps and the one new mechanic each one teaches. Bramblewick,
Bellmarket, the Lantern Fair, Quillmoor, Rosecourt and the abbey are implemented;
the abbey is the final map. The plans for the implemented maps were retired
once built (they remain in Git history); `data/balance.json` and
`data/upgrades.json` are the source of truth for their numbers.

| # | Map | New mechanic | Final person to convince | State |
| --- | --- | --- | --- | --- |
| 1 | Bramblewick (village) | Debate opponents and their villagers | Priest of Bramblewick | Implemented |
| 2 | Bellmarket (market) | Locked listeners opened by introductions; the amber Market Hand | - | Implemented |
| 3 | The Lantern Fair | Interest against Distraction: a hard threshold with many ways over it, fast drain, stolen audiences; the moss-green Barker | The Ringmaster | Implemented |
| 4 | Quillmoor University | Prepared arguments: academics only hear their own faculty's argument | The Rector | Implemented |
| 5 | Rosecourt (the King's garden) | Whispered introductions: who you win first opens who listens next | The King | Implemented |
| 6 | The hilltop abbey (final map) | The procession: everyone won walks to the Pope and pleads for you, and he is moved only by those advocates | The Pope | Implemented |

Each map asks a different question:

- **Bellmarket:** what have you bought?
- **The fair:** are you interesting enough?
- **Quillmoor:** did you bring the right argument?
- **Rosecourt:** who have you already talked to today?
- **The abbey:** who will stand beside you?

Story thread: winning the King gives the cultist his approval to go before
the Pope. Beyond the story it has one effect: the Pope takes his seat only for
a pilgrim who has it, and who has mastered every follower inscription (the
helper, Market Hand, Barker, Teaching Assistant and Page nodes, and the abbey's
own Company). The Pope's ears stay closed until enough of the won stand before
him, and only they move him until then, so no cultist reaches him alone. His
conviction, the advocates he needs and every plea are in `data/balance.json`
("abbey"). A full abbey circle is needed to win; the abbey's round is 30 seconds.
Winning him shows the campaign's ending.

Shared rules for every new map:

- **One new mechanic.** Each map introduces one.
- **Opening without new upgrades.** Easy opening groups convert with the
  build carried in, before any of the map's own upgrades.
- **Bosses.** Four, in Bramblewick's pattern, where the map has bosses.
- **Upgrade circle.** Each map has its own purple circle of about 36 nodes.
- **Local effects.** The map's effects apply only on that map.
- **Access.** A map opens from the previous map's completed circle. The
  password list shows every implemented area.

Open question for the user: every gathering and boss caps speech at 20
phrases a second. Rosecourt alone turns speech above the cap into heavier
phrases; earlier maps keep the plain cap, so Quillmoor's last talk ranks
are still partly clipped.
