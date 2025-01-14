Add-Type -AssemblyName UIAutomationClient

function Camera-App-Playlist($devPowStat, $token, $SPId) 
{   
    $startTime = Get-Date    
    $ErrorActionPreference='Stop'
    $scenarioName = "$devPowStat\Camerae2eTest"
    $logFile = "$devPowStat-Camerae2eTest.txt"
        
    try
	{  
        #Create Scenario folder
        $scenarioLogFolder = $scenarioName
        CreateScenarioLogsFolder $scenarioLogFolder

        #Toggling All effects on
        Write-Output "Entering ToggleAIEffectsInSettingsApp function to toggle all effects On"
        ToggleAIEffectsInSettingsApp -AFVal "On" -PLVal "On" -BBVal "On" -BSVal "False" -BPVal "True" `
                                     -ECVal "On" -ECSVal "False" -ECEVal "True" -VFVal "On" `
                                     -CF "On" -CFI "False" -CFA "False" -CFW "True"
                    
        #Open Camera App and set default setting to "Use system settings" 
        Write-Output "Open camera App"
        $ui = OpenApp 'microsoft.windows.camera:' 'Camera'
        Start-Sleep -s 1
        SetDefaultSettingInCameraApp $ui "Use system settings"

        #Validate WSE not supported in Photo Mode
        ValidateWSEInPhotoMode "$devPowStat\Camerae2eTest"
        
        #Close Camera App
        CloseApp 'WindowsCamera'

        #Set photo resolution ,3.8MP is specific to Arcata, 0.9MP is for LNL-GCS, setting few resolutions for LNL-HP-Rgis,RomulusEV3
        foreach ($ptoRes in "0.9 megapixels, 16 by 9 aspect ratio,  1280 by 720 resolution" , "2.1 megapixels, 16 by 9 aspect ratio,  1920 by 1080 resolution" , "3.8 megapixels, 16 by 9 aspect ratio,  2592 by 1458 resolution" ,  "12.2 megapixels, 4 by 3 aspect ratio,  4032 by 3024 resolution")
        {
           #Create scenario folder specific to photoresolution for collecting logs
           Write-Output "Creating folder for capturing logs"
           $ptoResfolder = $ptoRes.Split(", ") | Select-Object -First 1
           $ptoResfoldername = $ptoResfolder + "MP"
           $scenarioLogFolder = "$scenarioName\$ptoResfoldername" 

           CreateScenarioLogsFolder $scenarioLogFolder
           
          $devState = CheckDevicePowerState $devPowStat $token $SPId
          if($devState -eq $false)
          {   
             TestOutputMessage $scenarioLogFolder "Skipped" $startTime "Token is empty"  
             return
          }

           $result = SetphotoResolutionInCameraApp $scenarioLogFolder $startTime $ptoRes
           if($result[-1]  -ne $false)
           {  
              #Set video resolution, setting resolutions for LNL-HP-Regis, Romulus EV3
              foreach ($vdo in "1080p, 16 by 9 aspect ratio, 30 fps", "720p, 16 by 9 aspect ratio, 30 fps")
              {
                  #Create scenario folder specific to videoresolution for collecting logs
                  Write-Output "Creating folder for capturing logs"
                  $vdoResfolder = $vdo.Split(", ") | Select-Object -First 1
                  $scenarioLogFolder = "$scenarioName\$ptoResfoldername\$vdoResfolder" 

                  CreateScenarioLogsFolder $scenarioLogFolder

                  $result = SetvideoResolutionInCameraApp $scenarioLogFolder $startTime $vdo
                  if($result[-1]  -ne $false)
                  {
                     #Checks if frame server is stopped
                     Write-Output "Entering CheckServiceState function"
                     CheckServiceState 'Windows Camera Frame Server'
                                   
                     #Strating to collect Traces
                     Write-Output "Entering StartTrace function"
                     StartTrace $scenarioLogFolder

                     #Open Task Manager
                     Write-output "Opening Task Manager"
                     $uitaskmgr = OpenApp 'Taskmgr' 'Task Manager'
                     Start-Sleep -s 1
                     setTMUpdateSpeedLow -uiEle $uitaskmgr
                                          
                     #Start video recording and close the camera app once finished recording 
                     Write-Output "Entering StartVideoRecording function"
                     $InitTimeCameraApp = StartVideoRecording "60"
                     $cameraAppStartTime = $InitTimeCameraApp[-1]
                     Write-Output "Camera App start time in UTC: ${cameraAppStartTime}"

                     #Capture CPU and NPU Usage
                     Write-output "Entering CPUandNPU-Usage function to capture CPU and NPU usage Screenshot"  
                     stopTaskManager -uitaskmgr $uitaskmgr -Scenario $scenarioLogFolder
                     
                     #Checks if frame server is stopped
                     Write-Output "Entering CheckServiceState function"
                     CheckServiceState 'Windows Camera Frame Server' 
                     
                     #Stop the Trace
                     Write-Output "Entering StopTrace function"
                     StopTrace $scenarioLogFolder
                                                      
                     #Verify and validate if proper logs are generated or not.   
                     $wsev2PolicyState = CheckWSEV2Policy
                     if($wsev2PolicyState -eq $false)
                     {  
                        #ScenarioID 81968 is based on v1 effects.
                        Write-Output "Entering Verifylogs function"   
                        Verifylogs $scenarioLogFolder "81968" $startTime 
                        
                        #calculate Time from camera app started until PC trace first frame processed
                        Write-Output "Entering CheckInitTimeCameraApp function" 
                        CheckInitTimeCameraApp $scenarioLogFolder "81968" $cameraAppStartTime
                     }
                     else
                     {
                        #ScenarioID  is based on v1+v2 effects.
                        Write-Output "Entering Verifylogs function"  
                        Verifylogs $scenarioLogFolder "2834432" $startTime #(Need to change the scenario ID, not sure if this is correct)
                     
                        #calculate Time from camera app started until PC trace first frame processed
                        Write-Output "Entering CheckInitTimeCameraApp function" 
                        CheckInitTimeCameraApp $scenarioLogFolder "2834432" $cameraAppStartTime #(Need to change the scenario ID, not sure if this is correct)
                     }
                     
                     #Get the properties of latest video recording
                     Write-Output "Entering GetVideoDetails function"
                     GetVideoDetails $scenarioLogFolder $pathLogsFolder
                     
                     #collect data for Reporting
                     Reporting $Results "$pathLogsFolder\Report.txt"
                     
   
                 }
               }                  
           }             
        }  
        #Restore the default state for AI effects
        Write-Output "Entering ToggleAIEffectsInSettingsApp function to Restore the default state for AI effects"
        ToggleAIEffectsInSettingsApp -AFVal "Off" -PLVal "Off" -BBVal "Off" -BSVal "False" -BPVal "False" `
                                     -ECVal "Off" -ECSVal "False" -ECEVal "False" -VFVal "Off" `
                                     -CF "Off" -CFI "False" -CFA "False" -CFW "False"
             
    }
    catch
    {   
       Error-Exception -snarioName $scenarioLogFolder -strttme $startTime -rslts $Results -logFile $logFile -token $token -SPID $SPID
    }
}

