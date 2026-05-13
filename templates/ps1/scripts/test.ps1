[CmdletBinding()]
param([string]$Path = (Get-Location).Path, [switch]$All, [string]$Program, [string]$Filter, [string]$Recurse)
Set-StrictMode -Version Latest
. $PSScriptRoot\lib\common.ps1

if ($Recurse) { $Path = (Resolve-Path -LiteralPath $Recurse).Path; $All = $true }
$progs = Find-Programs -Root $Path -Program $Program
$fail = 0
foreach ($p in $progs) {
    $m = Get-ProgramManifest -Program $p
    if (-not $m.ContainsKey('run')) { Write-Result 'SKIP' $m.name '(no run)' 'Gray'; continue }
    $testsDir = Join-Path $p.Path '__tests__'
    if (-not (Test-Path $testsDir)) { continue }
    $cases = @(Get-ChildItem -LiteralPath $testsDir -Directory)
    foreach ($c in $cases) {
        if ($Filter -and $c.Name -notlike $Filter) { continue }
        $expect = Join-Path $c.FullName 'expect.txt'
        if (-not (Test-Path $expect)) { Write-Result 'SKIP' $m.name $c.Name 'Gray' @('no expect.txt'); continue }
        $argsFile = Join-Path $c.FullName 'args.txt'
        $cmd = $m.run
        if (Test-Path $argsFile) {
            $extra = (Get-Content -LiteralPath $argsFile -Raw).Trim()
            if ($extra) { $cmd = "$cmd $extra" }
        }
        $inF = Join-Path $c.FullName 'in.txt'
        $r = Invoke-Step -Cmd $cmd -Cwd $p.Path -StdinFile $inF
        $expectedOut = Get-Content -LiteralPath $expect -Raw
        $cmpOut = Compare-Text -Actual $r.Stdout -Expected $expectedOut

        $expErr = Join-Path $c.FullName 'expect.err.txt'
        $cmpErr = if (Test-Path $expErr) {
            Compare-Text -Actual $r.Stderr -Expected (Get-Content -LiteralPath $expErr -Raw)
        } else { @{ Match = $true } }

        $exitF = Join-Path $c.FullName 'exit.txt'
        $expCode = if (Test-Path $exitF) { [int]((Get-Content -LiteralPath $exitF -Raw).Trim()) } else { 0 }
        $codeOk = $r.ExitCode -eq $expCode

        if ($cmpOut.Match -and $cmpErr.Match -and $codeOk) {
            Write-Result 'PASS' $m.name $c.Name 'Green'
        } else {
            $fail++
            $diff = @()
            if (-not $cmpOut.Match) { $diff += 'stdout:'; $diff += $cmpOut.Diff }
            if (-not $cmpErr.Match) { $diff += 'stderr:'; $diff += $cmpErr.Diff }
            if (-not $codeOk) { $diff += "exit: expected=$expCode actual=$($r.ExitCode)" }
            Write-Result 'FAIL' $m.name $c.Name 'Red' $diff
        }
    }
}
exit $fail
