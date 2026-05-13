[CmdletBinding(SupportsShouldProcess)]
param([string]$Path = (Get-Location).Path, [switch]$All, [string]$Program, [switch]$Refs, [string]$Recurse)
Set-StrictMode -Version Latest
. $PSScriptRoot\lib\common.ps1

if ($Recurse) { $Path = (Resolve-Path -LiteralPath $Recurse).Path; $All = $true }
$progs = Find-Programs -Root $Path -Program $Program
$fail = 0
foreach ($p in $progs) {
    $m = Get-ProgramManifest -Program $p
    if ($m.ContainsKey('clean')) {
        if ($PSCmdlet.ShouldProcess($m.name, 'clean')) {
            $r = Invoke-Step -Cmd $m.clean -Cwd $p.Path
            if ($r.ExitCode -ne 0) { $fail++; Write-Result 'FAIL' $m.name 'clean' 'Red' @($r.Stderr) }
            else { Write-Result 'OK' $m.name 'clean' 'Green' }
        }
    }
    if ($Refs) {
        $testsDir = Join-Path $p.Path '__tests__'
        if (Test-Path $testsDir) {
            Get-ChildItem -LiteralPath $testsDir -Directory | ForEach-Object {
                foreach ($f in 'expect.txt','expect.err.txt','exit.txt') {
                    $fp = Join-Path $_.FullName $f
                    if (Test-Path $fp) {
                        if ($PSCmdlet.ShouldProcess($fp, 'remove')) { Remove-Item -LiteralPath $fp }
                    }
                }
            }
        }
    }
}
exit $fail
