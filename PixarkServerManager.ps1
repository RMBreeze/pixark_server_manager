#
# Script.ps1
#

function Get-WarningInterval {
	$durations = 15,10,5,4,3,2,1
	return $durations
}


# SCRIPT BODY
#
# Don't change below here unless you know what you are doing!!!
#

$installNew = "Install a new server."
$updateExisting = "Update an existing server."
$startExistingServer = "Start an existing server."
$restartExistingServer = "Restart an existing server."
$stopExistingServer = "Stop an existing server."
$backupExistingServer = "Backup an existing server."
$wipeExistingServer = "Wipe an existing server."
$uninstallExistingServer = "Uninstall an existing server."
$updateExistingServerInfo = "Update existing server info."
$installSteamCMD = "Install SteamCMD."

function Display-ServerList {
	param([String]$menuTitle,
		[Boolean]$skipAll = $FALSE)	
	Clear-Host
	Write-Host "----------------------------------"
	Write-Host " $menuTitle"
	Write-Host "----------------------------------"
	if ($Script:settings.servers.Count -eq 0) {
		Write-Host "`nYou have no servers currently installed!"
		pause
	}
	$tableName = "Installed Servers"
	$table = New-Object system.Data.DataTable "$tableName"
	$col1 = New-Object system.Data.DataColumn "#  ",([string])
	$col2 = New-Object system.Data.DataColumn "Session Name",([string])
	$col3 = New-Object system.Data.DataColumn "Alias",([string])
	$col4 = New-Object system.Data.DataColumn "Server Path",([string])

	$table.columns.add($col1)
	$table.columns.add($col2)
	$table.columns.add($col3)
	$table.columns.add($col4)
	$i = 0
	if ($Script:settings.servers.Count -gt 0 -and $skipAll -eq $FALSE) {
		$row = $table.NewRow()
		$row.("#  ") = "" + ++$i + "."
		$row.("session Name") = "ALL SERVERS"
		$row.("Server Path") = "ALL SERVERS"
		$row.("Alias") = "ALL SERVERS"
		$table.Rows.Add($row) 
	}
	foreach($serverInfo in $Script:settings.servers) {
		$row = $table.NewRow()
		$row.("#  ") = "" + ++$i + "."
		$row.("session Name") = $serverInfo.sessionName
		$row.("Alias") = $serverInfo.alias
		$row.("Server Path") = $serverInfo.drivePath
		$table.Rows.Add($row) 
	}	
	$row = $table.NewRow()
	$row.("#  ") = "Q."
	$row.("session Name") = "Main Menu"
	$row.("Server Path") = "Main Menu"
	$row.("Alias") = "Main Menu"
	$table.Rows.Add($row) 
	$table | format-table  -AutoSize	
}

function Display-MainMenu {
	Clear-Host
	Write-Host "----------------------------------"
	Write-Host " Welcome to PixArk Server Manager"
	Write-Host "----------------------------------"
	Write-Host "`n 1. $installNew"
	Write-Host " 2. $updateExisting"
	Write-Host " 3. $startExistingServer"
	Write-Host " 4. $restartExistingServer"
	Write-Host " 5. $stopExistingServer"
	Write-Host " 6. $backupExistingServer"
	Write-Host " 7. $wipeExistingServer"
	Write-Host " 8. $uninstallExistingServer"
	Write-Host " 9. $updateExistingServerInfo"
	Write-Host " 10. $installSteamCMD"
	Write-Host "`n---------------------------------"
	Write-Host " 'Q' to quit.`n"
}

function Start-MenuLoop {
	do {
		Display-MainMenu
		$choice = Read-Host "Enter a selection"
		switch ($choice) {
			  '1' {				
				Install-Server
			} '2' {
				Show-UpdatePrompt
			} '3' {
				Show-StartPrompt
			} '4' {
				Menu-Stub
			} '5' {
				Show-ShutdownPrompt
			} '6' {
				Show-BackupPrompt
			} '7' {
				Show-WipePrompt
			} '8' {
				Show-UninstallPrompt
			} '9' {
				Show-UpdateInfoPrompt
			} '10' {
				Test-SteamCmd
			}
		}
	} until ($choice -match "[qQ]")
}

function Show-StopPrompt {

}

