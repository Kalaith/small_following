# Offline tests. Uses only an isolated fixture under builds/ and fake artifacts.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. "$projectRoot/tools/publishing/Publisher.ps1"
$script:checks = 0
function Assert-Publish($Condition, $Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:checks++
    Write-Host "PASS: $Message"
}
function Assert-PublishFailure([scriptblock]$Action, [string]$Message) {
    $failed = $false
    try { & $Action *> $null } catch { $failed = $true }
    Assert-Publish $failed $Message
}
$fixture = Join-Path $projectRoot ('builds/publish-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture -Force | Out-Null
Copy-Item -LiteralPath "$projectRoot/project.godot", "$projectRoot/publish.json", "$projectRoot/export_presets.cfg" -Destination $fixture
$info = Get-PublishProject $fixture
Assert-Publish ($info.Slug -eq 'small_following') 'project metadata selects the configured slug'
Assert-PublishFailure { Read-PublishBuild $info } 'publishing without a completed build fails'
$id = '0123456789abcdef0123456789abcdef'
$buildDir = Join-Path $fixture "builds/publish/$id"
New-Item -ItemType Directory -Path "$buildDir/web", "$buildDir/windows" -Force | Out-Null
$records = @()
foreach ($relative in @('web/index.html', 'web/index.js', 'web/index.wasm', 'web/index.pck', 'web/index.worker.js', 'web/index.audio.worklet.js', 'windows/SmallFollowing.exe', 'small_following_windows.zip')) {
    [IO.File]::WriteAllText("$buildDir/$relative", "fixture-$relative")
    $records += @{ path = $relative; sha256 = (Get-FileHash -LiteralPath "$buildDir/$relative").Hash }
}
$manifest = @{ schema = 1; slug = $info.Slug; files = $records }
Write-PublishJson "$buildDir/manifest.json" $manifest
Write-PublishJson "$fixture/builds/publish/latest.json" @{ id = $id }
$build = Read-PublishBuild $info
Assert-Publish ($build.Directory -eq $buildDir) 'verified completed build is accepted'
Add-Content -LiteralPath "$buildDir/web/index.pck" -Value 'changed'
Assert-PublishFailure { Read-PublishBuild $info } 'modified pack prevents publication'
[IO.File]::WriteAllText("$buildDir/web/index.pck", 'fixture-web/index.pck')
[IO.File]::WriteAllText("$buildDir/web/secret.txt", 'fixture only')
Assert-PublishFailure { Read-PublishBuild $info } 'untracked build file prevents publication'
Remove-Item -LiteralPath "$buildDir/web/secret.txt"
$manifest.files = $records | Where-Object { $_.path -ne 'web/index.wasm' }
Write-PublishJson "$buildDir/manifest.json" $manifest
Assert-PublishFailure { Read-PublishBuild $info } 'missing runtime manifest entry prevents publication'
$manifest.files = $records + @{ path = '../outside.txt'; sha256 = 'none' }
Write-PublishJson "$buildDir/manifest.json" $manifest
Assert-PublishFailure { Read-PublishBuild $info } 'manifest path traversal is rejected'
$manifest.files = $records
Write-PublishJson "$buildDir/manifest.json" $manifest
$build = Read-PublishBuild $info
Assert-PublishFailure { Get-DeployDirectory 'relative' $info } 'relative deploy root is rejected'
$destination = Get-DeployDirectory "$fixture/deploy" $info
Assert-Publish ($destination -eq "$fixture\deploy\games\small_following") 'only this game receives deployment files'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
[IO.File]::WriteAllText("$destination/keep.txt", 'unrelated')
Copy-PublishWebsite $build $destination $info.Slug
Assert-Publish ((Get-Content -LiteralPath "$destination/keep.txt") -eq 'unrelated') 'deployment preserves unrelated files'
Assert-Publish (Test-Path -LiteralPath "$destination/.htaccess") 'Apache isolation headers are deployed'
Assert-Publish (Test-Path -LiteralPath "$destination/small_following_windows.zip") 'Windows download is deployed'
$dryDestination = "$fixture/dry-run"
& "$projectRoot/publish.ps1" -ProjectDir $fixture -DeployRoot $dryDestination -DryRun
Assert-Publish (-not (Test-Path -LiteralPath $dryDestination)) 'dry-run does not create deployment directories'
Assert-PublishFailure { & "$projectRoot/publish.ps1" -Preview -Production -DryRun } 'contradictory environments fail'
Assert-PublishFailure { & "$projectRoot/publish.ps1" -BuildOnly -FTP -DryRun } 'build-only cannot publish'
Assert-PublishFailure { & "$projectRoot/publish.ps1" -BuildOnly -SkipBuild } 'build-only cannot skip building'
Assert-PublishFailure { & "$projectRoot/publish-itch.ps1" -Preview -Status } 'contradictory itch actions fail'
& "$projectRoot/publish-itch.ps1" -ProjectDir $fixture -DryRun -ButlerPath "$fixture/missing.exe"
Assert-Publish $true 'itch dry-run validates artifacts without invoking Butler'
# Exercise channel dispatch with an isolated fake executable, never the network.
$fakeButler = "$fixture/butler.ps1"
[IO.File]::WriteAllText($fakeButler, '$args | ConvertTo-Json -Compress | Add-Content -LiteralPath (Join-Path $PSScriptRoot "calls.jsonl"); $global:LASTEXITCODE = 0')
& "$projectRoot/publish-itch.ps1" -ProjectDir $fixture -ButlerPath $fakeButler -Preview
$calls = @(Get-Content -LiteralPath "$fixture/calls.jsonl" | ForEach-Object { ,($_ | ConvertFrom-Json) })
Assert-Publish ($calls.Count -eq 2 -and $calls[0][0] -eq 'push-preview' -and $calls[1][0] -eq 'push-preview') 'itch preview compares both channels without push'
Assert-Publish ($calls[0][-1] -eq 'kalaith/small-following:html5' -and $calls[1][-1] -eq 'kalaith/small-following:windows') 'web and Windows use distinct configured channels'
& "$projectRoot/publish-itch.ps1" -ProjectDir $fixture -ButlerPath $fakeButler -Channel windows -UserVersion test-1
$lastCall = (Get-Content -LiteralPath "$fixture/calls.jsonl" -Tail 1) | ConvertFrom-Json
Assert-Publish ($lastCall[0] -eq 'push' -and $lastCall -contains '--userversion' -and $lastCall -notcontains '--auto-wrap') 'Windows push passes version without HTML wrapping'
[IO.File]::WriteAllText($fakeButler, '$global:LASTEXITCODE = 7')
Assert-PublishFailure { & "$projectRoot/publish-itch.ps1" -ProjectDir $fixture -ButlerPath $fakeButler -Status } 'Butler failure propagates'
Write-Host "PUBLISH RESULT: $script:checks checks, 0 failures. Fixture retained: $fixture"
