Add-Type -AssemblyName System.Windows.Forms

function ToggleAiEffectsInCameraApp($AFVal,$PLVal,$BBVal,$BSVal,$BPVal,$ECVal,$ECSVal,$ECEVal,$CF,$CFI,$CFA,$CFW)
{   

   #Open Camera App
   Write-Output "Open camera App"
   $uiEle = OpenApp 'microsoft.windows.camera:' 'Camera'
   Start-Sleep -s 1

   #Switch to video mode
   SwitchModeInCameraApp $uiEle "Switch to video mode" "Take video" 
   Start-Sleep -s 2

   #Open Windows Studio effects and toggle AI effects
   Write-Output "Navigate to Windows Studio Effects"
   
   $exists = CheckIfElementExists $uiEle ToggleButton "Windows Studio effects"
   if ($exists)
   {
      FindAndClick $uiEle ToggleButton "Windows Studio effects"
   }
   else
   {
      $exists = CheckIfElementExists $uiEle ToggleButton "Windows Studio Effects"
      if ($exists)
	   {
         FindAndClick $uiEle ToggleButton "Windows Studio Effects"
      }
      else
      {
         $exists = CheckIfElementExists $uiEle ToggleButton "Effects"
         if ($exists)
         {
             FindAndClick $uiEle ToggleButton "Effects"
             Write-Host "   Error- Camera App UI only diplays Effects for WSE" -BackgroundColor Yellow
         }
         else
         {
            Write-Error " Windows Studio Effects not found in Camera App UI" -ErrorAction Stop     
         } 
      }
   }
   Start-Sleep -s 1
   
   Write-Output "Toggle camera effects in camera App UI"   
   FindAndSetValue $uiEle ToggleSwitch "Automatic framing" $AFVal
   FindAndSetValue $uiEle ToggleSwitch "Eye contact" $ECVal
   FindAndSetValue $uiEle ToggleSwitch "Background effects" $BBVal
   Start-Sleep -s 1
   if($BBVal -eq "On")
   {
      FindAndSetValue $uiEle RadioButton "Standard blur" $BSVal  
      FindAndSetValue $uiEle RadioButton "Portrait blur" $BPVal
   }
   $wsev2PolicyState = CheckWSEV2Policy
   if($wsev2PolicyState -eq $true)
   {
      Start-Sleep -s 1
      FindAndSetValue $uiEle  ToggleSwitch "Portrait light" $PLVal
      FindAndSetValue $uiEle  ToggleSwitch "Creative filters" $CF
      if($CF -eq "On")
      {  
         Start-Sleep -s 1 
         FindAndSetValue $uiEle  RadioButton "Illustrated" $CFI
         FindAndSetValue $uiEle  RadioButton "Animated" $CFA
         FindAndSetValue $uiEle  RadioButton "Water color" $CFW

      }
      if($ECVal -eq "On")
      { 
         Start-Sleep -s 1 
         FindAndSetValue $uiEle  RadioButton "Standard" $ECSVal
         FindAndSetValue $uiEle  RadioButton "Teleprompter" $ECEVal
      }
   }
   #Close camera App
   CloseApp 'WindowsCamera'
}

function SetDefaultSettingInCameraApp($uiEle, $selSetting)
{
          
     #Set Default setting to "Use System settings"
     Write-Output "Set default setting to $selSetting"
     FindAndClick $uiEle Button "Open Settings Menu"
     Start-Sleep -s 1
     FindAndClick $uiEle Microsoft.UI.Xaml.Controls.Expander "Camera settings"
     Start-Sleep -s 1
     FindAndClick $uiEle ComboBox "Default settings - These settings apply to the Camera app at the start of each session"
     Start-Sleep -s 1
     FindAndClick $uiEle ComboBoxItem $selSetting
     Start-Sleep -s 1
     FindAndClick $uiEle Button "Back"
     Start-Sleep -s 2
     
     #Close camera App
     CloseApp 'WindowsCamera'
}

