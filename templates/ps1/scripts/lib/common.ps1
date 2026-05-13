Set-StrictMode -Version Latest
. $PSScriptRoot\toml.ps1

function Get-GitIgnoredSet {
    param([string]$Root, [string[]]$Paths)
    $set = @{}
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $set }
    Push-Location $Root
    try {
        $null = & git rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -ne 0) { return $set }
        if (-not $Paths -or $Paths.Count -eq 0) { return $set }
        $ignored = $Paths | & git check-ignore --stdin 2>$null
        if ($LASTEXITCODE -gt 1) { return $set }
        foreach ($i in @($ignored)) { if ($i) { $set[$i] = $true } }
    } finally { Pop-Location }
    return $set
}

function Find-Programs {
    param([string]$Root = (Get-Location).Path, [string]$Program)
    $skip = @('node_modules','__tests__','.git','.harness','.svn','.hg')
    $candidates = @(
        Get-ChildItem -LiteralPath $Root -Recurse -Directory -Force |
            Where-Object {
                $name = $_.Name
                if ($name -eq '.git' -or $name -eq '.harness') { return $false }
                $rel = $_.FullName.Substring($Root.Length).TrimStart('\','/')
                $parts = $rel -split '[\\/]'
                foreach ($p in $parts) {
                    if ($skip -contains $p) { return $false }
                }
                return $true
            }
    )
    $ignored = Get-GitIgnoredSet -Root $Root -Paths ($candidates | ForEach-Object { $_.FullName })
    $progs = @()
    foreach ($dir in $candidates) {
        if ($ignored.ContainsKey($dir.FullName)) { continue }
        $hasManifest = Test-Path (Join-Path $dir.FullName 'harness.toml')
        $hasConv = @(@('install','build','run','clean') | Where-Object {
            Test-Path (Join-Path $dir.FullName "$_.ps1")
        })
        if ($hasManifest -or $hasConv.Count -gt 0) {
            if (-not $Program -or $dir.Name -eq $Program) {
                $progs += [PSCustomObject]@{
                    Path = $dir.FullName
                    Name = $dir.Name
                    HasManifest = $hasManifest
                }
            }
        }
    }
    return @($progs)
}

function Get-ProgramManifest {
    param([Parameter(Mandatory)]$Program)
    if ($Program.HasManifest) {
        $m = ConvertFrom-HarnessToml -Path (Join-Path $Program.Path 'harness.toml')
        if (-not $m.ContainsKey('name')) { $m['name'] = $Program.Name }
        return $m
    } else {
        $m = @{ name = $Program.Name }
        foreach ($step in 'install','build','run','clean') {
            $p = Join-Path $Program.Path "$step.ps1"
            if (Test-Path $p) { $m[$step] = "& '$p'" }
        }
        return $m
    }
}

function Invoke-Step {
    param([string]$Cmd, [string]$Cwd, [string]$StdinFile)
    if (-not $Cmd) { return [PSCustomObject]@{ ExitCode = 0; Stdout = ''; Stderr = ''; Skipped = $true } }
    $outF = [System.IO.Path]::GetTempFileName()
    $errF = [System.IO.Path]::GetTempFileName()
    $useStdin = $StdinFile -and (Test-Path $StdinFile)
    try {
        Push-Location $Cwd
        if ($useStdin) {
            # cmd.exe handles native stdin redirect + closes properly on EOF
            $cmdLine = "$Cmd < `"$StdinFile`" > `"$outF`" 2> `"$errF`""
            & cmd.exe /c $cmdLine
        } else {
            $script = "& { $Cmd } 1> '$outF' 2> '$errF' 3>`$null 4>`$null 5>`$null 6>`$null"
            $null = Invoke-Expression $script
        }
        $code = if (Test-Path variable:LASTEXITCODE) { $LASTEXITCODE } else { 0 }
        if ($null -eq $code) { $code = 0 }
        $obj = [PSCustomObject]@{
            ExitCode = [int]$code
            Stdout = (Get-Content -LiteralPath $outF -Raw -ErrorAction SilentlyContinue) ?? ''
            Stderr = (Get-Content -LiteralPath $errF -Raw -ErrorAction SilentlyContinue) ?? ''
            Skipped = $false
        }
        Write-Output -NoEnumerate $obj
        return
    } finally {
        Pop-Location
        Remove-Item -LiteralPath $outF,$errF -ErrorAction SilentlyContinue
    }
}

function Compare-Text {
    param([string]$Actual, [string]$Expected, [int]$MaxLines = 20)
    $a = ($Actual -replace "`r`n","`n").TrimEnd("`n") -split "`n"
    $e = ($Expected -replace "`r`n","`n").TrimEnd("`n") -split "`n"
    if (($a -join "`n") -eq ($e -join "`n")) { return @{ Match = $true } }
    $diff = @()
    $max = [Math]::Max($a.Count, $e.Count)
    for ($i = 0; $i -lt $max -and $diff.Count -lt $MaxLines; $i++) {
        $av = if ($i -lt $a.Count) { $a[$i] } else { '<EOF>' }
        $ev = if ($i -lt $e.Count) { $e[$i] } else { '<EOF>' }
        if ($av -ne $ev) { $diff += "L$($i+1): -$ev"; $diff += "L$($i+1): +$av" }
    }
    return @{ Match = $false; Diff = $diff }
}

function Write-Result {
    param([string]$Tag, [string]$Program, [string]$Case, [string]$Color, [string[]]$Extra)
    Write-Host "[$Tag] $Program/$Case" -ForegroundColor $Color
    if ($Extra) { $Extra | ForEach-Object { Write-Host "  $_" } }
}
