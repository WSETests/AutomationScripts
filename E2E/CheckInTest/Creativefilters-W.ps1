﻿Add-Type -AssemblyName UIAutomationClient

function Creativefilters-W-Playlist($devPowStat, $token, $SPId) 
{   
    $startTime = Get-Date    
    $ErrorActionPreference='Stop'
    $scenarioName = "$devPowStat\Creativefilters-W"
    $logFile = "$devPowStat-Creativefilters-W.txt"
    
    $wsev2PolicyState = CheckWSEV2Policy 
    if($wsev2PolicyState -eq $false)
    {
       TestOutputMessage $scenarioName "Skipped" $startTime "Creativefilters Not Supported"  
    }
    else
    {       
       $devState = CheckDevicePowerState $devPowStat $token $SPId
       if($devState -eq $false)
       {   
          TestOutputMessage $scenarioName "Skipped" $startTime "Token is empty"  
          return
       }
       try
	   {   
           #Create scenario specific folder for collecting logs
           Write-Output "Creating folder for capturing logs"
           CreateScenarioLogsFolder $scenarioName
           
           #Toggling Auto-Framing effect on
           Write-Output "Entering ToggleAIEffectsInSettingsApp function to toggle Creativefilters"
           ToggleAIEffectsInSettingsApp -AFVal "Off" -PLVal "Off" -BBVal "Off" -BSVal "False" -BPVal "False" `
                                        -ECVal "Off" -ECSVal "False" -ECEVal "False" -VFVal "Off" `
                                        -CF "On" -CFI "False" -CFA "False" -CFW "True"
                                    
           #Checks if frame server is stopped
           Write-Output "Entering CheckServiceState function" 
           CheckServiceState 'Windows Camera Frame Server'
       
           #Start collecting Traces before opening setting page
           Write-Output "Entering StartTrace function"
           StartTrace $scenarioName
       
           Write-Output "Open Setting Page"
           $ui = OpenApp 'ms-settings:' 'Settings'
           Start-Sleep -m 500
       
           #Open camera system setting page
           Write-Output "Entering FindCameraEffectsPage function"
           FindCameraEffectsPage $ui
           Start-Sleep -s 5
           
           #Close system setting page and stop collecting Trace
           CloseApp 'systemsettings'
       
           #Checks if frame server is stopped
           Write-Output "Entering CheckServiceState function" 
           CheckServiceState 'Windows Camera Frame Server'
       
           #Stop collecting trace
           Write-Output "Entering StopTrace function"
           StopTrace $scenarioName
       
           #Verify and validate if proper logs are generated or not.
           Write-Output "Entering Verifylogs function"
           Verifylogs $scenarioName "2097152" $startTime 
       
           #For our Sanity, we make sure that we exit the test in netural state,which is pluggedin
           SetSmartPlugState $token $SPId 1   
       
           #collect data for Reporting
           Reporting $Results "$pathLogsFolder\Report.txt"
                  
        }
        catch
        {  
           Error-Exception -snarioName $scenarioName -strttme $startTime -rslts $Results -logFile $logFile -token $token -SPID $SPID
        }
     }
}