function SwitchModeInCameraApp($uiEle, $swtchMde, $chkEle) 
{
    $return = CheckIfElementExists $uiEle ToggleButton $chkEle
    if ($return -eq $null){
        Write-Output "$swtchMde"
        FindAndClick $uiEle Button $swtchMde
        Start-Sleep -s 2  
    }
    else
    {
       Write-Output "Already in $chkEle mode"
       Start-Sleep -s 2 
    }
}
function StartVideoRecording($scnds)
{  
     #Open Camera App
     Write-Output "Open camera App"
     $ui = OpenApp 'microsoft.windows.camera:' 'Camera'
     Start-Sleep -s 1

     #Capture the start time for Camera App
     $cameraApp = Get-Process -Name WindowsCamera | select starttime
     $cameraAppStart = $cameraApp.StartTime

     #Set time zone to UTC as Asg trace logs are using UTC date format
     $cameraAppStartinUTC = $cameraAppStart.ToUniversalTime()
     
     #Convert the date to string format to add the milliseconds 
     $cameraAppStartTostring = $cameraAppStartinUTC.ToString('yyyy/MM/dd HH:mm:ss:fff')
     
     #Coverting the string back to date format for time calculation in code later in CheckInitTimeCameraApp function.
     $cameraAppStartTime = [System.DateTime]::ParseExact($cameraAppStartTostring,'yyyy/MM/dd HH:mm:ss:fff',$null)
                                  
     #Switch to video mode if not in video mode
     SwitchModeInCameraApp $ui "Switch to video mode" "Take video" 
     Start-Sleep -s 2
     
     #record video inbetween space presses
     Write-Output "Start recording a video for $scnds seconds"
     [System.Windows.Forms.SendKeys]::SendWait(' ');
     Start-Sleep -s $scnds
     [System.Windows.Forms.SendKeys]::SendWait(' ');
     Start-Sleep -s 2
     Write-Output "video recording stopped after $scnds seconds"
     
     #restores photo mode for the next run(This line will be uncommented once camera issue is fixed)
     #SwitchModeInCameraApp $ui "Switch to photo mode" "Take photo"
     Start-Sleep -s 2

     #Close camera App
     CloseApp 'WindowsCamera'
     Start-Sleep -s 1  

     #Return the value to pass as parameter to CheckInitTimeCameraApp function in camerae2eTest.ps1 and CameraAppTest.ps1
     return , $cameraAppStartTime 
}

