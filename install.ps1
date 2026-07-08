<#
.SYNOPSIS
    Installs or uninstalls Eyeless Tempering Made Easy.

.DESCRIPTION
    Patches the White March Part II Abydon finale conversation so the tempered ("Moderated")
    Abydon ending is ALWAYS available, regardless of how many Eyeless arguments you win.

    This is a data-file patch, not a sidecar DLL. It backs up the original conversation file once,
    then removes the condition on node 250 (the tempering player line) that hides it until node 320
    has fired. With that condition gone, the line is offered at the debate hub (node 145)
    immediately, regardless of how the debate goes. The vanilla gate can never be retuned to mean
    "always" - it requires reaching node 320, which needs fully winning debate topics - so the
    condition is removed rather than adjusted.

.PARAMETER GameDir
    Path to the Pillars of Eternity install directory. If omitted, common Steam locations are
    probed, then you are prompted.

.PARAMETER Uninstall
    Restore the backed-up conversation file.
#>
[CmdletBinding()]
param(
    [string]$GameDir,

    [switch]$Uninstall,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

$ErrorActionPreference = 'Stop'

$RelativeConversation = 'PillarsOfEternity_Data\data\conversations\px2_04_eyeless_stronghold\px2_04_cv_abydon_finale.conversation'
$BackupSuffix = '.eyeless-tempering-made-easy-backup'

function Normalize-PathInput([string]$path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return $null }
    $p = $path.Trim()
    if ($p.Length -ge 2 -and (($p.StartsWith('"') -and $p.EndsWith('"')) -or ($p.StartsWith("'") -and $p.EndsWith("'")))) {
        $p = $p.Substring(1, $p.Length - 2).Trim()
    }
    return [Environment]::ExpandEnvironmentVariables($p)
}

function Get-SteamRoots {
    $roots = New-Object System.Collections.Generic.List[string]
    foreach ($regPath in @(
        'HKCU:\Software\Valve\Steam',
        'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam',
        'HKLM:\SOFTWARE\Valve\Steam'
    )) {
        try {
            $props = Get-ItemProperty -LiteralPath $regPath -ErrorAction Stop
            foreach ($name in @('SteamPath', 'InstallPath')) {
                $value = Normalize-PathInput $props.$name
                if ($value -and (Test-Path -LiteralPath $value)) { $roots.Add($value) }
            }
        } catch {
        }
    }

    foreach ($root in @($roots.ToArray())) {
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (-not (Test-Path -LiteralPath $vdf)) { continue }
        try {
            foreach ($line in Get-Content -LiteralPath $vdf) {
                if ($line -match '"path"\s+"([^"]+)"') {
                    $library = ($Matches[1] -replace '\\\\', '\')
                    if ($library -and (Test-Path -LiteralPath $library)) { $roots.Add($library) }
                }
            }
        } catch {
        }
    }
    return $roots.ToArray() | Where-Object { $_ } | Select-Object -Unique
}

function Get-CandidateGameDirs {
    $guesses = New-Object System.Collections.Generic.List[string]
    foreach ($root in Get-SteamRoots) {
        $guesses.Add((Join-Path $root 'steamapps\common\Pillars of Eternity'))
    }
    foreach ($g in @(
        'C:\Program Files (x86)\Steam\steamapps\common\Pillars of Eternity',
        'C:\Program Files\Steam\steamapps\common\Pillars of Eternity',
        'D:\SteamLibrary\steamapps\common\Pillars of Eternity',
        'E:\SteamLibrary\steamapps\common\Pillars of Eternity'
    )) {
        $guesses.Add($g)
    }
    return $guesses.ToArray() | Where-Object { $_ } | Select-Object -Unique
}

function Test-GameDir([string]$dir) {
    if ([string]::IsNullOrWhiteSpace($dir)) { return $false }
    return Test-Path -LiteralPath (Join-Path $dir $RelativeConversation)
}

function Resolve-GameDir([string]$dir) {
    $try = Normalize-PathInput $dir
    if ([string]::IsNullOrWhiteSpace($try)) { return $dir }
    try {
        $leaf = Split-Path -Leaf $try
        if ($leaf -ieq 'px2_04_cv_abydon_finale.conversation' -or $leaf -ieq 'PillarsOfEternity.exe') {
            $try = Split-Path -Parent $try
        }
        if (Test-Path -LiteralPath $try) {
            $try = (Get-Item -LiteralPath $try).FullName
        } else {
            $try = [System.IO.Path]::GetFullPath($try)
        }
    } catch {
        return $dir
    }

    while ($try -and -not (Test-GameDir $try)) {
        $parent = Split-Path $try -Parent
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $try) { break }
        $try = $parent
    }
    if (Test-GameDir $try) { return $try }
    return $dir
}

function Find-GameDir {
    foreach ($g in Get-CandidateGameDirs) {
        if (Test-GameDir $g) { return $g }
    }
    return $null
}

