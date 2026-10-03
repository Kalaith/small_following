# Small Following - commit style

Use a short subject in the game's voice with a clear technical tag. Keep the
language gentle and concrete: footsteps, listeners, donations and ritual
inscriptions already belong to this game. Plain wording is appropriate for
mechanical changes. The reader should understand the change immediately.

## 1. Subject

```text
<What changes for the village or cultist> (<plain technical tag>)
```

Use present tense, one line and no trailing period. Keep it concise; a forced
metaphor is less useful than a clear description. Avoid Conventional Commits
prefixes when following this style. The tag should identify the actual change,
such as `rank validation`, `cloth motion` or `Godot documentation`.

Examples below illustrate wording, not newly implemented features:

```text
The robe settles after the cultist stops (cloth motion)
One inscription buys one rank (stale purchase validation)
The village keeps its donations through a restart (save round trip)
The ritual reveals its distant circles (graph pan and zoom)
Document the village's Godot workflow (development guides)
```

Use project terms consistently:

| Technical concept | Game vocabulary |
| --- | --- |
| Player movement | Cultist, footsteps, running |
| Conversation and recruitment | Phrases, conviction, listeners |
| Currency | Donations |
| Upgrade graph and purchase | Ritual circle, node, rank, inscription |
| Save and recovery | Saved progression; use the plain term for precision |

## 2. Body

For a substantial change, explain the problem, resulting behavior and reason
in short paragraphs. Name relevant identifiers in backticks. Link or name the
actual design heading rather than inventing numbered sections.

State checks actually performed, their results and any unresolved limits.
Separate automated route evidence, rendered inspection and human playtesting.
Do not imply a clean import, export or human acceptance from script tests.
Wrap prose at roughly 76 columns when practical.

A commit concerning a partial feature should state its remaining scope. A
small mechanical change may need only the subject and brief verification.

## 3. Attribution

When recording AI co-authorship, use the correct tool/name and email supplied
by the working environment or user in a standard `Co-Authored-By:` trailer.
Do not copy the Rust reference's model identity or invent an address. Keep
trailers after a blank line and retain any existing project attribution policy.

## 4. Commit cadence

Make regular local commits as part of the development workflow. Commit each
complete, validated feature slice before starting the next slice, even when
the larger feature remains unfinished. Small fixes, tests, refactors and
documentation changes also deserve their own coherent commits.

A slice should have a clear outcome, include its related tests and docs, and
leave the project usable. For example, a new mechanic's validated data model,
runtime behavior and UI integration may be separate slices when each can
stand on its own. Describe remaining feature work in the commit body.

Keep experiments uncommitted until their outcome is understood. Do not commit
every edit or bundle several completed slices merely to wait for a milestone.
Run checks appropriate to each slice and report existing blockers honestly.
The user's explicit request to defer commits takes precedence over this cadence.

## 5. Scope and handoff

Before each commit:

- Review `git status --short` and the diff, including untracked files.
- Group an independently useful change with its relevant tests and docs.
- Stage only the intended task files. Preserve pre-existing work; do not sweep
  it into the commit or discard it to obtain a clean status.
- Keep secrets, runtime saves, caches and local exports out of the commit.
- Follow the user's branch instructions and current checkout context.
- Report the commit hash, verification and any remaining changes honestly.

Local edits and commits do not authorize pushing, publishing or remote setup.
