﻿Add-Type -AssemblyName UIAutomationClient

function CameraAppTest($logFile,$token,$SPId,$camsnario,$vdoRes,$ptoRes,$devPowStat,$VF,$toggleEachAiEffect)
{
   try
   {  
       $startTime = Get-Date
       $VFdetails= "VF-$VF"
       $scenarioLogFolder = "CameraAppTest\$camsnario\$vdoRes\$ptoRes\$devPowStat\$VFdetails\$toggleEachAiEffect"
       Write-Output "`nStarting Test for $scenarioLogFolder`n"
       Write-Output "Creating the log folder" 
       CreateScenarioLogsFolder $scenarioLogFolder

       #Set the device Power state
       #if token and SPid is available than run scenarios for both pluggedin and unplugged 
       Write-Output "Start Tests for $devPowStat scenario" 
       $devState = CheckDevicePowerState $devPowStat $token $SPId
       if($devState -eq $false)
       {   
          TestOutputMessage  $scenarioLogFolder "Skipped" $startTime "Token is empty"  
          return
       }  

       #Open system setting page and toggle voice focus 
       if($VF -ne "NA")
       {
          VoiceFocusToggleSwitch $VF
       }
                       
       #Retrieve value for scenario from Hash table
       $toggleEachAiEffect = RetrieveValue $toggleEachAiEffect
       if($toggleEachAiEffect.length -eq 0)
       {
          TestOutputMessage $scenarioLogFolder "Skipped" $startTime "wsev2Policy Not Supported"
          return
       }
              
       #video resolution 
       Write-Output "Setting up the video resolution to $vdoRes"

       #Retrieve video resolution from hash table
       Write-Output "Retrieve $vdoRes value from hash table"
       $vdoRes = RetrieveValue $vdoRes
       
       #skip the test if video resolution is not available. 
       $result = SetvideoResolutionInCameraApp $scenarioLogFolder $startTime $vdoRes
       if($result[-1]  -eq $false)
       {
          Write-Output "$vdoRes is not supported"
          return
       }  
       
       #photo resolution 
       Write-Output "Setting up the Photo resolution to $ptoRes"
       
       #Retrieve photo resolution from hash table
       Write-Output "Retrieve $ptoRes value from hash table"
       $ptoRes = RetrieveValue $ptoRes
       #skip the test if photo resolution is not available. 
       $result = SetphotoResolutionInCameraApp $scenarioLogFolder $startTime $ptoRes
       if($result[-1]  -eq $false)
       {
          Write-Output "$PtoRes is not supported"
          return
       }
        
       #Open system setting page
       $ui = OpenApp 'ms-settings:' 'Settings'
       Start-Sleep -m 500
       
       #open camera effects page and turn all effects off
       Write-Output "Navigate to camera effects setting page"
       FindCameraEffectsPage $ui
       Start-Sleep -m 500 
       
       #Setting AI effects for Tests in camera setting page 
       $wsev2PolicyState = CheckWSEV2Policy
       if($wsev2PolicyState -eq $false)	  
       {
          $scenarioID = $toggleEachAiEffect[13]
                    
          #Setting AI effects for Tests in camera setting page 
          Write-Output "Setting up the camera Ai effects"       
          
          FindAndSetValue $ui ToggleSwitch "Automatic framing" $toggleEachAiEffect[0]
          FindAndSetValue $ui ToggleSwitch "Eye contact" $toggleEachAiEffect[5]
          
          FindAndSetValue $ui ToggleSwitch "Background effects" $toggleEachAiEffect[2]
          if($toggleEachAiEffect[2] -eq "On")
          {
              FindAndSetValue $ui RadioButton "Standard blur" $toggleEachAiEffect[3]
              FindAndSetValue $ui RadioButton "Portrait blur" $toggleEachAiEffect[4]
          }
       }
       else
       {
          $scenarioID = $toggleEachAiEffect[13]

          #Setting AI effects for Tests in camera setting page 
          Write-Output "Setting up the camera Ai effects"       
          
          FindAndSetValue $ui ToggleSwitch "Automatic framing" $toggleEachAiEffect[0]
          FindAndSetValue $ui ToggleSwitch "Portrait light" $toggleEachAiEffect[1]
          FindAndSetValue $ui ToggleSwitch "Background effects" $toggleEachAiEffect[2]
          if($toggleEachAiEffect[2] -eq "On")
          {
              FindAndSetValue $ui RadioButton "Standard blur" $toggleEachAiEffect[3]
              FindAndSetValue $ui RadioButton "Portrait blur" $toggleEachAiEffect[4]
          }
          FindAndSetValue $ui ToggleSwitch "Eye contact" $toggleEachAiEffect[5]
          if($toggleEachAiEffect[5] -eq "On")
          {
              FindAndSetValue $ui RadioButton "Standard" $toggleEachAiEffect[6]
              FindAndSetValue $ui RadioButton "Teleprompter" $toggleEachAiEffect[7]
              
          }
          FindAndSetValue $ui ToggleSwitch "Creative filters" $toggleEachAiEffect[8]
          if($toggleEachAiEffect[8] -eq "On")
          {
             FindAndSetValue $ui RadioButton "Illustrated" $toggleEachAiEffect[9]
             FindAndSetValue $ui RadioButton "Animated" $toggleEachAiEffect[10]
             FindAndSetValue $ui RadioButton "Watercolor" $toggleEachAiEffect[11]
              
          }
       }
       CloseApp 'systemsettings'
       
       #Checks if frame server is stopped
       Write-Output "Entering CheckServiceState function"
       CheckServiceState 'Windows Camera Frame Server'
                             
       #Strating to collect Traces
       StartTrace $scenarioLogFolder
       
       Write-Output "Start test for $camsnario"
       if($camsnario -eq "Recording")
       {
           #Start video recording and close the camera app once finished recording 
           $InitTimeCameraApp = StartVideoRecording "20"
           $cameraAppStartTime = $InitTimeCameraApp[-1]
           Write-Output "Camera App start time in UTC: ${cameraAppStartTime}"
       }
       else
       {   
           #Start Previewing and close the camera app once finished. 
           $InitTimeCameraApp = CameraPreviewing "20"
           $cameraAppStartTime = $InitTimeCameraApp[-1]
           Write-Output "Camera App start time in UTC: ${cameraAppStartTime}"
       }
       #Checks if frame server is stopped
       Write-Output "Entering CheckServiceState function"
       CheckServiceState 'Windows Camera Frame Server' 
       
       #Stop the Trace
       Write-Output "Entering StopTrace function"
       StopTrace $scenarioLogFolder                          
            
       #Verify and validate if proper logs are generated or not.        
       Verifylogs $scenarioLogFolder $scenarioID $startTime
       
       #calculate Time from camera app started until PC trace first frame processed
       Write-Output "Entering CheckInitTimeCameraApp function" 
       CheckInitTimeCameraApp $scenarioLogFolder $scenarioID $cameraAppStartTime
       
       if($camsnario -eq "Recording")
       {   
          if($VF -eq "On")
          { 
             #Verify and validate if proper logs are generated or not for Audio Blur.
             VerifyAudioBlurLogs $scenarioLogFolder 512 
          } 
           
           #Get the properties of latest video recording
           GetVideoDetails $scenarioLogFolder $pathLogsFolder
       }
       
       Write-Output "Entering GetContentOfLogFileAndCopyToTestSpecificLogFile function"
       GetContentOfLogFileAndCopyToTestSpecificLogFile $scenarioLogFolder
       
       #collect data for Reporting
       Reporting $Results "$pathLogsFolder\Report.txt"
   
    }
    catch
    {
        CloseApp 'WindowsCamera'
        CloseApp 'Taskmgr'
        StopTrace $scenarioLogFolder
        CheckServiceState 'Windows Camera Frame Server'
        Write-Output $_
        TestOutputMessage $scenarioLogFolder "Exception" $startTime $_.Exception.Message
        Reporting $Results "$pathLogsFolder\Report.txt"
        GetContentOfLogFileAndCopyToTestSpecificLogFile $scenarioLogFolder
        $getLogs = Get-Content -Path "$pathLogsFolder\$scenarioLogFolder\log.txt" -raw
        write-host $getLogs
        $logs = resolve-path "$pathLogsFolder\$scenarioLogFolder\log.txt"
        Write-Host "(Logs saved here:$logs)"
        SetSmartPlugState $token $SPId 1
        #TakeScreenshot 
       
        continue;
    }                                
 
}
function CameraAppTest-Internal($logFile,$token,$SPId,$camsnario,$vdoRes,$ptoRes,$devPowStat,$VF,$toggleEachAiEffect)
{
   try
   {  
       $startTime = Get-Date
       $VFdetails= "VF-$VF"
       $scenarioLogFolder = "CameraAppTest\$camsnario\$vdoRes\$ptoRes\$devPowStat\$VFdetails\$toggleEachAiEffect"
       Write-Output "`nStarting Test for $scenarioLogFolder`n"
       Write-Output "Creating the log folder" 
       CreateScenarioLogsFolder $scenarioLogFolder

       #Retrieve value for scenario from Hash table
       $toggleEachAiEffect = RetrieveValue $toggleEachAiEffect
       if($toggleEachAiEffect.length -eq 0)
       {
          TestOutputMessage $scenarioLogFolder "Skipped" $startTime "wsev2Policy Not Supported"
          return
       }

       #Open system setting page
       $ui = OpenApp 'ms-settings:' 'Settings'
       Start-Sleep -m 500
       
       #open camera effects page and turn all effects off
       Write-Output "Navigate to camera effects setting page"
       FindCameraEffectsPage $ui
       Start-Sleep -m 500 
       
       #Setting AI effects for Tests in camera setting page 
       $wsev2PolicyState = CheckWSEV2Policy
       if($wsev2PolicyState -eq $false)	  
       {
          $scenarioID = $toggleEachAiEffect[13]
                    
          #Setting AI effects for Tests in camera setting page 
          Write-Output "Setting up the camera Ai effects"       
          
          FindAndSetValue $ui ToggleSwitch "Automatic framing" $toggleEachAiEffect[0]
          FindAndSetValue $ui ToggleSwitch "Eye contact" $toggleEachAiEffect[5]
          
          FindAndSetValue $ui ToggleSwitch "Background effects" $toggleEachAiEffect[2]
          if($toggleEachAiEffect[2] -eq "On")
          {
              FindAndSetValue $ui RadioButton "Standard blur" $toggleEachAiEffect[3]
              FindAndSetValue $ui RadioButton "Portrait blur" $toggleEachAiEffect[4]
          }
       }
       else
       {
          $scenarioID = $toggleEachAiEffect[13]

          #Setting AI effects for Tests in camera setting page 
          Write-Output "Setting up the camera Ai effects"       
          
          FindAndSetValue $ui ToggleSwitch "Automatic framing" $toggleEachAiEffect[0]
          FindAndSetValue $ui ToggleSwitch "Portrait light" $toggleEachAiEffect[1]
          FindAndSetValue $ui ToggleSwitch "Background effects" $toggleEachAiEffect[2]
          if($toggleEachAiEffect[2] -eq "On")
          {
              FindAndSetValue $ui RadioButton "Standard blur" $toggleEachAiEffect[3]
              FindAndSetValue $ui RadioButton "Portrait blur" $toggleEachAiEffect[4]
          }
          FindAndSetValue $ui ToggleSwitch "Eye contact" $toggleEachAiEffect[5]
          if($toggleEachAiEffect[5] -eq "On")
          {
              FindAndSetValue $ui RadioButton "Standard" $toggleEachAiEffect[6]
              FindAndSetValue $ui RadioButton "Teleprompter" $toggleEachAiEffect[7]
              
          }
          FindAndSetValue $ui ToggleSwitch "Creative filters" $toggleEachAiEffect[8]
          if($toggleEachAiEffect[8] -eq "On")
          {
             FindAndSetValue $ui RadioButton "Illustrated" $toggleEachAiEffect[9]
             FindAndSetValue $ui RadioButton "Animated" $toggleEachAiEffect[10]
             FindAndSetValue $ui RadioButton "Watercolor" $toggleEachAiEffect[11]
              
          }
       }
       CloseApp 'systemsettings'
       
       #Checks if frame server is stopped
       Write-Output "Entering CheckServiceState function"
       CheckServiceState 'Windows Camera Frame Server'
                             
       #Strating to collect Traces
       StartTrace $scenarioLogFolder
       
       Write-Output "Start test for $camsnario"
       if($camsnario -eq "Recording")
       {
           #Start video recording and close the camera app once finished recording 
           $InitTimeCameraApp = StartVideoRecording "20"
           $cameraAppStartTime = $InitTimeCameraApp[-1]
           Write-Output "Camera App start time in UTC: ${cameraAppStartTime}"
       }
       else
       {   
           #Start Previewing and close the camera app once finished. 
           $InitTimeCameraApp = CameraPreviewing "20"
           $cameraAppStartTime = $InitTimeCameraApp[-1]
           Write-Output "Camera App start time in UTC: ${cameraAppStartTime}"
       }
       #Checks if frame server is stopped
       Write-Output "Entering CheckServiceState function"
       CheckServiceState 'Windows Camera Frame Server' 
       
       #Stop the Trace
       Write-Output "Entering StopTrace function"
       StopTrace $scenarioLogFolder                          
            
       #Verify and validate if proper logs are generated or not.        
       Verifylogs $scenarioLogFolder $scenarioID $startTime
       
       #calculate Time from camera app started until PC trace first frame processed
       Write-Output "Entering CheckInitTimeCameraApp function" 
       CheckInitTimeCameraApp $scenarioLogFolder $scenarioID $cameraAppStartTime
       
       if($camsnario -eq "Recording")
       {   
          if($VF -eq "On")
          { 
             #Verify and validate if proper logs are generated or not for Audio Blur.
             VerifyAudioBlurLogs $scenarioLogFolder 512 
          } 
           
           #Get the properties of latest video recording
           GetVideoDetails $scenarioLogFolder $pathLogsFolder
       }
       
       Write-Output "Entering GetContentOfLogFileAndCopyToTestSpecificLogFile function"
       GetContentOfLogFileAndCopyToTestSpecificLogFile $scenarioLogFolder
       
       #collect data for Reporting
       Reporting $Results "$pathLogsFolder\Report.txt"
   
    }
    catch
    {
        CloseApp 'WindowsCamera'
        CloseApp 'Taskmgr'
        StopTrace $scenarioLogFolder
        CheckServiceState 'Windows Camera Frame Server'
        Write-Output $_
        TestOutputMessage $scenarioLogFolder "Exception" $startTime $_.Exception.Message
        Reporting $Results "$pathLogsFolder\Report.txt"
        GetContentOfLogFileAndCopyToTestSpecificLogFile $scenarioLogFolder
        $getLogs = Get-Content -Path "$pathLogsFolder\$scenarioLogFolder\log.txt" -raw
        write-host $getLogs
        $logs = resolve-path "$pathLogsFolder\$scenarioLogFolder\log.txt"
        Write-Host "(Logs saved here:$logs)"
        SetSmartPlugState $token $SPId 1
        #TakeScreenshot 
       
        continue;
    }                                
}

