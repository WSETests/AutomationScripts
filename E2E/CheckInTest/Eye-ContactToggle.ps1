Add-Type -AssemblyName UIAutomationClient

function EyeContact-Playlist($devPowStat, $token, $SPId) 
{   
    $startTime = Get-Date    
    $ErrorActionPreference='Stop'
    $scenarioName = "$devPowStat\EyeContactStandard"
    $logFile = "$devPowStat-EyeContactStandard.txt"
    
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
        
        #Toggling Eye Contact effect on
        Write-Output "Entering ToggleAIEffectsInSettingsApp function to toggle Eye Contact effect on"
        ToggleAIEffectsInSettingsApp -AFVal "Off" -PLVal "Off" -BBVal "Off" -BSVal "False" -BPVal "False" `
                                     -ECVal "On" -ECSVal "True" -ECEVal "False" -VFVal "Off" `
                                     -CF "Off" -CFI "False" -CFA "False" -CFW "False"

                
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
        Verifylogs $scenarioName "16" $startTime

        #collect data for Reporting
        Reporting $Results "$pathLogsFolder\Report.txt"
        
        #For our Sanity, we make sure that we exit the test in netural state,which is pluggedin
        SetSmartPlugState $token $SPId 1  
     }
     catch
     {
        Error-Exception -snarioName $scenarioName -strttme $startTime -rslts $Results -logFile $logFile -token $token -SPID $SPID
     }
}
