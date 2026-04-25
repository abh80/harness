Set-StrictMode -Version Latest

function ConvertFrom-HarnessToml {
    param([Parameter(Mandatory)][string]$Path)
    $result = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $l = $line.Trim()
        if ($l -eq '' -or $l.StartsWith('#')) { continue }
        if ($l -notmatch '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$') { continue }
        $key = $matches[1]
        $val = $matches[2].Trim()
        # strip trailing comment outside string
        if ($val -match '^"([^"]*)"') { $val = $matches[1] }
        elseif ($val -match "^'([^']*)'") { $val = $matches[1] }
        else { $val = ($val -replace '\s+#.*$','').Trim() }
        $result[$key] = $val
    }
    return $result
}