function Show-WipePrompt {
	$worldDir = "\ShooterGame\Saved\CubeServers\CubeWorld_Light\*"
	$profileDir = "\SavedArks\*"
	do {		
		Display-ServerList -menuTitle $wipeExistingServer
		$choice = Read-Host "Coose a Menu # to continue"
		if ($choice -eq "1") {
			foreach($serverInfo in $Script:Settings.servers) {
				$proceed = Show-WarnPrompt -serverInfo $serverInfo
				if (-Not ($proceed)) { return }
				Remove-Item -Path $serverInfo.drivePath + $worldDir -Recurse -Force
				Remove-Item -Path $serverInfo.drivePath + $profileDir -Recurse -Force
			}			
		} else {
			if (-Not ($choice -match "^\d+$")) { continue }		
			$serverInfo = (Get-InstalledServers).Get(($choice - 2))
			$proceed = Show-WarnPrompt -serverInfo $serverInfo
			if (-Not ($proceed)) { return }
			Remove-Item -Path $serverInfo.drivePath + $worldDir -Recurse -Force
			Remove-Item -Path $serverInfo.drivePath + $profileDir -Recurse -Force		
		}			
	} until ($choice -match "[qQ]")
}

function Show-StartPrompt {
	do {		
		Display-ServerList -menuTitle $startExistingServer
		$choice = Read-Host "Coose a Menu # to continue"
		if ($choice -eq "1") {
			foreach($serverInfo in $Script:Settings.servers) {
				Start-Server -serverInfo $serverInfo
			}			
		} else {
			if (-Not ($choice -match "^\d+$")) { continue }
			$servers = (Get-InstalledServers)
			$serverInfo = $servers.Get(($choice - 2)) 
			Start-Server -serverInfo $serverInfo
		}			
	} until ($choice -match "[qQ]")
}

function Show-UpdateInfoPrompt {
	do {		
		Display-ServerList -menuTitle $updateExistingServerInfo -skipAll $TRUE
		$choice = Read-Host "Coose a Menu # to continue"		
		if (-Not ($choice -match "^\d+$")) { continue }
		Update-ServerInfo -skipServerRoot $TRUE
	} until ($choice -match "[qQ]")
}

function Show-UninstallPrompt {
	do {		
		Display-ServerList -menuTitle $uninstallExistingServer
		$choice = Read-Host "Coose a Menu # to continue"
		if ($choice -eq "1") {
			foreach($serverInfo in $Script:Settings.servers) {
				$proceed = Show-WarnPrompt -serverInfo $serverInfo
				if (-Not ($proceed)) { return }
				Remove-Item -Path $serverInfo.drivePath -Recurse -Force				
			}			
		} else {
			if (-Not ($choice -match "^\d+$")) { continue }			
			$serverInfo = (Get-InstalledServers).Get(($choice - 2))
			$proceed = Show-WarnPrompt -serverInfo $serverInfo
			if (-Not ($proceed)) { return }
			if (Test-Path $serverInfo.drivePath) { Remove-Item -Path $serverInfo.drivePath -Recurse -Force }
			[System.Collections.ArrayList]$servers = (Get-InstalledServers)
			$servers.RemoveAt(($choice - 2))
			$Script:Settings.servers = $servers
			Export-SettingsFile			
		}			
	} until ($choice -match "[qQ]")
}

function Show-WarnPrompt {
	param([server_info]$serverInfo)
	Write-Host "`n"
	do {
		$choice = Read-Host "WARNING!!! This process is irreversable! Do you want to create a backup first (Y/N) [Y]"
		if ($choice -match "[yY]") { Backup-ServerData -targetRoot $serverInfo.drivePath }
	} until ($choice -match "[yY]" -Or $choice -match "[nN]")

	$deleteKey = $serverInfo.guid.Split("-")[0]
	$okToProceed = $FALSE
	Write-Host "`nAre you ABSOLUTELY sure you want to continue?"	
	do {
		Write-Host -NoNewLine "`nType " 
		Write-Host "$deleteKey" -ForegroundColor Red -NoNewline
		Write-Host " to proceed, Q to return to Main Menu: " -NoNewline 		
		$choice = Read-Host
		if ($choice -match "[qQ]") { 
			continue 
		} elseIf (-Not ($choice -eq $deleteKey)) { 
			Write-Host "$deleteKey" -ForegroundColor Red -NoNewline
			Write-Host " does not match " -NoNewline
			Write-Host "$choice" -ForegroundColor Red -NoNewline
			Write-Host ". Try again!" -NoNewline 
		} else {
			$okToProceed = $TRUE
		}
	} until ($choice -match "[qQ]" -OR $choice -eq $deleteKey)
	$okToProceed
}

