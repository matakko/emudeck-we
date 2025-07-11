function appImageInit(){




	#Emulators new Path Junction
	$carpetaReal = "$env:USERPROFILE/EmuDeck/Emulators"
	$carpetaSymlink = "$env:APPDATA/EmuDeck/Emulators"

	# Verificar si la carpeta real existe como un directorio
	$esDirectorioReal = Test-Path $carpetaReal -PathType Container

	# Verificar si la carpeta symlink no existe o si existe pero no es un junction
	$existeSymlink = Test-Path $carpetaSymlink -PathType Container
	$esJunctionSymlink = $false

	if ($existeSymlink) {
		$esJunctionSymlink = (Get-Item $carpetaSymlink).Attributes -match "ReparsePoint"
	}

	# Si la carpeta real existe y la symlink no existe o no es un junction, crear el symlink
	if ($esDirectorioReal -and (-not $existeSymlink -or -not $esJunctionSymlink)) {
		createSaveLink $carpetaReal $carpetaSymlink
	}

	#ESDE new Path Junction
	$carpetaReal = "$env:USERPROFILE/EmuDeck/EmulationStation-DE"
	$carpetaSymlink = "$env:APPDATA/EmuDeck/EmulationStation-DE"

	# Verificar si la carpeta real existe como un directorio
	$esDirectorioReal = Test-Path $carpetaReal -PathType Container

	# Verificar si la carpeta symlink no existe o si existe pero no es un junction
	$existeSymlink = Test-Path $carpetaSymlink -PathType Container
	$esJunctionSymlink = $false

	if ($existeSymlink) {
		$esJunctionSymlink = (Get-Item $carpetaSymlink).Attributes -match "ReparsePoint"
	}

	# Si la carpeta real existe y la symlink no existe o no es un junction, crear el symlink
	if ($esDirectorioReal -and (-not $existeSymlink -or -not $esJunctionSymlink)) {
		createSaveLink $carpetaReal $carpetaSymlink
	}


	#AutoFixes
	mkdir "$emudeckFolder/feeds" -ErrorAction SilentlyContinue

	#Python
	generate_pythonEnv


	#CHD
	mkdir "$toolsPath\chdconv" -ErrorAction SilentlyContinue
	Copy-Item -Path "$env:APPDATA\EmuDeck\backend\tools\chdconv\chddeck.ps1" -Destination "$toolsPath\chdconv\" -Force


	Move-item -Path "$env:USERPROFILE/EmuDeck/settings.ps1" -destination "$env:APPDATA/EmuDeck/settings.ps1" -force
	setSetting "miratedSettings" "true"

	#Remove SRM BOM
	# $userConfigsFile="$toolsPath\userData\userConfigurations.json"
	# $content = Get-Content -Path $userConfigsFile -Raw
	# $killBOM = New-Object System.Text.UTF8Encoding $false
	# [System.IO.File]::WriteAllText($userConfigsFile, $content, $killBOM)


	#autofix_betaCorruption
	autofix_cloudSyncLockfile
	autofix_areInstalled
	#autofix_raSavesFolders
	#autofix_lnk
	#autofix_ESDE
	#autofix_dynamicParsers
	#autofix_oldParsersBAT
	#autofix_emulatorInitLaunchers
	#autofix_MAXMIN
	#autofix_junctions
	#autofix_controllerSettings
	#autofix_gamecubeFolder

	#ADB
	if ( Android_ADB_isInstalled -eq "false" ){
		Android_ADB_install
	}

	# Init functions
	setScreenDimensionsScale

	$test=Test-Path "$toolsPath\launchers\srm\steamrommanager.ps1"
	if ( -not $test ){
		mkdir "$toolsPath\launchers\srm\" -ErrorAction SilentlyContinue
		Copy-Item -Path "$env:APPDATA\EmuDeck\backend\tools\launchers\srm\steamrommanager.ps1" -Destination "$toolsPath\launchers\srm\" -Force
	}


#	mkdir "$emulationPath\roms\genesiswide" -ErrorAction SilentlyContinue
#	mkdir "$emulationPath\storage\rpcs3\dev_hdd0\game"  -ErrorAction SilentlyContinue


	###
	###
	### Check if ESDE is added to Steam
	###
	###
	$steamRegPath = "HKCU:\Software\Valve\Steam"
	$steamInstallPath = (Get-ItemProperty -Path $steamRegPath).SteamPath
	$steamInstallPath = $steamInstallPath.Replace("/", "\\")

	$steamPath = "$steamInstallPath\userdata"
	# Busca el archivo shortcuts.vdf en cada carpeta de userdata
	$ESDEinSteam="No"

	$archivosLinksVDF = Get-ChildItem -Path $steamPath -File -Recurse -Filter "shortcuts.vdf"

	if ($archivosLinksVDF.Count -gt 0) {
		$archivosLinksVDF | ForEach-Object {
			$filePath =  $_.FullName
			$shortcutsContent = Get-Content -Path $filePath
			if ($shortcutsContent -like "*EmulationStationDE*"){
				$ESDEinSteam="Yes"
			}
		}
	}

	if ($ESDEinSteam -eq "No" -and $doInstallESDE -eq "true" ){
		ESDE_addToSteam
	}

	#Azahar ESDE fix
	$xmlPath = "$esdePath/ES-DE/gamelists/n3ds/gamelist.xml"

	if (Select-String -Path $xmlPath -Pattern "Citra") {
		confirmDialog -TitleText "Azahar ESDE fixed" -MessageText "There was an issue launching Azahar from ESDE, we have just automatically fixed it. Now you can play 3DS Games using Azahar from ESDE"
		ESDE_init
		Copy-Item "$env:APPDATA\EmuDeck\backend\configs\emulationstation\gamelists\n3ds\gamelist.xml" -Destination "$esdePath\ES-DE\gamelists\n3ds\" -ErrorAction SilentlyContinue -Force
	}

	#Citron ESDE fix
	$xmlPath = "$esdePath/ES-DE/gamelists/switch/gamelist.xml"

	if(Test-Path "$xmlPath"){
		if (Select-String -Path $xmlPath -Pattern "Citron") {
			echo "we do nothing"
		}else{
			confirmDialog -TitleText "Citron ESDE fixed" -MessageText "There was an issue launching Citron from ESDE, we have just automatically fixed it. Now you can play your games using Citron from ESDE"
			ESDE_init
			Copy-Item "$env:APPDATA\EmuDeck\backend\configs\emulationstation\gamelists\switch\gamelist.xml" -Destination "$esdePath\ES-DE\gamelists\switch\" -ErrorAction SilentlyContinue -Force
		}
	}else{
		mkdir "$esdePath/ES-DE/gamelists/switch" -ErrorAction SilentlyContinue
		confirmDialog -TitleText "Citron ESDE fixed" -MessageText "There was an issue launching Citron from ESDE, we have just automatically fixed it. Now you can play your games using Citron from ESDE"
		ESDE_init
		Copy-Item "$env:APPDATA\EmuDeck\backend\configs\emulationstation\gamelists\switch\gamelist.xml" -Destination "$esdePath\ES-DE\gamelists\switch\" -ErrorAction SilentlyContinue -Force
	}


	echo "true"

}
