[CmdletBinding()]
param([string]$Path = (Get-Location).Path, [switch]$All, [string]$Program, [string]$Filter, [string]$Recurse)
Set-StrictMode -Version Latest
. $PSScriptRoot\lib\common.ps1

if ($Recurse) { $Path = (Resolve-Path -LiteralPath $Recurse).Path; $All = $true }
$progs = Find-Programs -Root $Path -Program $Program
foreach ($p in $progs) {
    $m = Get-ProgramManifest -Program $p
    if (-not $m.ContainsKey('run')) { continue }
    $testsDir = Join-Path $p.Path '__tests__'
    if (-not (Test-Path $testsDir)) { continue }
    foreach ($c in @(Get-ChildItem -LiteralPath $testsDir -Directory)) {
        if ($Filter -and $c.Name -notlike $Filter) { continue }
        $argsFile = Join-Path $c.FullName 'args.txt'
        $cmd = $m.run
        if (Test-Path $argsFile) {
            $extra = (Get-Content -LiteralPath $argsFile -Raw).Trim()
            if ($extra) { $cmd = "$cmd $extra" }
        }
        $inF = Join-Path $c.FullName 'in.txt'
        $r = Invoke-Step -Cmd $cmd -Cwd $p.Path -StdinFile $inF
        Set-Content -LiteralPath (Join-Path $c.FullName 'expect.txt') -Value $r.Stdout -NoNewline
        $errF = Join-Path $c.FullName 'expect.err.txt'
        if ($r.Stderr) { Set-Content -LiteralPath $errF -Value $r.Stderr -NoNewline }
        elseif (Test-Path $errF) { Remove-Item -LiteralPath $errF }
        $exitF = Join-Path $c.FullName 'exit.txt'
        if ($r.ExitCode -ne 0) { Set-Content -LiteralPath $exitF -Value $r.ExitCode }
        elseif (Test-Path $exitF) { Remove-Item -LiteralPath $exitF }
        Write-Result 'REC' $m.name $c.Name 'Cyan'
    }
}
