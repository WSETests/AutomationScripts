# this is the common defintion used in the script
Set-Variable WSE_CAMERA_DRIVER_FRIENDLY_NAME		-Option ReadOnly -Value "Windows Studio Effects Camera"
Set-Variable KSCATEGORY_VIDEO_CAMERA_CLASS_GUID		-Option ReadOnly -Value "{e5323777-f976-4f5b-9b55-b94699c46e44}"
# definition of the registry path
Set-Variable OS_CURRENT_VERSION_PATH_IN_REGISTRY	-Option ReadOnly -Value "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
Set-Variable SENSOR_GROUP_PATH_IN_REGISTRY			-Option ReadOnly -Value "HKLM:\SOFTWARE\Microsoft\Windows Media Foundation\FrameServer\SensorGroups"
Set-Variable VIDEO_CAMERA_CLASS_PATH_IN_REGISTRY	-Option ReadOnly -Value "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceClasses\$KSCATEGORY_VIDEO_CAMERA_CLASS_GUID"
# definition of the driver store path related to WSE
Set-Variable WINDOWS_DRIVER_FILE_REPOSITORY_PATH	-Option ReadOnly -Value "C:\Windows\System32\DriverStore\FileRepository\*"
# definition of the output file name
Set-Variable OUTPUT_TRAGET_FILE_NAME				-Option ReadOnly -Value "WseEnablingStatus.txt"

<#
.DESCRIPTION
	This function output message to console and target file.
#>
function outputMessage($message) {
	Write-Host $message
	Write-Output $message >> $pathLogsFolder\$OUTPUT_TRAGET_FILE_NAME
}

<#
.DESCRIPTION
	This function output driver info with its friendly name and version.
#>
function outputDriverInfoByFriendlyName($driverInstance) {
	$driverFriendlyName = $driverInstance.FriendlyName
	$driverVersion = $driverInstance.driverVersion
	outputMessage "${driverFriendlyName}: ${driverVersion}"
}

<#
.DESCRIPTION
	This function retrieve the first WSE camera driver instance from device manager.
#>
function getWseCameraDriverInstance() {
	# Looking into Device Manager,
	# making sure the "Windows Studio Effects Camera" is listed under "Software Components";
	# This means the extension .inf for MEP camera was deployed.

	$wseCameraDeviceNamingList = "Windows Camera Effects", "Windows Studio Camera Effects"

	return Get-CimInstance -Class win32_PnpSignedDriver |
		   Where-Object {($_.DeviceClass -eq "SoftwareComponent") -and ($wseCameraDeviceNamingList -contains $_.DeviceName)} |
		   Select-Object -First 1
}

<#
.DESCRIPTION
	This function retrieve the first WSE audio driver instance from device manager.
#>
function getWseAudioDriverInstance() {

	$wseAudioDeviceNamingList = "MSVoiceClarity APO", "MSAudioBlur APO"

	return Get-CimInstance -Class win32_PnpSignedDriver |
		   Where-Object {($_.DeviceClass -eq "AUDIOPROCESSINGOBJECT") -and ($wseAudioDeviceNamingList -contains $_.DeviceName)} |
		   Select-Object -First 1
}

<#
.DESCRIPTION
	This function retrieve the Opt-In camera from registry:
	Looking into registry,
	make sure the regkey DWORD named FSMEnablesMSEffects is set to value = 1,
	under Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceClasses\{e5323777-f976-4f5b-9b55-b94699c46e44}\<device ID>\#GLOBAL\Device Parameters,
	where <Device ID> is replaced with the related camera device ID
