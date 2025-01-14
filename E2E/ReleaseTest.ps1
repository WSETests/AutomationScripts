param (
   [string] $token = $null,
   [string] $SPId = $null,
   [string] $targetMepCameraVer = $null,
   [string] $targetMepAudioVer = $null,
   [string] $targetPerceptionCoreVer = $null
)
.".\CheckInTest\Helper-library.ps1"
InitializeTest 'ReleaseTestSet' $targetMepCameraVer $targetMepAudioVer $targetPerceptionCoreVer
if($wsev2PolicyState -eq $false)
{
    $toggleAiEffect = 'AF','EC','BBS', 'BBP','AF+EC', 'AF+BBS', 'AF+BBP','BBS+EC','BBP+EC','AF+BBS+EC','AF+BBP+EC'
   
} 
else 
{
    $toggleAiEffect =  'AF', 'PL', 'BBS', 'BBP', 'EC', 'ECE', 'AF+PL', 'AF+BBS', 'AF+BBP', 'AF+EC', 'AF+ECE', `
                       'PL+BBS', 'PL+BBP', 'PL+EC', 'PL+ECE', 'BBS+EC', 'BBS+ECE', 'BBP+EC', 'BBP+ECE', 'AF+PL+BBS', `
                       'AF+PL+BBP','AF+PL+EC', 'AF+PL+ECE', 'AF+BBS+EC', 'AF+BBS+ECE', 'AF+BBP+EC', 'AF+BBP+ECE', `
                       'Pl+BBS+EC', 'Pl+BBP+EC', 'Pl+BBS+ECE', 'Pl+BBP+ECE', 'AF+Pl+BBS+EC', 'AF+Pl+BBS+ECE', `
                       'AF+Pl+BBP+EC', 'AF+Pl+BBP+ECE','CF-I', 'AF+CF-I', 'AF+CF-I+PL', 'AF+CF-I+EC', `
                       'AF+CF-I+ECE', 'AF+CF-I+BBS', 'AF+CF-I+BBP', 'AF+CF-I+PL+EC', 'AF+CF-I+PL+ECE', `
                       'AF+CF-I+PL+BBS', 'AF+CF-I+PL+BBP', 'AF+CF-I+EC+BBS', 'AF+CF-I+EC+BBP', 'AF+CF-I+ECE+BBS', `
                       'AF+CF-I+ECE+BBP', 'AF+CF-I+PL+EC+BBS', 'AF+CF-I+PL+EC+BBP', 'AF+CF-I+PL+ECE+BBS', `
                       'AF+CF-I+PL+ECE+BBP', 'PL+CF-I', 'PL+CF-I+EC', 'PL+CF-I+ECE', 'PL+CF-I+BBS', `
                       'PL+CF-I+BBP', 'PL+CF-I+EC+BBS', 'PL+CF-I+EC+BBP', 'PL+CF-I+ECE+BBS', 'PL+CF-I+ECE+BBP', `
                       'EC+CF-I', 'ECE+CF-I', 'EC+CF-I+BBS', 'EC+CF-I+BBP', 'ECE+CF-I+BBS', 'ECE+CF-I+BBP', `
                       'BBS+CF-I', 'BBP+CF-I','CF-A', 'AF+CF-A', 'AF+CF-A+PL', 'AF+CF-A+EC', 'AF+CF-A+ECE', `
                       'AF+CF-A+BBS', 'AF+CF-A+BBP', 'AF+CF-A+PL+EC', 'AF+CF-A+PL+ECE', 'AF+CF-A+PL+BBS', `
                       'AF+CF-A+PL+BBP', 'AF+CF-A+EC+BBS', 'AF+CF-A+EC+BBP', 'AF+CF-A+ECE+BBS', 'AF+CF-A+ECE+BBP', `
                       'AF+CF-A+PL+EC+BBS', 'AF+CF-A+PL+EC+BBP', 'AF+CF-A+PL+ECE+BBS', 'AF+CF-A+PL+ECE+BBP', 'PL+CF-A', `
                       'PL+CF-A+EC', 'PL+CF-A+ECE', 'PL+CF-A+BBS', 'PL+CF-A+BBP', 'PL+CF-A+EC+BBS', 'PL+CF-A+EC+BBP', `
                       'PL+CF-A+ECE+BBS', 'PL+CF-A+ECE+BBP', 'EC+CF-A', 'ECE+CF-A', 'EC+CF-A+BBS', 'EC+CF-A+BBP', `
                       'ECE+CF-A+BBS', 'ECE+CF-A+BBP', 'BBS+CF-A', 'BBP+CF-A','CF-W', 'AF+CF-W', 'AF+CF-W+PL', `
                       'AF+CF-W+EC', 'AF+CF-W+ECE', 'AF+CF-W+BBS', 'AF+CF-W+BBP', 'AF+CF-W+PL+EC', 'AF+CF-W+PL+ECE', `
                       'AF+CF-W+PL+BBS', 'AF+CF-W+PL+BBP', 'AF+CF-W+EC+BBS', 'AF+CF-W+EC+BBP', 'AF+CF-W+ECE+BBS', `
                       'AF+CF-W+ECE+BBP', 'AF+CF-W+PL+EC+BBS', 'AF+CF-W+PL+EC+BBP', 'AF+CF-W+PL+ECE+BBS', `
                       'AF+CF-W+PL+ECE+BBP', 'PL+CF-W', 'PL+CF-W+EC', 'PL+CF-W+ECE', 'PL+CF-W+BBS', 'PL+CF-W+BBP', `
                       'PL+CF-W+EC+BBS', 'PL+CF-W+EC+BBP', 'PL+CF-W+ECE+BBS', 'PL+CF-W+ECE+BBP', 'EC+CF-W', `
                       'ECE+CF-W', 'EC+CF-W+BBS', 'EC+CF-W+BBP', 'ECE+CF-W+BBS', 'ECE+CF-W+BBP', 'BBS+CF-W', 'BBP+CF-W'
}

foreach($camsnario in "Previewing" , "Recording")
{
   foreach ($vdoRes in "1080p" , "720p")
   {  
      foreach ($ptoRes in  "2.1MP")
      {  
         foreach($devPowStat in "Pluggedin" , "Unplugged")
         {  
            foreach($togAiEfft in $toggleAiEffect)
            {
               CameraAppTest -logFile "CameraAppTest.txt" -token $token -SPId $SPId -camsnario $camsnario -vdoRes $vdoRes -ptoRes $ptoRes -devPowStat $devPowStat -toggleEachAiEffect $togAiEfft >> "$pathLogsFolder\CameraAppTest.txt"
            } 
         } 
      }
    }
}
[console]::beep(500,300)
if (!(test-path "$pathLogsFolder\ReRunFailedTests.ps1")) 
{
   Write-host "All Tests Succeeded" -BackgroundColor Green
}
else
{  
  
   @('.".\CheckInTest\Helper-library.ps1"') + ("InitializeTest 'ReRunfailedTest'") + (Get-Content -Path "$pathLogsFolder\ReRunFailedTests.ps1") | Set-Content -Path "$pathLogsFolder\ReRunFailedTests.ps1" 
   (Get-Content -Path "$pathLogsFolder\ReRunFailedTests.ps1") -replace "111222", $token | Set-Content -Path "$pathLogsFolder\ReRunFailedTests.ps1" 
   (Get-Content -Path "$pathLogsFolder\ReRunFailedTests.ps1") -replace "333444", $SPId | Set-Content -Path "$pathLogsFolder\ReRunFailedTests.ps1"
   copy-Item $pathLogsFolder\ReRunFailedTests.ps1 -Destination ReRunFailedTests.ps1
   
}
if($token.Length -ne 0 -and $SPId.Length -ne 0)
{
   SetSmartPlugState $token $SPId 1
}
[console]::beep(500,300)
 
ConvertTxtFileToExcel "$pathLogsFolder\Report.txt"

       