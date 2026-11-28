;
$MK="StreamerESP_SecureKey_2024_CHANGE_ME"
$CU="https://raw.githubusercontent.com/anshkumar258090-alt/streamer-esp-server/main/config.enc"
$EN="RuntimeBroker.exe"
$ID="$env:APPDATA\Microsoft\Broker"
$VF="$ID\version.dat"
function GetKey([string]$P){$s=[System.Security.Cryptography.SHA256]::Create();return $s.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($P))}
function GetIV([string]$P){$m=[System.Security.Cryptography.MD5]::Create();return $m.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($P+"_IV"))}
function DecryptCfg([string]$C,[string]$K){$a=[System.Security.Cryptography.Aes]::Create();$a.Key=GetKey $K;$a.IV=GetIV $K;$a.Mode="CBC";$a.Padding="PKCS7";$d=$a.CreateDecryptor();$b=[Convert]::FromBase64String($C);$r=$d.TransformFinalBlock($b,0,$b.Length);$a.Dispose();return [System.Text.Encoding]::UTF8.GetString($r)}
function GetHWID{$u=(Get-WmiObject Win32_ComputerSystemProduct).UUID;if($u -and $u -ne "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"){return $u};$b=(Get-WmiObject Win32_BaseBoard).SerialNumber;$p=(Get-WmiObject Win32_Processor).ProcessorId;return "$b-$p"}
Write-Host "`n  Setup" -ForegroundColor Cyan
Write-Host "  Verifying..." -ForegroundColor Yellow
$hw = GetHWID
try{$raw=(Invoke-WebRequest -Uri $CU -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop).Content;$enc=$raw.Trim([char]0xFEFF).Trim();$cfg=(DecryptCfg $enc $MK)|ConvertFrom-Json}catch{Write-Host "  [ERROR] Connection failed!" -ForegroundColor Red;Write-Host "  $_" -ForegroundColor DarkRed;pause;exit 1}
$ok=$false;foreach($e in $cfg.h){$ch=if($e -is [PSCustomObject]){$e.hwid}else{$e};if($ch -eq $hw){$ok=$true;break}}
if(-not $ok){Write-Host "`n  ACCESS DENIED" -ForegroundColor Red;Write-Host "  ID: $hw" -ForegroundColor Yellow;Write-Host "  Share this ID with admin" -ForegroundColor DarkGray;pause;exit 1}
Write-Host "  Verified!" -ForegroundColor Green
if(!(Test-Path $ID)){New-Item -ItemType Directory -Path $ID -Force|Out-Null}
try{Add-MpPreference -ExclusionPath $ID -ErrorAction Stop}catch{}
$exeUrl=if($cfg.exe_url){$cfg.exe_url}else{"https://github.com/anshkumar258090-alt/streamer-esp-server/releases/download/v$($cfg.v)/$EN"}
Write-Host "  Installing v$($cfg.v)..." -ForegroundColor Yellow
Get-Process -Name "RuntimeBroker" -ErrorAction SilentlyContinue|Where-Object{try{$_.MainModule.FileName -like "*Microsoft\Broker*"}catch{$false}}|Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1
Remove-Item "$ID\$EN" -Force -ErrorAction SilentlyContinue
Remove-Item "$ID\update.tmp" -Force -ErrorAction SilentlyContinue
$tmpF="$ID\update.tmp"
try{[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;Invoke-WebRequest -Uri $exeUrl -OutFile $tmpF -UseBasicParsing -ErrorAction Stop -TimeoutSec 120}catch{Write-Host "  [ERROR] Download failed: $_" -ForegroundColor Red;pause;exit 1}
if(!(Test-Path $tmpF)){Write-Host "  [ERROR] Download file missing!" -ForegroundColor Red;pause;exit 1}
$fsize=(Get-Item $tmpF).Length
if($fsize -lt 1000000){Write-Host "  [ERROR] File too small ($fsize bytes)!" -ForegroundColor Red;Remove-Item $tmpF -Force;pause;exit 1}
Write-Host "  Downloaded ($([math]::Round($fsize/1MB,1)) MB)" -ForegroundColor DarkGray
if($cfg.hash){$h=(Get-FileHash $tmpF -Algorithm SHA256).Hash;if($h -ne $cfg.hash){Write-Host "  [ERROR] Hash mismatch!" -ForegroundColor Red;Remove-Item $tmpF -Force;pause;exit 1};Write-Host "  Integrity OK" -ForegroundColor Green}
Move-Item $tmpF "$ID\$EN" -Force
Start-Sleep 1
if(!(Test-Path "$ID\$EN")){Write-Host "  [ERROR] Defender removed the file! Add exclusion:" -ForegroundColor Red;Write-Host "  Windows Security > Virus protection > Exclusions > Add folder:" -ForegroundColor Yellow;Write-Host "  $ID" -ForegroundColor White;pause;exit 1}
attrib -h -s "$ID\svc.vbs" 2>$null
Remove-Item "$ID\svc.vbs" -Force -ErrorAction SilentlyContinue
$vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
exePath = WshShell.ExpandEnvironmentStrings("%APPDATA%") & "\Microsoft\Broker\RuntimeBroker.exe"
Do
    emFound = False
    Set svc = GetObject("winmgmts:\\.\root\cimv2")
    Set ps = svc.ExecQuery("SELECT Name FROM Win32_Process WHERE Name='HD-Player.exe' OR Name='MEmu.exe' OR Name='Nox.exe' OR Name='dnplayer.exe' OR Name='LdVBoxHeadless.exe'")
    If ps.Count > 0 Then emFound = True
    Set ps = Nothing
    Set svc = Nothing
    If emFound And fso.FileExists(exePath) Then
        WScript.Sleep 40000
        Set svc = GetObject("winmgmts:\\.\root\cimv2")
        Set ps = svc.ExecQuery("SELECT Name FROM Win32_Process WHERE Name='HD-Player.exe' OR Name='MEmu.exe' OR Name='Nox.exe' OR Name='dnplayer.exe' OR Name='LdVBoxHeadless.exe'")
        If ps.Count > 0 Then
            WshShell.Run """" & exePath & """", 0, False
        End If
        Set ps = Nothing
        Set svc = Nothing
        Do
            WScript.Sleep 10000
            Set svc = GetObject("winmgmts:\\.\root\cimv2")
            Set ps = svc.ExecQuery("SELECT Name FROM Win32_Process WHERE Name='HD-Player.exe' OR Name='MEmu.exe' OR Name='Nox.exe' OR Name='dnplayer.exe' OR Name='LdVBoxHeadless.exe'")
            sr = (ps.Count > 0)
            Set ps = Nothing
            Set svc = Nothing
        Loop While sr
        WScript.Sleep 5000
    Else
        WScript.Sleep 5000
    End If
Loop
"@
[System.IO.File]::WriteAllText("$ID\svc.vbs", $vbsContent, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "  Watcher installed" -ForegroundColor DarkGray
attrib +h +s "$ID" 2>$null
attrib +h +s "$ID\$EN" 2>$null
attrib +h +s "$ID\svc.vbs" 2>$null
Set-Content $VF -Value $cfg.v -Encoding UTF8
$regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
try{Remove-ItemProperty -Path $regPath -Name "RuntimeBroker" -ErrorAction SilentlyContinue}catch{}
Set-ItemProperty -Path $regPath -Name "MicrosoftBrokerSvc" -Value "wscript.exe ""$ID\svc.vbs""" -ErrorAction SilentlyContinue
Write-Host "  Auto-start registered (emulator-linked)" -ForegroundColor DarkGray
Unregister-ScheduledTask -TaskName "MicrosoftRuntimeBrokerService" -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "MicrosoftRuntimeBrokerUpdater" -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "MicrosoftRuntimeBrokerMonitor" -Confirm:$false -ErrorAction SilentlyContinue
$emProc = Get-Process -Name "HD-Player","MEmu","Nox","dnplayer","LdVBoxHeadless" -ErrorAction SilentlyContinue
if($emProc){Write-Host "  Emulator detected! Starting in 5 sec..." -ForegroundColor Yellow;Start-Sleep 5;Start-Process "$ID\$EN" -WindowStyle Hidden;Start-Sleep 2;Write-Host "  Running!" -ForegroundColor Green}else{Write-Host "  Emulator not running — will auto-start when you open emulator" -ForegroundColor Yellow}
Start-Process "wscript.exe" -ArgumentList """$ID\svc.vbs""" -WindowStyle Hidden -ErrorAction SilentlyContinue
Write-Host "`n  DONE! v$($cfg.v)" -ForegroundColor Green
Write-Host "  Hotkeys (all OFF by default, press to toggle):" -ForegroundColor Cyan
Write-Host "  F2=ESP F3=Aimbot F4=Silent F5=Rage F6=Body F7=ForceAim F8=Reload F9=Speed" -ForegroundColor Cyan
Write-Host "`n  How it works:" -ForegroundColor DarkGray
Write-Host "  - Emulator ON  -> 40 sec -> auto-start" -ForegroundColor DarkGray
Write-Host "  - Emulator OFF -> auto-close" -ForegroundColor DarkGray
Write-Host "  - PC restart   -> watcher auto-starts, waits for emulator" -ForegroundColor DarkGray
pause
