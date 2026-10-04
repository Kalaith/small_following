# Publishing Small Following

Run from this project in PowerShell. The scripts follow the Rust publisher's
environment conventions, using Godot exports and a separate itch.io entry point.

```powershell
.\publish.ps1 -DryRun                 # Show preview destination; no writes
.\publish.ps1                         # Build Web + Windows and deploy preview
.\publish.ps1 -Production             # Copy to local production (-p)
.\publish.ps1 -FTP                    # Copy to production and upload live
.\publish.ps1 -BuildOnly              # Export/package without deploying
.\publish.ps1 -SkipBuild -FTP         # Publish the last verified build
.\publish-itch.ps1 -DryRun            # Offline plan using the completed build
.\publish-itch.ps1 -Preview           # Compare against itch; no upload
.\publish-itch.ps1                    # Push HTML5 and Windows channels
.\publish-itch.ps1 -Channel html5     # Push only the browser game
.\publish-itch.ps1 -Status            # Query itch without building
```

`-Preview` on `publish.ps1` explicitly selects the default local preview.
On `publish-itch.ps1`, it means Butler's remote comparison, not a private
preview channel. `-UserVersion <label>` supplies an optional itch build version.
Build before using the itch publisher. Both scripts stop on failed tools.

## Tools and configuration

Web exports require **standard Godot 4.2.2**: the Mono editor disables Web export
even for GDScript. The approved standard editor is under ignored
`exports/tooling/`. `Run.ps1` still uses the original Mono editor.
Override with `-GodotExe <path>` or `GODOT_EXE`. Other versions are rejected.

Official Web and Windows x86-64 debug/release templates are installed under
`%APPDATA%/Godot/export_templates/4.2.2.stable`. Downloads came from the
[official Godot release](https://github.com/godotengine/godot-builds/releases/tag/4.2.2-stable)
and were verified against its `SHA512-SUMS.txt`. Scripts do not install tools.

Butler resolution: `-ButlerPath`, `BUTLER_EXE`, PATH, then the existing
`D:/WebHatchery/RustGames/rust_management/itch-butler/butler.exe`. It uses the
existing Butler login. Credentials never go in `publish.json` or source.

`publish.json` defines slug `small_following`, engine version, itch target
`kalaith/small-following` and distinct `html5` / `windows` channels.
For another Godot game, copy the entry scripts, `tools/publishing`, presets
and config; update scene paths, include filters, slug and itch target.
`-ProjectDir` selects a configured project.

WebHatchery settings come from `D:/WebHatchery/.env` (override with `-EnvFile`).
Process environment variables take precedence:

| Key | Meaning |
| --- | --- |
| `PREVIEW_ROOT`, `PRODUCTION_ROOT` | Selected local server root |
| `FTP_SERVER`, `FTP_USERNAME`, `FTP_PASSWORD` | Existing live connection |
| `FTP_PORT` | Port, default 21 |
| `FTP_REMOTE_ROOT` | Server root; deploy beneath `games/<slug>` |
| `FTP_USE_SSL` | Explicit TLS, default false to match Rust tooling |
| `FTP_PASSIVE_MODE` | Passive connection, default true |

`-DeployRoot <absolute path>` overrides the local root. Here preview uses
`\\wsl.localhost\Ubuntu\home\kalai\dev`, production uses `F:\WebHatchery`, and FTP
uses `/public_html/games/small_following`. The scripts update only this game's
files. Shared catalogs and Project Roost records remain outside their scope.

## Build and deployment behavior

Each build gets a new directory under ignored `builds/publish/`. Both exports
must exit successfully without logged errors before packaging succeeds and
`latest.json` changes. Export commands perform the editor import themselves.
The separate `--import` verification command retains a known exit-1 shutdown
limitation; see [VERIFICATION](VERIFICATION.md).

The pack explicitly includes the main and player scenes, scene dependencies, all runtime scripts,
assets and `data/upgrades.json`. Explicit script inclusion preserves resources
loaded from GDScript. Tests, docs, promo media and tools are excluded.
A SHA-256 manifest rejects missing, modified, unexpected or traversal paths
before reuse. Windows is also packaged as `small_following_windows.zip`,
copied beside the browser files for direct download.

Deployment overwrites known game files and writes the launcher last; it never
deletes unrelated files or updates sibling games. FTP is not atomic: a failed
transfer can leave a partial deployment. Correct the error and rerun
`-SkipBuild -FTP`. Previous local builds remain available. Butler manages
itch's build history and incremental uploads.

## Browser hosting

Godot 4.2 Web needs WebGL 2, HTTPS (localhost is exempt), and isolation headers:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

The publisher adds per-game `.htaccess` directives for Apache, including
`application/wasm` and cache revalidation. Apache must permit the directives
and enable `mod_headers`. Nginx ignores `.htaccess`; configure equivalent
headers in its game location. Verify actual HTTP responses and browser launch.
See [Godot 4.2 hosting](https://docs.godotengine.org/en/4.2/tutorials/export/exporting_for_web.html#serving-the-files).

In itch's Edit game page select **HTML**, mark the HTML5 upload playable in
the browser, and enable **SharedArrayBuffer support** in Embed options.
Use a 1280 x 800 embed or click to launch fullscreen. Windows remains a separate
download. Butler does not configure these settings or draft/public visibility.
See [itch HTML5 hosting](https://itch.io/docs/creators/html5).

Browser saves use IndexedDB and belong to each origin. They do not share the
desktop save or sync between localhost, WebHatchery and itch. Blocking browser
storage or third-party storage can prevent persistence. The touch update adds
tap movement and visible ritual/menu controls; see [verification](VERIFICATION.md)
for local browser emulation evidence. Real mobile devices and iOS Safari remain
unverified. A local touch build does not update the published copy.

## Checks

```powershell
.\tests\test_publish.ps1
python tools/publishing/serve.py       # localhost:8062, isolation headers
```

Offline publishing tests use isolated fixtures under `builds/` and fake Butler
calls. They check tampering, missing files, path safety, flags, dry-run side
effects and failure propagation. The optional Python server binds localhost
and serves the latest completed Web export; it is not a production server.
Exported-build and live deployment evidence belongs in VERIFICATION.
