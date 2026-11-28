;
Write-Host "`n  Uninstall" -ForegroundColor Cyan
Write-Host "  Stopping processes..." -ForegroundColor Yellow
Get-Process -Name "RuntimeBroker" -ErrorAction SilentlyContinue | ForEach-Object { try { if ($_.MainModule.FileName -like "*Microsoft\Broker*") { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue; Write-Host "  Stopped RuntimeBroker PID $($_.Id)" -ForegroundColor DarkGray } } catch {} }
Get-Process -Name "wscript" -ErrorAction SilentlyContinue | ForEach-Object { try { $cl=(Get-WmiObject Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine; if($cl -like "*svc.vbs*"){ Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue; Write-Host "  Stopped watcher PID $($_.Id)" -ForegroundColor DarkGray } } catch {} }
Start-Sleep 2
Write-Host "  Removing registry entries..." -ForegroundColor Yellow
$rp = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
Remove-ItemProperty -Path $rp -Name "MicrosoftBrokerSvc" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $rp -Name "RuntimeBroker" -ErrorAction SilentlyContinue
Write-Host "  Removing scheduled tasks..." -ForegroundColor Yellow
Unregister-ScheduledTask -TaskName "MicrosoftRuntimeBrokerService" -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "MicrosoftRuntimeBrokerUpdater" -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "MicrosoftRuntimeBrokerMonitor" -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "  Deleting files..." -ForegroundColor Yellow
$ID = "$env:APPDATA\Microsoft\Broker"
if (Test-Path $ID) { attrib -h -s "$ID" 2>$null; Get-ChildItem $ID -Force | ForEach-Object { attrib -h -s $_.FullName 2>$null }; Remove-Item $ID -Recurse -Force -ErrorAction SilentlyContinue; if (!(Test-Path $ID)) { Write-Host "  Files deleted!" -ForegroundColor Green } else { Write-Host "  [WARN] Some files locked, restart PC and delete manually: $ID" -ForegroundColor Yellow } } else { Write-Host "  No files found" -ForegroundColor DarkGray }
Write-Host "`n  UNINSTALLED!" -ForegroundColor Green
Write-Host "  Registry cleaned, files removed, processes stopped." -ForegroundColor DarkGray
Write-Host "  PC restart recommended.`n" -ForegroundColor DarkGray
pause