function GetContentOfLogFileAndCopyToTestSpecificLogFile($scenarioLogFldr)
{   
    #copy logs to test specific folder
    $logCopyFrom = "$pathLogsFolder\$logFile"
    $logCopyTo =  "$pathLogsFolder\$scenarioLogFldr\log.txt" 
    $search="Starting Test for "
    $linenumber = Get-Content $logCopyFrom | select-string $search | Select-Object -Last 1
    $lne = $linenumber.LineNumber - 1
    Get-Content -Path $logCopyFrom | Select -Skip $lne > $logCopyTo 
    
}
function RetrieveValue($inputValue)
{
 
   $returnValues = @{}
   $key = 'AF'
   $value = ("On","Off","Off","False","False","Off","False","False","Off","Fasle","False","False","AF","65536")
   $returnValues.Add($key, $value)
   $returnValues.Add('EC' , ("Off","Off","Off","False","False","On","True","False","Off","Fasle","False","False","ECS","16"))
   $returnValues.Add('AF+EC' , ("On","Off","Off","False","False","On","True","False","Off","Fasle","False","False","AF+ECS","65552"))
   

   $wsev2PolicyState = CheckWSEV2Policy
   if($wsev2PolicyState -eq $false)
   {
      $returnValues.Add('BBS' , ("Off","Off","On","True","False","Off","False","False","Off","Fasle","False","False","BBS","96"))
      $returnValues.Add('BBP' , ("Off","Off","On","False","True","Off","False","False","Off","Fasle","False","False","BBP","16416"))
      $returnValues.Add('AF+BBS' , ("On","Off","On","True","False","Off","False","False","Off","Fasle","False","False","AF+BBS","65632"))
      $returnValues.Add('AF+BBP' , ("On","Off","On","False","True","Off","False","False","Off","Fasle","False","False","AF+BBP","81952"))
      $returnValues.Add('BBS+EC' , ("Off","Off","On","True","False","On","True","False","Off","Fasle","False","False","BBS+ECS","112"))
      $returnValues.Add('BBP+EC' , ("Off","Off","On","False","True","On","True","False","Off","Fasle","False","False","BBP+ECS","16432"))
      $returnValues.Add('AF+BBS+EC', ("On","Off","On","True","False","On","True","False","Off","Fasle","False","False","AF+BBS+ECS","65648"))
      $returnValues.Add('AF+BBP+EC', ("On","Off","On","False","True","On","True","False","Off","Fasle","False","False","AF+BBP+ECS","81968"))
   }

   $wsev2PolicyState = CheckWSEV2Policy
   if($wsev2PolicyState -eq $true)
   {  
      $returnValues.Add('BBS' , ("Off","Off","On","True","False","Off","False","False","Off","Fasle","False","False","BBS","64"))
      $returnValues.Add('BBP' , ("Off","Off","On","False","True","Off","False","False","Off","Fasle","False","False","BBP","16384"))
      $returnValues.Add('AF+BBS' , ("On","Off","On","True","False","Off","False","False","Off","Fasle","False","False","AF+BBS","65600"))
      $returnValues.Add('AF+BBP' , ("On","Off","On","False","True","Off","False","False","Off","Fasle","False","False","AF+BBP","81920"))
      $returnValues.Add('BBS+EC' , ("Off","Off","On","True","False","On","True","False","Off","Fasle","False","False","BBS+ECS","80"))
      $returnValues.Add('BBP+EC' , ("Off","Off","On","False","True","On","True","False","Off","Fasle","False","False","BBP+ECS","16400"))
      $returnValues.Add('AF+BBS+EC', ("On","Off","On","True","False","On","True","False","Off","Fasle","False","False","AF+BBS+ECS","65616"))
      $returnValues.Add('AF+BBP+EC', ("On","Off","On","False","True","On","True","False","Off","Fasle","False","False","AF+BBP+ECS","81936"))

      $returnValues.Add('ECE' , ("Off","Off","Off","False","False","On","False","True","Off","Fasle","False","False","ECE","131072"))
      $returnValues.Add('PL' ,  ("Off","On","Off","False","False","Off","False","False","Off","Fasle","False","False","PL","524288"))
      $returnValues.Add('AF+PL' , ("On","On","Off","False","False","Off","False","False","Off","Fasle","False","False","AF+PL","589824"))
      $returnValues.Add('AF+ECE' , ("On","Off","Off","False","False","On","False","True","Off","Fasle","False","False","AF+ECE","196608"))
      $returnValues.Add('PL+BBS' , ("Off","On","On","True","False","Off","False","False","Off","Fasle","False","False","PL+BBS","524352"))
      $returnValues.Add('PL+BBP' , ("Off","On","On","False","True","Off","False","False","Off","Fasle","False","False","PL+BBP","540672"))
      $returnValues.Add('PL+EC' , ("Off","On","Off","False","False","On","True","False","Off","Fasle","False","False","PL+ECS","524304"))
      $returnValues.Add('PL+ECE' , ("Off","On","Off","False","False","On","False","True","Off","Fasle","False","False","PL+ECE","655360"))
      $returnValues.Add('BBS+ECE' , ("Off","Off","On","True","False","On","False","True","Off","Fasle","False","False","BBS+ECE","131136"))
      $returnValues.Add('BBP+ECE' , ("Off","Off","On","False","True","On","False","True","Off","Fasle","False","False","BBP+ECE","147456"))
      $returnValues.Add('AF+PL+BBS', ("On","On","On","True","False","Off","False","False","Off","Fasle","False","False","AF+PL+BBS","589888"))
      $returnValues.Add('AF+PL+BBP', ("On","On","On","False","True","Off","False","False","Off","Fasle","False","False","AF+PL+BBP","606208"))
      $returnValues.Add('AF+PL+EC', ("On","On","Off","False","False","On","True","False","Off","Fasle","False","False","AF+PL+ECS","589840"))
      $returnValues.Add('AF+PL+ECE', ("On","On","Off","False","False","On","False","True","Off","Fasle","False","False","AF+PL+ECE","720896"))
      $returnValues.Add('AF+BBS+ECE', ("On","Off","On","True","False","On","False","True","Off","Fasle","False","False","AF+BBS+ECE","196672"))
      $returnValues.Add('AF+BBP+ECE', ("On","Off","On","False","True","On","False","True","Off","Fasle","False","False","AF+BBP+ECE","212992"))
      $returnValues.Add('Pl+BBS+EC', ("Off","On","On","True","False","On","True","False","Off","Fasle","False","False","Pl+BBS+ECS","524368"))
      $returnValues.Add('Pl+BBP+EC', ("Off","On","On","False","True","On","True","False","Off","Fasle","False","False","Pl+BBP+ECS","540688"))
      $returnValues.Add('Pl+BBS+ECE', ("Off","On","On","True","False","On","False","True","Off","Fasle","False","False","Pl+BBS+ECE","655424"))
      $returnValues.Add('Pl+BBP+ECE', ("Off","On","On","False","True","On","False","True","Off","Fasle","False","False","Pl+BBP+ECE","671744"))
      $returnValues.Add('AF+Pl+BBS+EC', ("On","On","On","True","False","On","True","False","Off","Fasle","False","False","AF+Pl+BBS+ECS","589904"))
      $returnValues.Add('AF+Pl+BBS+ECE', ("On","On","On","True","False","On","False","True","Off","Fasle","False","False","AF+Pl+BBS+ECE","720960"))
      $returnValues.Add('AF+Pl+BBP+EC', ("On","On","On","False","True","On","True","False","Off","Fasle","False","False","AF+Pl+BBP+ECS","606224"))
      $returnValues.Add('AF+Pl+BBP+ECE', ("On","On","On","False","True","On","False","True","Off","Fasle","False","False","AF+Pl+BBP+ECE","737280"))
       
      $returnValues.Add('CF-I' ,  ("Off","Off","Off","False","False","Off","False","False","On","True","False","False","CF-I","2097152"))
      $returnValues.Add('AF+CF-I' ,  ("On","Off","Off","False","False","Off","False","False","On","True","False","False","AF+CF-I","2162688"))
      $returnValues.Add('AF+CF-I+PL' ,  ("On","On","Off","False","False","Off","False","False","On","True","False","False","AF+CF-I+PL","2686976"))
      $returnValues.Add('AF+CF-I+EC' ,  ("On","Off","Off","False","False","On","True","False","On","True","False","False","AF+CF-I+ECS","2162704"))
      $returnValues.Add('AF+CF-I+ECE' ,  ("On","Off","Off","False","False","On","False","True","On","True","False","False","AF+CF-I+ECE","2293760"))
      $returnValues.Add('AF+CF-I+BBS' ,  ("On","Off","On","True","False","Off","False","False","On","True","False","False","AF+CF-I+BBS","2162752"))
      $returnValues.Add('AF+CF-I+BBP' ,  ("On","Off","On","False","True","Off","False","False","On","True","False","False","AF+CF-I+BBP","2179072"))
      $returnValues.Add('AF+CF-I+PL+EC' ,  ("On","On","Off","False","False","On","True","False","On","True","False","False","AF+CF-I+PL+ECS","2686992"))
      $returnValues.Add('AF+CF-I+PL+ECE' ,  ("On","On","Off","False","False","On","False","True","On","True","False","False","AF+CF-I+PL+ECE","2818048"))
      $returnValues.Add('AF+CF-I+PL+BBS' ,  ("On","On","On","True","False","Off","False","False","On","True","False","False","AF+CF-I+PL+BBS","2687040"))
      $returnValues.Add('AF+CF-I+PL+BBP' ,  ("On","On","On","False","True","Off","False","False","On","True","False","False","AF+CF-I+PL+BBP","2703360"))
      $returnValues.Add('AF+CF-I+EC+BBS' ,  ("On","Off","On","True","False","On","True","False","On","True","False","False","AF+CF-I+ECS+BBS","2162768"))
      $returnValues.Add('AF+CF-I+EC+BBP' ,  ("On","Off","On","false","True","On","True","False","On","True","False","False","AF+CF-I+ECS+BBP","2179088"))
      $returnValues.Add('AF+CF-I+ECE+BBS' ,  ("On","Off","On","True","False","On","False","true","On","True","False","False","AF+CF-I+ECE+BBS","2293824"))
      $returnValues.Add('AF+CF-I+ECE+BBP' ,  ("On","Off","On","False","True","On","False","true","On","True","False","False","AF+CF-I+ECE+BBP","2310144"))
      $returnValues.Add('AF+CF-I+PL+EC+BBS' ,  ("On","On","On","True","False","On","True","False","On","True","False","False","AF+CF-I+PL+ECS+BBS","2687056"))
      $returnValues.Add('AF+CF-I+PL+EC+BBP' ,  ("On","On","On","False","True","On","True","False","On","True","False","False","AF+CF-I+ECS+BBP","2703376"))
      $returnValues.Add('AF+CF-I+PL+ECE+BBS' ,  ("On","On","On","True","False","On","False","True","On","True","False","False","AF+CF-I+PL+ECE+BBS","2818112"))
      $returnValues.Add('AF+CF-I+PL+ECE+BBP' ,  ("On","On","On","False","True","On","False","True","On","True","False","False","AF+CF-I+PL+ECE+BBP","2834432"))
      $returnValues.Add('PL+CF-I' ,  ("Off","On","Off","False","False","Off","False","False","On","True","False","False","PL+CF-I","2621440"))
      $returnValues.Add('PL+CF-I+EC' ,  ("Off","On","Off","False","False","On","True","False","On","True","False","False","PL+CF-I+ECS","2621456"))
      $returnValues.Add('PL+CF-I+ECE' ,  ("Off","On","Off","False","False","On","False","True","On","True","False","False","PL+CF-I+ECE","2752512"))
      $returnValues.Add('PL+CF-I+BBS' ,  ("Off","On","On","True","False","Off","false","False","On","True","False","False","PL+CF-I+BBS","2621504"))
      $returnValues.Add('PL+CF-I+BBP' ,  ("Off","On","On","False","True","Off","false","False","On","True","False","False","PL+CF-I+BBP","2637824"))
      $returnValues.Add('PL+CF-I+EC+BBS' ,  ("Off","On","On","True","False","On","True","False","On","True","False","False","PL+CF-I+ECS+BBS","2621520"))
      $returnValues.Add('PL+CF-I+EC+BBP' ,  ("Off","On","On","False","True","On","True","False","On","True","False","False","PL+CF-I+ECS+BBP","2637840"))
      $returnValues.Add('PL+CF-I+ECE+BBS' ,  ("Off","On","On","True","False","On","false","True","On","True","False","False","PL+CF-I+ECE+BBS","2752576"))
      $returnValues.Add('PL+CF-I+ECE+BBP' ,  ("Off","On","On","False","True","On","False","True","On","True","False","False","PL+CF-I+ECE+BBP","2768896"))
      $returnValues.Add('EC+CF-I' ,  ("Off","Off","Off","False","False","On","True","False","On","True","False","False","ECS+CF-I","2097168"))
      $returnValues.Add('ECE+CF-I' ,  ("Off","Off","Off","False","False","On","False","True","On","True","False","False","ECE+CF-I","2228224"))
      $returnValues.Add('EC+CF-I+BBS' ,  ("Off","Off","On","True","False","On","True","False","On","True","False","False","ECS+CF-I+BBS","2097232"))
      $returnValues.Add('EC+CF-I+BBP' ,  ("Off","Off","On","False","True","On","True","False","On","True","False","False","ECS+CF-I+BBP","2113552"))
      $returnValues.Add('ECE+CF-I+BBS' ,  ("Off","Off","On","True","False","On","False","True","On","True","False","False","ECE+CF-I+BBS","2228288"))
      $returnValues.Add('ECE+CF-I+BBP' ,  ("Off","Off","On","False","True","On","False","True","On","True","False","False","ECE+CF-I+BBP","2244608"))
      $returnValues.Add('BBS+CF-I' ,  ("Off","Off","On","True","False","Off","False","False","On","True","False","False","BBS+CF-I","2097216"))
      $returnValues.Add('BBP+CF-I' ,  ("Off","Off","On","False","True","Off","False","False","On","True","False","False","BBP+CF-I","2113536"))

      $returnValues.Add('CF-A' ,  ("Off","Off","Off","False","False","Off","False","False","On","False","True","False","CF-A","2097152"))
      $returnValues.Add('AF+CF-A' ,  ("On","Off","Off","False","False","Off","False","False","On","False","True","False","AF+CF-A","2162688"))
      $returnValues.Add('AF+CF-A+PL' ,  ("On","On","Off","False","False","Off","False","False","On","False","True","False","AF+CF-A+PL","2686976"))
      $returnValues.Add('AF+CF-A+EC' ,  ("On","Off","Off","False","False","On","True","False","On","False","True","False","AF+CF-A+ECS","2162704"))
      $returnValues.Add('AF+CF-A+ECE' ,  ("On","Off","Off","False","False","On","False","True","On","False","True","False","AF+CF-A+ECE","2293760"))
      $returnValues.Add('AF+CF-A+BBS' ,  ("On","Off","On","True","False","Off","False","False","On","False","True","False","AF+CF-A+BBS","2162752"))
      $returnValues.Add('AF+CF-A+BBP' ,  ("On","Off","On","False","True","Off","False","False","On","False","True","False","AF+CF-A+BBP","2179072"))
      $returnValues.Add('AF+CF-A+PL+EC' ,  ("On","On","Off","False","False","On","True","False","On","False","True","False","AF+CF-A+PL+ECS","2686992"))
      $returnValues.Add('AF+CF-A+PL+ECE' ,  ("On","On","Off","False","False","On","False","True","On","False","True","False","AF+CF-A+PL+ECE","2818048"))
      $returnValues.Add('AF+CF-A+PL+BBS' ,  ("On","On","On","True","False","Off","False","False","On","False","True","False","AF+CF-A+PL+BBS","2687040"))
      $returnValues.Add('AF+CF-A+PL+BBP' ,  ("On","On","On","False","True","Off","False","False","On","False","True","False","AF+CF-A+PL+BBP","2703360"))
      $returnValues.Add('AF+CF-A+EC+BBS' ,  ("On","Off","On","True","False","On","True","False","On","False","True","False","AF+CF-A+ECS+BBS","2162768"))
      $returnValues.Add('AF+CF-A+EC+BBP' ,  ("On","Off","On","false","True","On","True","False","On","False","True","False","AF+CF-A+ECS+BBP","2179088"))
      $returnValues.Add('AF+CF-A+ECE+BBS' ,  ("On","Off","On","True","False","On","False","true","On","False","True","False","AF+CF-A+ECE+BBS","2293824"))
      $returnValues.Add('AF+CF-A+ECE+BBP' ,  ("On","Off","On","False","True","On","False","true","On","False","True","False","AF+CF-A+ECE+BBP","2310144"))
      $returnValues.Add('AF+CF-A+PL+EC+BBS' ,  ("On","On","On","True","False","On","True","False","On","False","True","False","AF+CF-A+PL+ECS+BBS","2687056"))
      $returnValues.Add('AF+CF-A+PL+EC+BBP' ,  ("On","On","On","False","True","On","True","False","On","False","True","False","AF+CF-A+ECS+BBP","2703376"))
      $returnValues.Add('AF+CF-A+PL+ECE+BBS' ,  ("On","On","On","True","False","On","False","True","On","False","True","False","AF+CF-A+PL+ECE+BBS","2818112"))
      $returnValues.Add('AF+CF-A+PL+ECE+BBP' ,  ("On","On","On","False","True","On","False","True","On","False","True","False","AF+CF-A+PL+ECE+BBP","2834432"))
      $returnValues.Add('PL+CF-A' ,  ("Off","On","Off","False","False","Off","False","False","On","False","True","False","PL+CF-A","2621440"))
      $returnValues.Add('PL+CF-A+EC' ,  ("Off","On","Off","False","False","On","True","False","On","False","True","False","PL+CF-A+ECS","2621456"))
      $returnValues.Add('PL+CF-A+ECE' ,  ("Off","On","Off","False","False","On","False","True","On","False","True","False","PL+CF-A+ECE","2752512"))
      $returnValues.Add('PL+CF-A+BBS' ,  ("Off","On","On","True","False","Off","false","False","On","False","True","False","PL+CF-A+BBS","2621504"))
      $returnValues.Add('PL+CF-A+BBP' ,  ("Off","On","On","False","True","Off","false","False","On","False","True","False","PL+CF-A+BBP","2637824"))
      $returnValues.Add('PL+CF-A+EC+BBS' ,  ("Off","On","On","True","False","On","True","False","On","False","True","False","PL+CF-A+ECS+BBS","2621520"))
      $returnValues.Add('PL+CF-A+EC+BBP' ,  ("Off","On","On","False","True","On","True","False","On","False","True","False","PL+CF-A+ECS+BBP","2637840"))
      $returnValues.Add('PL+CF-A+ECE+BBS' ,  ("Off","On","On","True","False","On","false","True","On","False","True","False","PL+CF-A+ECE+BBS","2752576"))
      $returnValues.Add('PL+CF-A+ECE+BBP' ,  ("Off","On","On","False","True","On","False","True","On","False","True","False","PL+CF-A+ECE+BBP","2768896"))
      $returnValues.Add('EC+CF-A' ,  ("Off","Off","Off","False","False","On","True","False","On","False","True","False","ECS+CF-A","2097168"))
      $returnValues.Add('ECE+CF-A' ,  ("Off","Off","Off","False","False","On","False","True","On","False","True","False","ECE+CF-A","2228224"))
      $returnValues.Add('EC+CF-A+BBS' ,  ("Off","Off","On","True","False","On","True","False","On","False","True","False","ECS+CF-A+BBS","2097232"))
      $returnValues.Add('EC+CF-A+BBP' ,  ("Off","Off","On","False","True","On","True","False","On","False","True","False","ECS+CF-A+BBP","2113552"))
      $returnValues.Add('ECE+CF-A+BBS' ,  ("Off","Off","On","True","False","On","False","True","On","False","True","False","ECE+CF-A+BBS","2228288"))
      $returnValues.Add('ECE+CF-A+BBP' ,  ("Off","Off","On","False","True","On","False","True","On","False","True","False","ECE+CF-A+BBP","2244608"))
      $returnValues.Add('BBS+CF-A' ,  ("Off","Off","On","True","False","Off","False","False","On","False","True","False","BBS+CF-A","2097216"))
      $returnValues.Add('BBP+CF-A' ,  ("Off","Off","On","False","True","Off","False","False","On","False","True","False","BBP+CF-A","2113536"))

      $returnValues.Add('CF-W' ,  ("Off","Off","Off","False","False","Off","False","False","On","False","False","True","CF-W","2097152"))
      $returnValues.Add('AF+CF-W' ,  ("On","Off","Off","False","False","Off","False","False","On","False","False","True","AF+CF-W","2162688"))
      $returnValues.Add('AF+CF-W+PL' ,  ("On","On","Off","False","False","Off","False","False","On","False","False","True","AF+CF-W+PL","2686976"))
      $returnValues.Add('AF+CF-W+EC' ,  ("On","Off","Off","False","False","On","True","False","On","False","False","True","AF+CF-W+ECS","2162704"))
      $returnValues.Add('AF+CF-W+ECE' ,  ("On","Off","Off","False","False","On","False","True","On","False","False","True","AF+CF-W+ECE","2293760"))
      $returnValues.Add('AF+CF-W+BBS' ,  ("On","Off","On","True","False","Off","False","False","On","False","False","True","AF+CF-W+BBS","2162752"))
      $returnValues.Add('AF+CF-W+BBP' ,  ("On","Off","On","False","True","Off","False","False","On","False","False","True","AF+CF-W+BBP","2179072"))
      $returnValues.Add('AF+CF-W+PL+EC' ,  ("On","On","Off","False","False","On","True","False","On","False","False","True","AF+CF-W+PL+ECS","2686992"))
      $returnValues.Add('AF+CF-W+PL+ECE' ,  ("On","On","Off","False","False","On","False","True","On","False","False","True","AF+CF-W+PL+ECE","2818048"))
      $returnValues.Add('AF+CF-W+PL+BBS' ,  ("On","On","On","True","False","Off","False","False","On","False","False","True","AF+CF-W+PL+BBS","2687040"))
      $returnValues.Add('AF+CF-W+PL+BBP' ,  ("On","On","On","False","True","Off","False","False","On","False","False","True","AF+CF-W+PL+BBP","2703360"))
      $returnValues.Add('AF+CF-W+EC+BBS' ,  ("On","Off","On","True","False","On","True","False","On","False","False","True","AF+CF-W+ECS+BBS","2162768"))
      $returnValues.Add('AF+CF-W+EC+BBP' ,  ("On","Off","On","false","True","On","True","False","On","False","False","True","AF+CF-W+ECS+BBP","2179088"))
      $returnValues.Add('AF+CF-W+ECE+BBS' ,  ("On","Off","On","True","False","On","False","true","On","False","False","True","AF+CF-W+ECE+BBS","2293824"))
      $returnValues.Add('AF+CF-W+ECE+BBP' ,  ("On","Off","On","False","True","On","False","true","On","False","False","True","AF+CF-W+ECE+BBP","2310144"))
      $returnValues.Add('AF+CF-W+PL+EC+BBS' ,  ("On","On","On","True","False","On","True","False","On","False","False","True","AF+CF-W+PL+ECS+BBS","2687056"))
      $returnValues.Add('AF+CF-W+PL+EC+BBP' ,  ("On","On","On","False","True","On","True","False","On","False","False","True","AF+CF-W+ECS+BBP","2703376"))
      $returnValues.Add('AF+CF-W+PL+ECE+BBS' ,  ("On","On","On","True","False","On","False","True","On","False","False","True","AF+CF-W+PL+ECE+BBS","2818112"))
      $returnValues.Add('AF+CF-W+PL+ECE+BBP' ,  ("On","On","On","False","True","On","False","True","On","False","False","True","AF+CF-W+PL+ECE+BBP","2834432"))
      $returnValues.Add('PL+CF-W' ,  ("Off","On","Off","False","False","Off","False","False","On","False","False","True","PL+CF-W","2621440"))
      $returnValues.Add('PL+CF-W+EC' ,  ("Off","On","Off","False","False","On","True","False","On","False","False","True","PL+CF-W+ECS","2621456"))
      $returnValues.Add('PL+CF-W+ECE' ,  ("Off","On","Off","False","False","On","False","True","On","False","False","True","PL+CF-W+ECE","2752512"))
      $returnValues.Add('PL+CF-W+BBS' ,  ("Off","On","On","True","False","Off","false","False","On","False","False","True","PL+CF-W+BBS","2621504"))
      $returnValues.Add('PL+CF-W+BBP' ,  ("Off","On","On","False","True","Off","false","False","On","False","False","True","PL+CF-W+BBP","2637824"))
      $returnValues.Add('PL+CF-W+EC+BBS' ,  ("Off","On","On","True","False","On","True","False","On","False","False","True","PL+CF-W+ECS+BBS","2621520"))
      $returnValues.Add('PL+CF-W+EC+BBP' ,  ("Off","On","On","False","True","On","True","False","On","False","False","True","PL+CF-W+ECS+BBP","2637840"))
      $returnValues.Add('PL+CF-W+ECE+BBS' ,  ("Off","On","On","True","False","On","false","True","On","False","False","True","PL+CF-W+ECE+BBS","2752576"))
      $returnValues.Add('PL+CF-W+ECE+BBP' ,  ("Off","On","On","False","True","On","False","True","On","False","False","True","PL+CF-W+ECE+BBP","2768896"))
      $returnValues.Add('EC+CF-W' ,  ("Off","Off","Off","False","False","On","True","False","On","False","False","True","ECS+CF-W","2097168"))
      $returnValues.Add('ECE+CF-W' ,  ("Off","Off","Off","False","False","On","False","True","On","False","False","True","ECE+CF-W","2228224"))
      $returnValues.Add('EC+CF-W+BBS' ,  ("Off","Off","On","True","False","On","True","False","On","False","False","True","ECS+CF-W+BBS","2097232"))
      $returnValues.Add('EC+CF-W+BBP' ,  ("Off","Off","On","False","True","On","True","False","On","False","False","True","ECS+CF-W+BBP","2113552"))
      $returnValues.Add('ECE+CF-W+BBS' ,  ("Off","Off","On","True","False","On","False","True","On","False","False","True","ECE+CF-W+BBS","2228288"))
      $returnValues.Add('ECE+CF-W+BBP' ,  ("Off","Off","On","False","True","On","False","True","On","False","False","True","ECE+CF-W+BBP","2244608"))
      $returnValues.Add('BBS+CF-W' ,  ("Off","Off","On","True","False","Off","False","False","On","False","False","True","BBS+CF-W","2097216"))
      $returnValues.Add('BBP+CF-W' ,  ("Off","Off","On","False","True","Off","False","False","On","False","False","True","BBP+CF-W","2113536"))

   }
   $returnValues.Add('1440p' , "1440p, 16 by 9 aspect ratio, 30 fps")
   $returnValues.Add('1080p' , "1080p, 16 by 9 aspect ratio, 30 fps")
   $returnValues.Add('720p' , "720p, 16 by 9 aspect ratio, 30 fps")
   $returnValues.Add('480p' , "480p, 4 by 3 aspect ratio, 30 fps")
   $returnValues.Add('360p' , "360p, 16 by 9 aspect ratio, 30 fps")
   $returnValues.Add('1440p1' , "1440p, 4 by 3 aspect ratio, 30 fps")
   $returnValues.Add('1080p1' , "1080p, 4 by 3 aspect ratio, 30 fps")
   $returnValues.Add('960p' , "960p, 4 by 3 aspect ratio, 30 fps")
   $returnValues.Add('640p' , "640p, 1 by 1 aspect ratio, 30 fps")
   $returnValues.Add('540p' , "540p, 16 by 9 aspect ratio, 30 fps")
   $returnValues.Add('8.3MP' , "8.3 megapixels, 16 by 9 aspect ratio,  3840 by 2160 resolution")
   $returnValues.Add('12.2MP' ,  "12.2 megapixels, 4 by 3 aspect ratio,  4032 by 3024 resolution")
   $returnValues.Add('5.0MP' , "5.0 megapixels, 4 by 3 aspect ratio,  2592 by 1944 resolution")
   $returnValues.Add('4.5MP' , "4.5 megapixels, 3 by 2 aspect ratio,  2592 by 1728 resolution")
   $returnValues.Add('3.8MP' , "3.8 megapixels, 16 by 9 aspect ratio,  2592 by 1458 resolution")
   $returnValues.Add('2.1MP' ,  "2.1 megapixels, 16 by 9 aspect ratio,  1920 by 1080 resolution")
   $returnValues.Add('0.9MP' , "0.9 megapixels, 16 by 9 aspect ratio,  1280 by 720 resolution")
   $returnValues.Add('0.8MP' , "0.8 megapixels, 4 by 3 aspect ratio,  1024 by 768 resolution")
   $returnValues.Add('0.3MP' , "0.3 megapixels, 4 by 3 aspect ratio,  640 by 480 resolution")
   $returnValues.Add('0.2MP' , "0.2 megapixels, 16 by 9 aspect ratio,  640 by 360 resolution")
   $returnValues.Add("1440p, 16 by 9 aspect ratio, 30 fps" ,'1440p')
   $returnValues.Add("1080p, 16 by 9 aspect ratio, 30 fps" , '1080p')
   $returnValues.Add("720p, 16 by 9 aspect ratio, 30 fps" , '720p')
   $returnValues.Add("480p, 4 by 3 aspect ratio, 30 fps" , '480p')
   $returnValues.Add("360p, 16 by 9 aspect ratio, 30 fps" , '360p')
   $returnValues.Add("1440p, 4 by 3 aspect ratio, 30 fps" , '1440p1')
   $returnValues.Add("1080p, 4 by 3 aspect ratio, 30 fps" , '1080p1')
   $returnValues.Add("960p, 4 by 3 aspect ratio, 30 fps" , '960p')
   $returnValues.Add("640p, 1 by 1 aspect ratio, 30 fps" , '640p')
   $returnValues.Add("540p, 16 by 9 aspect ratio, 30 fps" , '540p')
   $returnValues.Add("8.3 megapixels, 16 by 9 aspect ratio,  3840 by 2160 resolution" , '8.3MP')
   $returnValues.Add("12.2 megapixels, 4 by 3 aspect ratio,  4032 by 3024 resolution" , '12.2MP')
   $returnValues.Add("5.0 megapixels, 4 by 3 aspect ratio,  2592 by 1944 resolution" ,'5.0MP')
   $returnValues.Add("4.5 megapixels, 3 by 2 aspect ratio,  2592 by 1728 resolution" ,'4.5MP')
   $returnValues.Add("3.8 megapixels, 16 by 9 aspect ratio,  2592 by 1458 resolution" ,'3.8MP')
   $returnValues.Add("2.1 megapixels, 16 by 9 aspect ratio,  1920 by 1080 resolution" ,'2.1MP')
   $returnValues.Add("0.9 megapixels, 16 by 9 aspect ratio,  1280 by 720 resolution" ,'0.9MP')
   $returnValues.Add("0.8 megapixels, 4 by 3 aspect ratio,  1024 by 768 resolution" ,'0.8MP')
   $returnValues.Add("0.3 megapixels, 4 by 3 aspect ratio,  640 by 480 resolution" , '0.3MP')
   $returnValues.Add("0.2 megapixels, 16 by 9 aspect ratio,  640 by 360 resolution" ,'0.2MP')
   
   $outputValue = $returnValues[$inputValue]
   return $outputValue
}   
      