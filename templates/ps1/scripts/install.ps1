[CmdletBinding()]
param([string]$Path = (Get-Location).Path, [switch]$All, [string]$Program, [string]$Recurse)
Set-StrictMode -Version Latest
. $PSScriptRoot\lib\common.ps1

if ($Recurse) { $Path = (Resolve-Path -LiteralPath $Recurse).Path; $All = $true }
$progs = Find-Programs -Root $Path -Program $Program
if (-not $All -and -not $Program -and $progs.Count -gt 1) {
    Write-Host "Multiple programs found. Use -All or -Program." -ForegroundColor Yellow; exit 2
}
$fail = 0
foreach ($p in $progs) {
    $m = Get-ProgramManifest -Program $p
    if (-not $m.ContainsKey('install')) { Write-Result 'SKIP' $m.name '(install)' 'Gray'; continue }
    $r = Invoke-Step -Cmd $m.install -Cwd $p.Path
    if ($r.ExitCode -ne 0) { $fail++; Write-Result 'FAIL' $m.name 'install' 'Red' @($r.Stderr) }
    else { Write-Result 'OK' $m.name 'install' 'Green' }
}
exit $fail
