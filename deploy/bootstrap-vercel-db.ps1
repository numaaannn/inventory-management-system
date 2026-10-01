param(
	[string]$DatabaseUrl,
	[string]$SqlFile = "$PSScriptRoot\shop_inventory.sql"
)

$ErrorActionPreference = 'Stop'
$MySql = 'C:\xampp\mysql\bin\mysql.exe'

if (-not $DatabaseUrl) {
	$DatabaseUrl = $env:DATABASE_URL
}
if (-not $DatabaseUrl) {
	Write-Host 'Set DATABASE_URL (mysql://user:pass@host:port/dbname) or pass -DatabaseUrl'
	exit 1
}
if (-not (Test-Path $MySql)) {
	Write-Host "MySQL client not found at $MySql"
	exit 1
}
if (-not (Test-Path $SqlFile)) {
	Write-Host "SQL file not found: $SqlFile"
	exit 1
}

if ($DatabaseUrl -match '^mysql://([^:]+):([^@]+)@([^:/]+):?(\d+)?/(.+)$') {
	$user = [uri]::UnescapeDataString($Matches[1])
	$pass = [uri]::UnescapeDataString($Matches[2])
	$hostName = $Matches[3]
	$port = if ($Matches[4]) { $Matches[4] } else { '3306' }
	$db = $Matches[5]
} else {
	throw 'DATABASE_URL must look like mysql://user:pass@host:3306/dbname'
}

Write-Host "Importing into $hostName:$port/$db ..."
$env:MYSQL_PWD = $pass
Get-Content $SqlFile -Raw | & $MySql -h $hostName -P $port -u $user $db
Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
Write-Host 'Import complete.'
