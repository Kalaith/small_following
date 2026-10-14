# Map roadmap

The order of maps and the one new mechanic each one teaches. Bramblewick,
Bellmarket, the Lantern Fair, Quillmoor and Rosecourt are implemented. The abbey is
next and not yet planned. The plans for the implemented maps were retired
once built (they remain in Git history); `data/balance.json` and
`data/upgrades.json` are the source of truth for their numbers.

| # | Map | New mechanic | Final person to convince | State |
| --- | --- | --- | --- | --- |
| 1 | Bramblewick (village) | Debate opponents and their villagers | Priest of Bramblewick | Implemented |
| 2 | Bellmarket (market) | Locked listeners opened by introductions; the amber Market Hand | - | Implemented |
| 3 | The Lantern Fair | Interest against Distraction: a hard threshold with many ways over it, fast drain, stolen audiences; the moss-green Barker | The Ringmaster | Implemented |
| 4 | Quillmoor University | Prepared arguments: academics only hear their own faculty's argument | The Rector | Implemented |
| 5 | Rosecourt (the King's garden) | Whispered introductions: who you win first opens who listens next | The King | Implemented |
| 6 | The hilltop abbey (final map) | Not yet planned | The Pope | - |

Each map asks a different question:

- **Bellmarket:** what have you bought?
- **The fair:** are you interesting enough?
- **Quillmoor:** did you bring the right argument?
- **Rosecourt:** who have you already talked to today?

Story thread: winning the King gives the cultist his approval to go before
the Pope. It is story only and carries no stat or unlock.

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
