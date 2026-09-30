param(
	[switch]$PackageOnly
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$DeployDir = $PSScriptRoot
$ZipPath = Join-Path $DeployDir 'inventory-management-system.zip'
$SqlPath = Join-Path $DeployDir 'shop_inventory.sql'
$MySql = 'C:\xampp\mysql\bin\mysql.exe'
$MySqlDump = 'C:\xampp\mysql\bin\mysqldump.exe'

Write-Host 'Exporting database...'
& $MySqlDump -u root shop_inventory | Set-Content -Path $SqlPath -Encoding UTF8

Write-Host 'Building upload zip...'
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

$exclude = @(
	'deploy\host-credentials.ps1',
	'deploy\inventory-management-system.zip',
	'.git',
	'.gitignore'
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($ZipPath, 'Create')

function Add-FolderToZip($folder, $zipPrefix) {
	Get-ChildItem -LiteralPath $folder -Force | ForEach-Object {
		$relative = ($_.FullName.Substring($ProjectRoot.Length)).TrimStart('\')
		if ($exclude -contains $relative) { return }
		if ($relative -like 'deploy\*' -and $_.Name -ne 'shop_inventory.sql') { return }

		if ($_.PSIsContainer) {
			Add-FolderToZip $_.FullName $zipPrefix
		} else {
			$entryName = ($relative -replace '\\', '/')
			[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entryName) | Out-Null
		}
	}
}

Add-FolderToZip $ProjectRoot ''
$zip.Dispose()
Write-Host "Created $ZipPath"

$credFile = Join-Path $DeployDir 'host-credentials.ps1'
if ($PackageOnly -or -not (Test-Path $credFile)) {
	if (-not (Test-Path $credFile)) {
		Write-Host 'No deploy\host-credentials.ps1 — zip and SQL are ready for manual cPanel upload.'
	}
	exit 0
}

. $credFile
$localConfig = @"
<?php
return [
	'DB_HOST' => '$($Deploy.DbHost)',
	'DB_NAME' => '$($Deploy.DbName)',
	'DB_USER' => '$($Deploy.DbUser)',
	'DB_PASSWORD' => '$($Deploy.DbPassword)',
];
"@

$tempRoot = Join-Path $env:TEMP ('ims-deploy-' + [Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempRoot | Out-Null
try {
	Expand-Archive -Path $ZipPath -DestinationPath $tempRoot -Force
	$configDir = Join-Path $tempRoot 'inc\config'
	New-Item -ItemType Directory -Path $configDir -Force | Out-Null
	Set-Content -Path (Join-Path $configDir 'constants.local.php') -Value $localConfig -Encoding UTF8

	Write-Host "Uploading to $($Deploy.FtpHost)$($Deploy.RemoteRoot) ..."
	$ftpBase = "ftp://$($Deploy.FtpHost)$($Deploy.RemoteRoot)".TrimEnd('/')

	function Upload-FtpFile($localPath, $remotePath, $user, $pass) {
		$uri = "$ftpBase/$remotePath".Replace('\', '/').Replace('//', '/').Replace('ftp:/', 'ftp://')
		$request = [System.Net.FtpWebRequest]::Create($uri)
		$request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
		$request.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
		$request.UseBinary = $true
		$request.UsePassive = $true
		$bytes = [System.IO.File]::ReadAllBytes($localPath)
		$request.ContentLength = $bytes.Length
		$stream = $request.GetRequestStream()
		$stream.Write($bytes, 0, $bytes.Length)
		$stream.Close()
		$response = $request.GetResponse()
		$response.Close()
	}

	function Ensure-FtpDirectory($remoteDir, $user, $pass) {
		$parts = $remoteDir.Trim('/').Split('/')
		$path = ''
		foreach ($part in $parts) {
			if ($part -eq '') { continue }
			$path += "/$part"
			$uri = "$ftpBase$path"
			try {
				$request = [System.Net.FtpWebRequest]::Create($uri)
				$request.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
				$request.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
				$request.UsePassive = $true
				$response = $request.GetResponse()
				$response.Close()
			} catch {
				# Directory may already exist
			}
		}
	}

	Get-ChildItem -Path $tempRoot -Recurse -File | ForEach-Object {
		$relative = $_.FullName.Substring($tempRoot.Length).TrimStart('\').Replace('\', '/')
		$remoteDir = Split-Path $relative -Parent
		if ($remoteDir) { Ensure-FtpDirectory $remoteDir $Deploy.FtpUser $Deploy.FtpPassword }
		Upload-FtpFile $_.FullName $relative $Deploy.FtpUser $Deploy.FtpPassword
	}

	Write-Host 'Upload finished.'
	Write-Host "Import deploy\shop_inventory.sql in phpMyAdmin, then open $($Deploy.SiteUrl)/login.php"
}
finally {
	Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
