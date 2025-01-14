param (
   [string] $token = $null,
   [string] $SPId = $null,
   [string] $targetMepCameraVer = $null,
   [string] $targetMepAudioVer = $null,
   [string] $targetPerceptionCoreVer = $null
)
.".\CheckInTest\Helper-library.ps1"
InitializeTest 'Checkin-Test' $targetMepCameraVer $targetMepAudioVer $targetPerceptionCoreVer

foreach($devPowStat in "Pluggedin", "Unplugged")
{
     VoiceFocus-Playlist "$devPowStat" $token $SPId >> $pathLogsFolder\"$devPowStat-VoiceFocus.txt"
   
    AutoFraming-Playlist $devPowStat $token $SPId >> $pathLogsFolder\"$devPowStat-AutomaticFraming.txt"
         
     BackgroundBlur-Playlist "$devPowStat" $token $SPId >> $pathLogsFolder\"$devPowStat-BackgroundBlurStandard.txt"
   
     Backgroundblur-Portrait-Playlist "$devPowStat" $token $SPId >> $pathLogsFolder\"$devPowStat-BackgroundBlurPortrait.txt"
   
     EyeContact-Playlist "$devPowStat" $token $SPId >> $pathLogsFolder\"$devPowStat-EyeContactStandard.txt"
   
     Camera-App-Playlist "$devPowStat" $token $SPId >> $pathLogsFolder\"$devPowStat-Camerae2eTest.txt"
   
     Voice-Recorder-Playlist "$devPowStat" $token $SPId >> $pathLogsFolder\"$devPowStat-VoiceRecordere2eTest.txt"

     Portrait-Light-Playlist "$devPowStat" $token $SPId >> $pathLogsFolder\"$devPowStat-PortraitLight.txt"
   
     EyeContact-Enhanced-Playlist "$devPowStat" $token $SPId >> $pathLogsFolder\"$devPowStat-EyeContactEnhanced.txt"

     Creativefilters-I-Playlist "$devPowStat" $token $SPId >> $pathLogsFolder\"$devPowStat-Creativefilters-I.txt"

     Creativefilters-A-Playlist "$devPowStat" $token $SPId >> $pathLogsFolder\"$devPowStat-Creativefilters-A.txt"

     Creativefilters-W-Playlist "$devPowStat" $token $SPId >> $pathLogsFolder\"$devPowStat-Creativefilters-W.txt"

}
#Turn on the smart plug 
if($token.Length -ne 0 -and $SPId.Length -ne 0)
{
   SetSmartPlugState $token $SPId 1
}

[console]::beep(500,300)

ConvertTxtFileToExcel "$pathLogsFolder\Report.txt"