function Show-UpdatePrompt {	
	do {		
		Display-ServerList -menuTitle $updateExisting
		$choice = Read-Host "Coose a Menu # to continue"
		if ($choice -eq "1") {
			Update-Server -updateAll $TRUE
		} else {
			if (-Not ($choice -match "^\d+$")) { continue }
			$servers = Get-InstalledServers
			Update-Server -serverInfo $servers.Get(($choice - 2))
		}			
	} until ($choice -match "[qQ]")
}

function Assert-UpdateNeeded {
	param(
		[Parameter(mandatory=$true)]
		[server_info]$serverInfo
	)
	$cacheAppManifest = $script:settings.serverCacheDir + "steamapps\appmanifest_824360.acf"
	$cacheBuildId = Get-BuildId -appmanifest $cacheAppManifest
	$targetBuildId = Get-BuildId -appmanifest $serverInfo.appManifest
	return ($cacheAppManifest -ne $targetBuildId)
}

function Update-Server {
	param(		
		[boolean]$updateAll = $FALSE,
		[Parameter(mandatory=$true)]
		[server_info]$serverInfo
	)
	Update-ServerCache
	if ($updateAll) {
		foreach($serverInfo in $Script:Settings.servers) {
			Start-SafeUpdate -serverInfo $serverInfo
		}
	} else {
		Start-SafeUpdate -serverInfo $serverInfo
	}
}

function Start-SafeUpdate {
	param(
		[server_info]$serverInfo
	)
	if (Asset-UpdateNeeded -serverInfo $serverInfo) {				
		Invoke-SafeShutdown -serverInfo $serverInfo -verb restart -reason "Server Update!"
		Start-RoboCopy -path $serverInfo.drivePath -isUpdate $TRUE
	} else {
		Write-Host "Target Server is already up-to-date!"
	}
}

function Show-BackupPrompt {
	do {		
		Display-ServerList -menuTitle $backupExistingServer
		$choice = Read-Host "Coose a Menu # to continue"
		if ($choice -eq "1") {
			Update-ServerCache	
			foreach($serverInfo in $Script:Settings.servers) {
				Backup-ServerData -targetRoot $serverInfo.drivePath
			}			
		} else {
			if (-Not ($choice -match "^\d+$")) { continue }
			$servers = Get-InstalledServers
			Backup-ServerData -targetRoot $servers.Get(($choice - 2)).drivePath
			pause
		}			
	} until ($choice -match "[qQ]")
}

function Get-InstalledServers {
	[System.Collections.ArrayList]$Script:Settings.servers	
}

function Send-RconCommand {
	param([String]$rconCommand, [server_info]$serverInfo)	
	& $Script:rcon -H $serverInfo.hostAddress -P $serverInfo.serverAdminPassword "$rconCommand"
}

