# Small Following

This repository contains the Small Following Godot project. Its game and build
notes live in the project files and `docs/`.

## Promoter capture

Promoter uses the shared [Godot capture driver](../godot_toolkit/tools/promo/README.md); this project does not need its own capture script. The game starts from its configured title scene. Use normal game controls and the documented game flow to stage publicly released features. See the [Promoter plan and update rules](../../local_apps/promoter/adapters/godot/README.md).

From this project root, check whether source changes need an update video:

```powershell
$promoter = (Resolve-Path '..\..\local_apps\promoter').Path
$project = (Resolve-Path '.').Path
& "$promoter\scripts\godot-promo.ps1" -Mode status -ProjectRoot $project -ProjectKey small-following
```

Keep `small-following` as the project key for later videos. Put plans and generated media under Promoter's ignored `data/media/` directory.