function CameraPreviewing($scnds)
{  
     #Open Camera App
     Write-Output "Open camera App"
     $ui = OpenApp 'microsoft.windows.camera:' 'Camera'
     Start-Sleep -s 1

     #Capture the start time for Camera App
     $cameraApp = Get-Process -Name WindowsCamera | select starttime
     $cameraAppStart = $cameraApp.StartTime

     #Set time zone to UTC as Asg trace logs are using UTC date format
     $cameraAppStartinUTC = $cameraAppStart.ToUniversalTime()
     
     #Convert the date to string format to add the milliseconds 
     $cameraAppStartTostring = $cameraAppStartinUTC.ToString('yyyy/MM/dd HH:mm:ss:fff')

     #Coverting the string back to date format for time calculation in code later CheckInitTimeCameraApp function.
     $cameraAppStartTime = [System.DateTime]::ParseExact($cameraAppStartTostring,'yyyy/MM/dd HH:mm:ss:fff',$null)
                          
     #Switch to video mode and start previewing as few photo resolution does not support MEP feature"
     SwitchModeInCameraApp $ui "Switch to video mode" "Take video" 
     Start-Sleep -s $scnds
     
     #Close camera App
     CloseApp 'WindowsCamera'
     Write-Output "Previewing stopped after $scnds seconds" 

     #Return the value to pass as parameter to CheckInitTimeCameraApp function in camerae2eTest.ps1 and CameraAppTest.ps1
     return , $cameraAppStartTime 
}
function SetvideoResolutionInCameraApp($snarioName, $strtTime, $vdoRes)
{      
     #Open Camera App
     Write-Output "Open camera App"
     $ui = OpenApp 'microsoft.windows.camera:' 'Camera'
     Start-Sleep -s 1

     #Switch to video mode if not in video mode(Note until we switch to video mode the changes made in video resolution does not persist)
     SwitchModeInCameraApp $ui "Switch to video mode" "Take video" 

     #set video quality 
     FindAndClick $ui Button "Open Settings Menu"
     Start-Sleep -s 1
     Write-output "Set video quality to $vdoRes"

     #Find video settings and click
     $exists = CheckIfElementExists $ui Microsoft.UI.Xaml.Controls.Expander "Videos settings"
     if ($exists)
     {
        FindAndClick $ui Microsoft.UI.Xaml.Controls.Expander "Videos settings"
     }
     else 
     { 
        $exists = CheckIfElementExists $ui Microsoft.UI.Xaml.Controls.Expander "Video settings"
        if ($exists)
        {
           FindAndClick $ui Microsoft.UI.Xaml.Controls.Expander "Video settings"
        }
        else
        {
           Write-Error "Video settings not found in camera App" -ErrorAction Stop     
        } 
     }
     Start-Sleep -s 1
     FindAndClick $ui ComboBox "Video quality"
     Start-Sleep -s 1

     #Select the video resolution if supported
     $return = CheckIfElementExists $ui ComboBoxItem $vdoRes
     if ($return -eq $null){
         TestOutputMessage $snarioName "Skipped" $strtTime  "unsupported resolution" 
         CloseApp 'WindowsCamera'
         return ,$false
     }
     else
     {
         FindAndClick $ui ComboBoxItem $vdoRes
         Start-Sleep -s 1
         CloseApp 'WindowsCamera'
     }
     
}
function SetphotoResolutionInCameraApp($snarioName, $strtTime, $photRes)
{    
     #Open Camera App
     Write-Output "Open camera App"
     $ui = OpenApp 'microsoft.windows.camera:' 'Camera'
     Start-Sleep -s 1

     #set photo quality
     FindAndClick $ui Button "Open Settings Menu"
     Start-Sleep -s 1 
     Write-output "Set photo quality to $photRes"

     #Find Photo settings and click
     $exists = CheckIfElementExists $ui Microsoft.UI.Xaml.Controls.Expander "Photos settings"
     if ($exists)
     {
        FindAndClick $ui Microsoft.UI.Xaml.Controls.Expander "Photos settings"
     }
     else 
     { 
        $exists = CheckIfElementExists $ui Microsoft.UI.Xaml.Controls.Expander "Photo settings"
        if ($exists)
        {
           FindAndClick $ui Microsoft.UI.Xaml.Controls.Expander "Photo settings"
        }
        else
        {
           Write-Error "Photo settings not found in camera App" -ErrorAction Stop     
        } 
     }
     Start-Sleep -s 1
     FindAndClick $ui ComboBox "Photo quality"
     Start-Sleep -s 1

     #Select the photo resolution if supported
     $return = CheckIfElementExists $ui ComboBoxItem $photRes
     if ($return -eq $null){
         TestOutputMessage $snarioName "Skipped" $strtTime  "unsupported resolution" 
         CloseApp 'WindowsCamera'
         return ,$false
     }
     else
     {
         FindAndClick $ui ComboBoxItem $photRes
         Start-Sleep -s 1
         CloseApp 'WindowsCamera'
         
     } 
}
function ValidateWSEInPhotoMode($snarioName)
{  
   $scenarioName = "$snarioName\ValidateWSEInPhotoMode"
   CreateScenarioLogsFolder $scenarioName 

   #Open Camera App
   Write-Output "Open camera App"
   $uiEle = OpenApp 'microsoft.windows.camera:' 'Camera'
   Start-Sleep -s 2

   #Switch to Photo mode
   SwitchModeInCameraApp $uiEle "Switch to photo mode" "Take photo" 
   Start-Sleep -s 1

   #Close camera App
   CloseApp 'WindowsCamera'
   Start-Sleep -s 1

   #Checks if frame server is stopped
   Write-Output "Entering CheckServiceState function"
   CheckServiceState 'Windows Camera Frame Server'
                 
   #Strating to collect Traces
   Write-Output "Entering StartTrace function"
   StartTrace $scenarioName
     
   #Open Camera App
   Write-Output "Open camera App"
   $uiEle = OpenApp 'microsoft.windows.camera:' 'Camera'
   Start-Sleep -s 1

   #Verify Windows Studio Effects not supported in Photo Mode
   Write-Output "Navigate to Windows Studio Effects"
   
   $exists = CheckIfElementExists $uiEle ToggleButton "Windows Studio effects"
   if ($exists)
   {
      Write-Host "   Error- Windows Studio Effects supported in Photo Mode " -ForegroundColor Yellow
   }
   else
   {
      Write-Output "Validation successful -Windows Studio Effects not supported in Photo Mode"
   } 
     
   #Close camera App
   CloseApp 'WindowsCamera'
   
   #Checks if frame server is stopped
   Write-Output "Entering CheckServiceState function"
   CheckServiceState 'Windows Camera Frame Server' 
   
   #Stop the Trace
   Write-Output "Entering StopTrace function"
   StopTrace $scenarioName
 
   #Validate PerceptionSessionUsageStats is not captured in PhotoMode. If PerceptionSessionUsageStats is captured, verify PC Scenario is not initialized 
   $pathAsgTraceTxt = "$pathLogsFolder\$scenarioName\" + "AsgTrace.txt"  
   $pattern = "PerceptionSessionUsageStats"
   $pcUsageStats = (Select-string -path  $pathAsgTraceTxt -Pattern $pattern)
   if($pcUsageStats.Length -eq 0)
   { 
      Write-Output "No PerceptionSessionUsageStats captured in Asgtrace while in PhotoMode"
   }
   else
   {
      Write-Output "PerceptionSessionUsageStats captured in Asgtrace while in PhotoMode " 
      $frameProcessingDetails = (Select-string -path $pathAsgTraceTxt -Pattern $pattern | Select-Object -Last 1) -split ","
            
      #Reading log file to verify PC Scenario is not initialized 
      $scenarioID = $frameProcessingDetails[8].Trim()

      if($scenarioID -eq 0)
      {
         Write-Output "No PerceptionCore Scenrio is initialized"
      }   
      else
      {
         Write-Host "   PerceptionCore Scenario is initialized and captured in Asgtrace while in PhotoMode " -ForegroundColor Yellow
      } 

   }
   #Open Camera App
   Write-Output "Open camera App"
   $uiEle = OpenApp 'microsoft.windows.camera:' 'Camera'
   Start-Sleep -s 1

   #Switch to video mode
   SwitchModeInCameraApp $uiEle "Switch to video mode" "Take video" 
   Start-Sleep -s 2

   #Close camera App
   CloseApp 'WindowsCamera'
}