function Backup-ServerData {
	param([String]$targetRoot)
	if ([String]::IsNullOrEmpty($targetRoot)) {
		Write-Host "You must supply a target server root path for backup!"
		pause
		return
	} 
	$toBeBackedUpPath = $targetRoot + "\ShooterGame\Saved"
	if (-Not (Test-Path -Path $toBeBackedUpPath)) {
		return
	}
	$excludeDir = "\Logs"
	$backupDir = "\PixArk_Backups"
	$zipName = "\" + (Get-Date -Format s).Replace(":", "_") + ".zip"
	$backupPath = $Script:settings.serverRoot + $backupDir
	$zipPath = $backupPath + $zipName
	if (-Not (Test-Path -Path $backupPath)) {
		New-Item -ItemType directory -Path $backupPath
	}
	$tempDir = [String][System.IO.Path]::GetTempFileName()
	Remove-Item $tempDir -Force
	New-Item -Type Directory -Path $tempDir -Force	
	Get-ChildItem $toBeBackedUpPath -Recurse | Copy-Item -Force -Destination { Join-Path $tempDir $_.FullName.Substring($toBeBackedUpPath.length) }
	if (Test-Path -Path $tempDir"\"$excludeDir) { Remove-Item -Recurse -Force $tempDir"\"$excludeDir }	
	Get-ChildItem $tempDir | Compress-Archive -DestinationPath "$zipPath" -Update
	Remove-Item $tempDir -Force -Recurse
}

function Start-Server {
	param([server_info]$serverInfo)
	$arguments = Build-ArgumentList -serverInfo $serverInfo
	Start-Process -FilePath ($serverInfo.drivePath + "\ShooterGame\Binaries\Win64\PixARKServer.exe") -ArgumentList $arguments 
	pause
}

function Build-ArgumentList {
	param([server_info]$serverInfo)
	$arguments += ("`"" + "CubeWorld_Light?listen?MaxPlayers=" + $serverInfo.maxPlayers + "?Port=" + $serverInfo.port + "?QueryPort=" + $serverInfo.queryPort + "?RCONPort=" + $serverInfo.rconPort + "?SessionName=" + $serverInfo.sessionName + "?ServerAdminPassword=" + $serverInfo.serverAdminPassword + "?CULTUREFORCOOKING=" + $serverInfo.cultureForCooking + "`"" )
	$arguments += " -NoBattlEye"
	$arguments += " -NoHangDetection"
	$arguments += (" -CubePort=" + $serverInfo.cubePort)
	$arguments += (" -cubeworld=" + $serverInfo.cubeWorld)
	$arguments += " -nosteamclient"
	$arguments += " -game"
	$arguments += " -server"
	$arguments += " -log"
	return $arguments
}

function Import-SettingsFile {
	$fileName = "settings.json"
	$currentDir = $script:invocationDir
	$defaultServerRoot = "C:\Servers\"
	$steamCmdDir = "SteamCMD\"
	$defaultSteamCMDRoot = $defaultServerRoot + $steamCmdDir
	$cacheDir = "PixArkCache_DoNotModify\"
	$steamCmdExe = "SteamCMD.exe"

	if (Test-Path ($currentDir + "\$fileName")) {
		$script:settings = Get-Content -Raw -Path ($currentDir + "\$fileName") | ConvertFrom-Json		
		return
	} elseIf (Test-Path ($script:settingsOutputDir + "\$fileName")) {
		$script:settings = Get-Content -Raw -Path ($script:settingsOutputDir + "\$fileName") | ConvertFrom-Json
		return
	} else {
		Clear-Host
		Write-Host "This is either your first run or your settings file is missing or corrupt!"
		$continue = Read-Host "`nDo you want to continue? A new settings file will be generated [Y]?"
		if ([String]::IsNullOrEmpty($continue)) {
			$serverRoot = "Y";
		}
		if ($continue -match "[nN]") {
			exit
		}
		do {
			$serverRoot = Read-Host "`nEnter your Server data root directory [$defaultServerRoot]"
			if ([String]::IsNullOrEmpty($serverRoot)) {
				$serverRoot = $defaultServerRoot;
			}
			$script:settings.serverRoot = $serverRoot
			$script:settings.serverCacheDir = $serverRoot + $cacheDir

			$steamCMD = Read-Host "`nEnter your SteamCMD root directory [$defaultSteamCMDRoot]"
			if ([String]::IsNullOrEmpty($steamCMD)) {
				$steamCMD = $defaultSteamCMDRoot;
			}
			$script:settings.steamCMD = "$steamCMD" + $steamCmdExe
			do {
				Write-Host ($script:settings | Format-List | Out-String)
				Write-Host "Ignore `"servers`" as you dont have any created... yet!"
				$proceed = Read-Host "Is this information correct (Y/N/Q)? " 
				if ($proceed -match "[Qq]") {
					exit
				}
			} until ($proceed -match "[yY]" -or $proceed -match "[nN]")
		} until ($proceed -match "[yY]")		
		$script:settings.servers = New-Object System.Collections.ArrayList
		Write-Host "`nThis script will now attempt to save the settings file at $script:settingsOutputDir\$script:settingsFileName, if that fails it will save the file in the current directory. Note that the `"$script:settingsFileName`" must be present in either your `"My Documents`" folder or the folder containing this script."
		New-Item -ItemType directory -Path $script:settingsOutputDir
		Export-SettingsFile
	}
}

function Export-SettingsFile {
	if (Test-Path -Path $script:settingsOutputDir) {
		$savePath = $script:settingsOutputDir
	} else { 
		$savePath = $script:invocationDir
	}
	$script:settings | ConvertTo-Json -depth 100 | Out-File ($savePath + "\" + $script:settingsFileName)
}

function Update-ServerInfo {
	param([boolean]$skipServerRoot = $FALSE)
	do {
		$serverInfo = New-Object server_info
		Write-Host "`nEnter the following server information, you will be given the option to start over before committing!"
		Write-Host "Press enter without typing anything to accept the [default answer], if applicable."
		
		if (-Not ($skipServerRoot)) {
			do {
				$defaultRoot = Read-Host "`nDo you want to use the default server root" $script:settings.serverRoot "[Y]"
				if ([String]::IsNullOrEmpty($defaultRoot)) { $defaultRoot = 'Y' }
			} until ($defaultRoot -match "[Yy]" -or $defaultRoot -match "[Nn]")
		}
		
		if ($defaultRoot -match "[yY]") {
			$pathMessage = "`nEnter a directory name for your new server eg. `"Server1`""
			$defaultPrefix = $script:settings.serverRoot
		} else {
			$pathMessage = "`nEnter a fully qualified directory path for your new server eg. `"C:\Servers\Server1`""
			$defaultPrefix = ""
		}
		
		do {
			$valid = $TRUE
			$drivePath = Read-Host $pathMessage
			if ([String]::IsNullOrEmpty($drivePath)) { 
				Write-Host "This cannot be blank!"
				$valid = $FALSE
				continue
			}
			$fullPath = $defaultPrefix + $drivePath
			if (Test-Path -path $fullPath) {
				Write-Host "There is already a directory with that name..."
				$valid = $FALSE
			}
		} until ($valid -eq $TRUE)
		
		Write-Host "Your new server will be located at $fullPath"
		$serverInfo.drivePath = $fullPath
		$serverInfo.appManifest = $fullPath + "\steamapps\appmanifest_824360.acf"

		$guid = [guid]::NewGuid()
		$serverInfo.guid = [String]$guid

		$defaultAlias = "MyFirstPixArkServer" 
		Write-Host "Create an alias for you server, this is only use for display purposes in this script and can be left blank!"
		$sessionName = Read-Host "`nEnter an alias for you server eg. `"$defaultAlias"`"
		$serverInfo.alias = $sessionName

		$randomDefaultName = "PixArk Server " + (Get-Random -Minimum 10000 -Maximum 1000000)
		$sessionName = Read-Host "`nEnter a Session Name so other people can find your server [$randomDefaultName]"
		if ([String]::IsNullOrEmpty($sessionName)) { $sessionName = $randomDefaultName }
		$serverInfo.sessionName = $sessionName

		$defaultMaxPlayers = 100
		$maxPlayers = Read-Host "`nEnter the maximum number of players allowed to connect [$defaultMaxPlayers]"
		if ([String]::IsNullOrEmpty($maxPlayers)) { $maxPlayers = $defaultMaxPlayers }
		$serverInfo.maxPlayers = $maxPlayers

		$defaultHostAddress = "127.0.0.1"	
		$hostAddress = Read-Host "`nEnter a host address for this server [$defaultHostAddress]"
		if ([String]::IsNullOrEmpty($hostAddress)) { $hostAddress = $defaultHostAddress }
		$serverInfo.hostAddress = $hostAddress

		$defaultRconPort = 20069
		$rconPort = Read-Host "`nEnter an RCON port number for issuing remote server commands [$defaultRconPort]"
		if ([String]::IsNullOrEmpty($rconPort)) { $rconPort = $defaultRconPort }
		$serverInfo.rconPort = $rconPort

		$defaultQueryPort = 21069
		$queryPort = Read-Host "`nEnter a Query Port number to respond to server queries [$defaultQueryPort]"
		if ([String]::IsNullOrEmpty($queryPort)) { $queryPort = $defaultQueryPort }
		$serverInfo.queryPort = $queryPort
	
		$defaultPort = 22069
		$port = Read-Host "`nEnter a Port number to accept incoming connections on [$defaultPort]"
		if ([String]::IsNullOrEmpty($port)) { $port = $defaultPort }
		$serverInfo.port = $port

		$defaultCubePort = 15000
		$cubePort = Read-Host "`nEnter a Cube port number... no idea what this does at the moment [$defaultCubePort]"
		if ([String]::IsNullOrEmpty($cubePort)) { $cubePort = $defaultCubePort }
		$serverInfo.cubePort = $cubePort

		$defaultServerPassword = ""
		$serverPassword = Read-Host "`nEnter a server password required for joining [$defaultServerPassword]"
		if ([String]::IsNullOrEmpty($serverPassword)) { $serverPassword = $defaultServerPassword }
		$serverInfo.serverPassword = $serverPassword

		$defaultCubeWorld = "world"
		$cubeWorld = Read-Host "`nEnter the name for your generated world [$defaultCubeWorld]"
		if ([String]::IsNullOrEmpty($cubeWorld)) { $cubeWorld = $defaultCubeWorld }
		$serverInfo.cubeWorld = $cubeWorld

		$defaultCultureForCooking = "en"
		$cultureForCooking = Read-Host "`nEnter the locale code for your language [$defaultCultureForCooking]"
		if ([String]::IsNullOrEmpty($cultureForCooking)) { $cultureForCooking = $defaultCultureForCooking }
		$serverInfo.cultureForCooking = $cultureForCooking

		$valid = $FALSE
		do {
			$serverAdminPassword = Read-Host "`nEnter a Server Admin Password... I wont let you leave this blank!"
			if (-Not [String]::IsNullOrEmpty($serverAdminPassword)) { $valid = $TRUE }
		} until ($valid -eq $TRUE)
		$serverInfo.serverAdminPassword = $serverAdminPassword

		Write-Host ($serverInfo | Format-List | Out-String)

		do {
			$answer = Read-Host "`nAre you sure you want to continue (Y/N/Q)"			
		} until ($defaultRoot -match "[Yy]" -or $defaultRoot -match "[Nn]")

		if ($answer -match "[qQ]") { exit }
		if ($answer -match "[yY]") { $continue = $TRUE }

	} until ($continue -eq $TRUE)

	$tempServerList = New-Object System.Collections.ArrayList
	$replacement = $FALSE
	foreach($server_settings in $script:settings.servers) {
		if($server_settings.drivePath -eq $serverInfo.drivePath) {
			Write-Host "`nWarning! A saved server entry already exists for that drive path, but there is no server installed there!" 
			Write-Host ($server_settings | Format-List | Out-String)
			do {
				$answer = Read-Host "This entry will be overwritten, which is likely safe to do so. Do you want to continue (Y/N) [Y]"
				if ([String]::IsNullOrEmpty($answer)) { $answer = 'Y' }
				if ($answer -match "[nN]") { return }
			} until ($answer -match "[Yy]")
			[void]$tempServerList.Add($serverInfo) 
			$replacement = $TRUE
		} else {
			[void]$tempServerList.Add($server_settings)
		}
	}
	if(-Not ($replacement)) { $tempServerList.Add($serverInfo) }
	if ($tempServerList.Count -eq 0) { 
		[void]$script:settings.servers.Add($serverInfo)
	} else { 
		$script:settings.servers = $tempServerList
	}
	Export-SettingsFile
	$script:newServer = $serverInfo	
}

function Install-Server {	
	Update-ServerInfo	
	Update-ServerCache
	Start-RoboCopy -path $script:newServer.drivePath -isUpdate $FALSE
	New-StartScript -serverInfo $script:newServer
	Write-Host "Your new server has been successfully installed at" $script:newServer.drivePath"!"
	pause
}

function Start-RoboCopy {
	param([String]$path,[boolean]$isUpdate)
	if ($isUpdate) { 
		$startMsg = "Updating existing Server."
		$endMsg = "Update complete!"
	} else {
		$startMsg = "Installing a new Server."
		$endMsg = "Installation complete!"
	}
	Write-Host "`n---------------------------------------------------------"
	Write-Host " $startMsg"
	Write-Host "---------------------------------------------------------`n"
	robocopy $script:settings.serverCacheDir $path /XO /e
	Write-Host "`n---------------------------------------------------------"
	Write-Host " $endMsg"
	Write-Host "---------------------------------------------------------`n"
	pause
}

function New-StartScript {
	param([server_info]$serverInfo)	
	$startScript = "start `"`" /NORMAL `""
    $startScript += $serverInfo.drivePath + "\ShooterGame\Binaries\Win64\PixARKServer.exe`" "
	$startScript += Build-ArgumentList -serverInfo $serverInfo
	$outPath = ($serverInfo.drivePath + "\start_server.bat")
	$startScript | Out-File -encoding ASCII -filePath $outPath
	Write-Host "A start script for your server has been placed in" $outPath	
}

function Test-SteamCmd {
	if (-Not (Test-Path $script:settings.steamCMD)) {
		Install-SteamCmd
	}
}

function Install-SteamCmd {
	Write-Host `n$script:settings.steamCMD "not found... This script cannot continue without it!"
	$choice = Read-Host "Would you like to automatically download and extract steamCMD [Y]?"
	if([String]::IsNullOrEmpty($choice)) { $choice = 'Y' }
	if (-Not ($choice -match "[Yy]")) {	exit }

	$steamCMDDir = Split-Path -Path $script:settings.steamCMD

	if(-Not (Test-Path $steamCMDDir)) { New-Item -ItemType directory -Path $steamCMDDir	}

	$webClient = (new-object System.Net.WebClient)
	$steamCMDUrl = "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
	$file = $steamCMDDir + "\steamcmd.zip"
	$webClient.DownloadFile($steamCMDUrl, $file)
	$shell = (New-Object -com shell.application)
	$zipfile = $shell.namespace($file)
	$target = $shell.namespace($steamCMDDir)
	$target.CopyHere($zipfile.items())
		
	Write-Host "SteamCMD succesfully installed to" $steamCMDDir
	pause
}

function Run-SteamCmdApp  {
	param([String]$installDir,[Boolean]$doValidate)
	$validate = if ($doValidate) { "validate +exit" } else { "+exit" }
	& $script:settings.steamCMD +login anonymous +force_install_dir $installDir +app_update 824360 $validate
}

function Get-BuildId {
	param(
		[Parameter(mandatory=$true)]
		[string]$appmanifest
	)
	foreach ($line in Get-Content $appmanifest) {
		if ($line -match "buildid") {
			$build_info = $line.trim() -split "\s+"
			$buildId = $build_info[1].trim('"')
		}
	}
	return $buildId
}

function Update-ServerCache {
	Test-SteamCmd
	Write-Host "`n---------------------------------------------------------"
	Write-Host "Updating Server Cache via SteamCMD."
	Write-Host "---------------------------------------------------------`n"
	
	$appManifest = $script:settings.serverCacheDir + "steamapps\appmanifest_824360.acf"
	if (Test-Path $appmanifest) {
		Write-Host "Checking for Updates via SteamCMD..."
		Run-SteamCmdApp -installDir $script:settings.serverCacheDir -doValidate $FALSE
	} else {
		Write-Host "You have no server cache downloaded, SteamCMD will automatically install the cache at" $script:settings.serverCacheDir
		Run-SteamCmdApp -installDir $script:settings.serverCacheDir -doValidate $TRUE
	}
	Write-Host "`n---------------------------------------------------------"
	Write-Host "Cache update complete!"
	Write-Host "---------------------------------------------------------`n"
}

function Ping-Server {
	param([server_info]$serverInfo)	
	$response = & .\mcrcon.exe -H $serverInfo.hostAdress -P $serverInfo.rconPort -p $serverInfo.serverPassword "saveworld"
}

function Get-PlayerList {
	param([server_info]$serverInfo)
	#$response =  & .\mcrcon.exe -H 127.0.0.1 -P 20069 -p 12345 "listplayers"
	$response = & .\mcrcon.exe -H $serverInfo.hostAdress -P $serverInfo.rconPort -p $serverInfo.serverPassword "listplayers"
	return $response
}

function Stop-Server {
	param([server_info]$serverInfo)
	#$response =  & .\mcrcon.exe -H 127.0.0.1 -P 20069 -p 12345 "saveworld"
	#$response =  & .\mcrcon.exe -H 127.0.0.1 -P 20069 -p 12345 "DoExit"
	$response = & .\mcrcon.exe -H $serverInfo.hostAdress -P $serverInfo.rconPort -p $serverInfo.serverPassword "saveworld"
	$response = & .\mcrcon.exe -H $serverInfo.hostAdress -P $serverInfo.rconPort -p $serverInfo.serverPassword "shutdown"
}

function Assert-ServerOnline {
	
}

function Assert-NoPlayersOnline {
	param([server_info]$serverInfo)
	$response = Get-PlayerList -serverInfo $serverInfo
	return ($response -match "No Players Connected")
}

function Send-ServerBroadcast {
	param(
		[server_info]$serverInfo,
		[string]$message
	)

	Write-Host $message.replace("\n","`n")
	#$response =  & .\mcrcon.exe -H 127.0.0.1 -P 20069 -p 12345 "broadcast $message"
	$response = & .\mcrcon.exe -H $serverInfo.hostAdress -P $serverInfo.rconPort -p $serverInfo.serverPassword "broadcast $message"
}


function Invoke-SafeShutdown {
	param(
		[server_info]$serverInfo,
		[string]$verb = "shutdown",
		[string]$reason = "Maintenance"
	)
	$durations = (Get-WarningInterval | Sort-Object -Descending)
	$i = 0
	foreach($minutesTillShutdown in $durations) {
		if (Assert-NoPlayersOnline -serverInfo $serverInfo) { 
			Write-Host "There are no players currently online, skipping warning cycle!"
			$goodToGo = $TRUE
			break 
		} 
		if ($minutesTillShutdown -eq 1) { 
			continue 
		} elseIf (($i + 1) -eq $durations.Count) {
			$timeLeft = ($minutesTillShutdown - 1) * 60
		} else {
			$timeLeft = ($durations[$i] - $durations[($i + 1)]) * 60
		}		
		Send-ServerBroadcast -message "Server $verb in $minutesTillShutdown minutes, find a safe place to logout! Reason: $reason" -serverInfo $serverInfo
		do {
			Write-Host "There are still players currently online."
			Start-Sleep -Seconds 60
			$timeLeft -= 60
			if (Assert-NoPlayersOnline -serverInfo $serverInfo) {
				$goodToGo = $TRUE
			}
		} until ($timeLeft -le 0 -or $goodToGo)
		$i++
	}
	if (-Not ($goodToGo)) {
		Send-ServerBroadcast -message "Server $verb in 60 seconds, find a safe place to logout! Reason: $reason" -serverInfo $serverInfo
		Start-Sleep -Seconds 30
		Send-ServerBroadcast -message "Server $verb in 30 seconds, find a safe place to logout! Reason: $reason" -serverInfo $serverInfo 
		Start-Sleep -Seconds 15
		Send-ServerBroadcast -message "Server $verb in 15 seconds, find a safe place to logout! Reason: $reason" -serverInfo $serverInfo
		Start-Sleep -Seconds 5
		Send-ServerBroadcast -message "Server $verb in 10 seconds, find a safe place to logout! Reason: $reason" -serverInfo $serverInfo
		Start-Sleep -Seconds 5
		Send-ServerBroadcast -message "Server $verb in 5 seconds, find a safe place to logout! Reason: $reason" -serverInfo $serverInfo
		Start-Sleep -Seconds 5		
	}
	Send-ServerBroadcast -message "Server $verb NOW! Have a nice day! Reason: $reason" -serverInfo $serverInfo
	Stop-Server -serverInfo $serverInfo
}

class server_info {
	[String]$guid
	[String]$alias
	[String]$drivePath
	[String]$appManifest
	[String]$sessionName
	[String]$hostAddress
	[int]$maxPlayers
	[int]$rconPort
	[int]$queryPort
	[int]$port
	[int]$cubePort
	[String]$cultureForCooking
	[String]$serverPassword
	[String]$cubeWorld
	[String]$serverAdminPassword
}

class manager_settings{
	[String]$steamCMD
	[String]$serverRoot
	[String]$serverCacheDir
	[System.Collections.ArrayList]$servers
}

function Perform-PreChecks {
	$script:invocationDir = Split-Path $script:MyInvocation.MyCommand.Path
	$script:settings = New-Object manager_settings
	$script:settingsFileName = "settings.json"
	$script:settingsOutputDir = [Environment]::GetFolderPath("MyDocuments") + "\PixArkSM"
	$script:rcon = $script:invocationDir + "\mcrcon.exe"
	if (-Not (Test-Path $script:rcon)) {
		Write-Host $script:rcon + " was not found... The script will only have limited functionality without it!"
		$script:rcon = $FALSE
		pause
	}
	Import-SettingsFile 
}

Perform-PreChecks
Start-MenuLoop
