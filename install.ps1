# Links every skill in skills/ into each tool's skill folder (Windows junctions).
$targets = @("$HOME\.claude\skills", "$HOME\.codex\skills", "$HOME\.copilot\skills")
foreach ($skill in Get-ChildItem "$PSScriptRoot\skills" -Directory) {
    foreach ($root in $targets) {
        New-Item -ItemType Directory -Force $root | Out-Null
        $link = Join-Path $root $skill.Name
        if (Test-Path $link) {
            # Leave a real folder alone; it is not ours to replace.
            if ((Get-Item $link).LinkType -ne 'Junction') { Write-Warning "skip $link (exists, not a link)" }
            continue
        }
        New-Item -ItemType Junction -Path $link -Target $skill.FullName | Out-Null
        Write-Output "linked $link"
    }
}