function Get-GameDirOrPrompt {
    if ($RemainingArgs -and $RemainingArgs.Count -gt 0) {
        $script:GameDir = (($script:GameDir, $RemainingArgs) | Where-Object { $_ }) -join ' '
    }
    if ($script:GameDir) { $script:GameDir = Resolve-GameDir $script:GameDir }
    if (-not (Test-GameDir $script:GameDir)) {
        $auto = Find-GameDir
        if (Test-GameDir $auto) { $script:GameDir = $auto }
    }
    if (-not (Test-GameDir $script:GameDir)) {
        Write-Host "Could not find your Pillars of Eternity installation automatically." -ForegroundColor Yellow
        Write-Host "Paste the folder that contains 'PillarsOfEternity.exe' or 'PillarsOfEternity_Data'." -ForegroundColor DarkGray
        Write-Host "Quotes are optional; paths with spaces and parentheses are OK." -ForegroundColor DarkGray
        Write-Host "Example: C:\Program Files (x86)\Steam\steamapps\common\Pillars of Eternity" -ForegroundColor DarkGray
        for ($attempt = 1; $attempt -le 5; $attempt++) {
            $entry = Read-Host "Pillars of Eternity install path (leave blank to cancel)"
            if ([string]::IsNullOrWhiteSpace($entry)) { throw "Installation cancelled." }
            $candidate = Resolve-GameDir $entry
            if (Test-GameDir $candidate) { $script:GameDir = $candidate; break }
            Write-Host "I could not find the Abydon finale conversation from that path. Try the main game folder." -ForegroundColor Yellow
        }
        if (-not (Test-GameDir $script:GameDir)) { throw "Could not locate the game after several attempts." }
    }
    return $script:GameDir
}

function Get-Text([string]$path) {
    return [System.IO.File]::ReadAllText($path)
}

function Set-Text([string]$path, [string]$text) {
    [System.IO.File]::WriteAllText($path, $text)
}

function Install-Patch([string]$conversationPath) {
    $backup = "$conversationPath$BackupSuffix"
    if (-not (Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $conversationPath -Destination $backup -Force
        Write-Host "Backed up original conversation -> $backup" -ForegroundColor Green
    } else {
        Write-Host "Backup already exists: $backup" -ForegroundColor DarkGray
    }

    $text = Get-Text $conversationPath

    # Mechanism (traced through the actual .conversation flow, not the forum thread):
    #   * Node 145 ("Debate begins here") is the debate hub and links DIRECTLY to node 250 - the
    #     player line "Then return to Abydon with perspective as well as memory..." (the tempered
    #     "Moderated" ending, which leads to node 288).
    #   * Node 250 is hidden behind HasConversationNodeBeenPlayed(320): it appears only after node
    #     320 has fired. Node 320 is reached only by fully winning a debate topic
    #     (n_abydon_argument_danger/stuck/burden == 2) and, vanilla, all three
    #     (n_abydon_arguments_won == 3). So retuning the argument count can't ever mean "always"
    #     (an EqualTo matches one exact value), and it still requires reaching node 320 at all -
    #     which is why the old "3 -> 0" edit didn't reliably work.
    # Fix: remove node 250's HasConversationNodeBeenPlayed(320) condition, so the tempering line is
    # offered at the debate hub immediately, regardless of any arguments. Nothing else is touched;
    # the debate and its counters still work exactly as vanilla.
    $gate = 'HasConversationNodeBeenPlayed\(String, Int32\)</FullName>\s*<Parameters>\s*<string>[^<]*px2_04_cv_abydon_finale\.conversation</string>\s*<string>320</string>'
    if (-not [regex]::IsMatch($text, $gate)) {
        Write-Host "Already patched: the tempering line (node 250) is unconditional." -ForegroundColor Yellow
        return
    }

    $pattern = '<Components>\s*<ExpressionComponent[^>]*>\s*<Data>\s*<FullName>Boolean HasConversationNodeBeenPlayed\(String, Int32\)</FullName>\s*<Parameters>\s*<string>[^<]*px2_04_cv_abydon_finale\.conversation</string>\s*<string>320</string>\s*</Parameters>\s*</Data>\s*<Not>false</Not>\s*<Operator>And</Operator>\s*</ExpressionComponent>\s*</Components>'
    $matches = [regex]::Matches($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($matches.Count -ne 1) {
        throw "Expected exactly one node-320 gate on the tempering line (node 250), but found $($matches.Count). Refusing to guess."
    }

    $patched = [regex]::Replace(
        $text,
        $pattern,
        '<Components />',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    Set-Text $conversationPath $patched
    Write-Host "Patched Abydon finale: tempering line (node 250) now always available at the debate hub." -ForegroundColor Green
}

function Uninstall-Patch([string]$conversationPath) {
    $backup = "$conversationPath$BackupSuffix"
    if (-not (Test-Path -LiteralPath $backup)) {
        throw "Backup not found: $backup"
    }
    Copy-Item -LiteralPath $backup -Destination $conversationPath -Force
    Write-Host "Restored original conversation from backup." -ForegroundColor Green
}

$resolvedGameDir = Get-GameDirOrPrompt
Write-Host "Game folder: $resolvedGameDir" -ForegroundColor DarkGray

$proc = Get-Process -Name 'PillarsOfEternity*' -ErrorAction SilentlyContinue
if ($proc) {
    $ids = ($proc | ForEach-Object { $_.Id }) -join ', '
    throw "Pillars of Eternity is running (pid $ids). Close it and re-run."
}

$conversation = Join-Path $resolvedGameDir $RelativeConversation
if ($Uninstall) {
    Uninstall-Patch $conversation
    Write-Host "`nEyeless Tempering Made Easy uninstalled." -ForegroundColor Cyan
} else {
    Install-Patch $conversation
    Write-Host "`nEyeless Tempering Made Easy installed." -ForegroundColor Cyan
    Write-Host "Load any save before telling the Eyeless whether to reconstruct Abydon." -ForegroundColor DarkGray
}