#>
function getOptInCameraInstanceFromRegistry() {

	$OptInCameraInstance = $null

	# looking for the all the camera devices under the SensorGroups
	$allCameraDevicesInSensorGroups =
		Get-ChildItem $SENSOR_GROUP_PATH_IN_REGISTRY |
		Where-Object {$_.Property -contains "SymbolicLinkName"}

	if ($null -ne $allCameraDevicesInSensorGroups) {

		foreach ($cameraDevice in $allCameraDevicesInSensorGroups) {

			# check if the SymbolicLinkName have GUID of KSCATEGORY_VIDEO_CAMERA
			$symbolicNameValue = $cameraDevice | Get-ItemProperty | Select-Object -ExpandProperty SymbolicLinkName

			if ($symbolicNameValue -match $KSCATEGORY_VIDEO_CAMERA_CLASS_GUID) {

				# split the string into two parts by KSCATEGORY_VIDEO_CAMERA_CLASS_GUID
				# ex. \\?\DISPLAY#INT3480#4&6cbd2a3&0&UID144512#{e5323777-f976-4f5b-9b55-b94699c46e44}\{35B04BC3-29D6-4DF2-B5ED-44819B53428E}
				# the first part is the device ID: '\\?\DISPLAY#INT3480#4&6cbd2a3&0&UID144512#'
				# the second part is the instance ID: '{35B04BC3-29D6-4DF2-B5ED-44819B53428E}'
				$tokens = $symbolicNameValue -split "\#$KSCATEGORY_VIDEO_CAMERA_CLASS_GUID\\"

				# replace the '\' with '#' in the first part
				# eg, '##?#DISPLAY#INT3480#4&6cbd2a3&0&UID144512'
				($tokens)[0] = ($tokens)[0].replace('\','#')

				# get the real device ID from the first part, and remove the prefix '##?#', with '#' replaced by '\'
				$OptInCameraDeviceID = ($tokens)[0].Substring(4)
				$OptInCameraDeviceID = $OptInCameraDeviceID.replace('#','\')

				$targetCameraDeivcePath =
					"$VIDEO_CAMERA_CLASS_PATH_IN_REGISTRY\" + ($tokens)[0] + "#$KSCATEGORY_VIDEO_CAMERA_CLASS_GUID\#" + $tokens[1]

				# check if regkey DWORD named FSMEnablesMSEffects exists
				$OptInCameraInstance =
				    Get-ChildItem -Path $targetCameraDeivcePath -recurse -ErrorAction SilentlyContinue |
					Where-Object {$_.Property -contains "FSMEnableMsEffects"} |
					Select-Object -First 1

				if ($OptInCameraInstance) {
					break
				}
			}
		}
	}

	return $OptInCameraInstance
}

<#
.DESCRIPTION
	This function retrieve camera HW info by its friendly name from device manager.
	be aware that the device with the specified friendly name may not always exist,
	so it might return null objects.
#>
function getOptInCameraHwInfoByFriendlyName($optinCameraFriendlyName) {

	return Get-CimInstance -Class win32_PnpSignedDriver |
		   Where-Object {$_.DeviceClass -eq "CAMERA" -and
		   				($_.FriendlyName -eq $optinCameraFriendlyName -or $_.Description -eq $optinCameraFriendlyName)}
}

<#
.DESCRIPTION
	This function collect the PerceptionCore.dll version info. from driver store path.
#>
function getPerceptionCoreInfo() {

	# Lookup all the PerceptionCore.dll under DriverStore path
	$perceptionCoreInfo =
		Get-ChildItem -Path $WINDOWS_DRIVER_FILE_REPOSITORY_PATH -Recurse -ErrorAction SilentlyContinue |
		Where-Object {$_.Name -eq "PerceptionCore.dll"}

	return $perceptionCoreInfo
}

<#
.DESCRIPTION
	This function output system related information.
#>
function displaySystemInfo() {
	$systemName = $env:COMPUTERNAME

	$currentOSVersionInfo = Get-ItemProperty $OS_CURRENT_VERSION_PATH_IN_REGISTRY
	$currentOSProductName = $currentOSVersionInfo.ProductName
	$currentBuildNumber = $currentOSVersionInfo.CurrentBuildNumber
	$currentUBR = $currentOSVersionInfo.UBR

	outputMessage "System Name: $systemName"
	outputMessage "System OS Info: $currentOSProductName ($currentBuildNumber.$currentUBR)"
}

<#
.DESCRIPTION
	This is main function to output the Opt-In camera status.
	Input parameters:
	(optional) $targetMepCameraVer: The version of MEP camera that the user expected.
	(optional) $targetMepAudioVer: The version of MEP audio that the user expected.
	(optional) $targetPerceptionCoreVer: The version of PerceptionCore.dll that the user expected.

	Output return code:
	$true: MEP enablement is successful.
	$false: there was a failure in MEP enablement.
#>

function WseEnablingStatus($targetMepCameraVer, $targetMepAudioVer, $targetPerceptionCoreVer) {

	# check device manager
	$wseCameraDriverInstance = getWseCameraDriverInstance
	if ($null -eq $wseCameraDriverInstance) {
		Write-Host "can not find '$WSE_CAMERA_DRIVER_FRIENDLY_NAME' in device manager, extension .inf for MEP camera was not correctly deployed" -ForegroundColor Red
		return $false
	}

	# Looking into registry
	$optinCameraInstanceFromRegistry = getOptInCameraInstanceFromRegistry
	if ($null -eq $optinCameraInstanceFromRegistry) {
		Write-Host "can not find Opt-in camera instance in registry, there is no 'FSMEnableMsEffects' key in registry" -ForegroundColor Red
		return $false
	}

	$FSMEnableMsEffectsValue = $optinCameraInstanceFromRegistry | Get-ItemProperty | Select-Object -ExpandProperty FSMEnableMsEffects
	if ("1" -ne $FSMEnableMsEffectsValue) {
		Write-Host "'FSMEnableMsEffects' key was not set to 1 in registry" -ForegroundColor Red
		return $false
	}

	displaySystemInfo

	# both conditions are met, output the opt-in result
	$bOptInCamera = ($null -ne $wseCameraDriverInstance) -and ("1" -eq $FSMEnableMsEffectsValue)
	outputMessage "Opt-In Camera Status: $bOptInCamera"

	$optinCameraFriendlyName = $optinCameraInstanceFromRegistry | Get-ItemProperty | Select-Object -ExpandProperty FriendlyName
	if ($optinCameraFriendlyName) {
		outputMessage "Opt-In Camera FriendlyName: $optinCameraFriendlyName"
		$optInCameraHwInfo = getOptInCameraHwInfoByFriendlyName $optinCameraFriendlyName
		if ($optInCameraHwInfo) {
			$optInCameraVidPid = $optInCameraHwInfo.HardWareID
			$optInCameraDriverVersion = $optInCameraHwInfo.DriverVersion
			outputMessage "Opt-In Camera Hardware ID: $optInCameraVidPid"
			outputMessage "Opt-In Camera Driver: $optInCameraDriverVersion"
		} else {
			Write-Host "Opt-In Camera Hardware Info not found"
		}
	}

	# output WSE camera driver info if exists
	if ($wseCameraDriverInstance) {
		outputDriverInfoByFriendlyName $wseCameraDriverInstance
		if ($targetMepCameraVer -and ($targetMepCameraVer -ne $wseCameraDriverInstance.driverVersion)) {
			Write-Host "User input MEP-camera version: $targetMepCameraVer"
			return $false
		}
	}

	# output WSE audio driver info if exists
	$wseAudioDriverInstance = getWseAudioDriverInstance
	if ($wseAudioDriverInstance) {
		outputDriverInfoByFriendlyName $wseAudioDriverInstance
		if ($targetMepAudioVer -and ($targetMepAudioVer -ne $wseAudioDriverInstance.driverVersion)) {
			Write-Host "User input MEP-audio version: $targetMepAudioVer"
			return $false
		}
	}

	# output PerceptionCore.dll version info if exists
	$perceptionCoreInfo = getPerceptionCoreInfo
	if ($perceptionCoreInfo) {
		# to verify whether the specified target perceptionCore version exists on the system.
		# if $targetPerceptionCoreVer was provided, set the value to false.
		$isPerceptionCoreVersionMatched = $true
		if ($targetPerceptionCoreVer) {
			$isPerceptionCoreVersionMatched = $false
		}

		foreach ($pcInfo in $perceptionCoreInfo) {
			$versionInfo = $pcInfo | Get-ItemProperty | Select-Object -ExpandProperty VersionInfo
			$pcProductVersion = $versionInfo.ProductVersion
			outputMessage "PerceptionCore.dll: $pcProductVersion [Path: $($pcInfo.FullName)]"
			if ($targetPerceptionCoreVer -and ($pcProductVersion -match $targetPerceptionCoreVer)) {
				$isPerceptionCoreVersionMatched = $true
			}
		}
		if (!($isPerceptionCoreVersionMatched)) {
			Write-Host "User input PerceptionCore version: $targetPerceptionCoreVer"
			return $false
		}
	} else {
		Write-Host "PerceptionCore.dll not found"
		return $false
	}

	# output Camera UWP version
	$camerAppVersion = Get-AppXPackage -Name "Microsoft.WindowsCamera"  | Select-Object -ExpandProperty Version
	if ($camerAppVersion) {
		outputMessage "CameraApp(UWP): $camerAppVersion"
	}

	return $true
}
