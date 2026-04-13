@echo off
setlocal EnableExtensions DisableDelayedExpansion
:: Start_WMT_GUI.bat
set "GUI_LAUNCHER_VERSION=1.3"
set "BAT_URL=https://raw.githubusercontent.com/ios12checker/Windows-Maintenance-Tool/refs/heads/main/Start_WMT_GUI.bat"
set "SCRIPT_URL=https://raw.githubusercontent.com/ios12checker/Windows-Maintenance-Tool/refs/heads/main/WMT-GUI.ps1"
set "SCRIPT=%~dp0WMT-GUI.ps1"

:: 1. Check for updates to this Launcher (.bat)
echo Checking for launcher updates...
set "TEMP_BAT=%TEMP%\Start_WMT_GUI_update.bat"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$remote = try { (Invoke-WebRequest -Uri '%BAT_URL%' -UseBasicParsing).Content } catch { $null }; " ^
  "if ($remote -match 'set \"GUI_LAUNCHER_VERSION=([\d\.]+)\"') { " ^
  "  if ([version]$matches[1] -gt [version]'%GUI_LAUNCHER_VERSION%') { " ^
  "    [IO.File]::WriteAllText('%TEMP_BAT%', $remote); exit 43 " ^
  "  } " ^
  "}"

if "%ERRORLEVEL%"=="43" (
  echo New launcher version found! Updating...
  timeout /t 1 /nobreak >nul
  copy /y "%TEMP_BAT%" "%~f0" >nul
  del "%TEMP_BAT%" >nul
  start "" "%~f0"
  exit /b
)

:: 2. Check for updates to the GUI Script (.ps1)
echo Checking for WMT-GUI.ps1 updates...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri '%SCRIPT_URL%' -OutFile '%SCRIPT%' -UseBasicParsing; exit 0 } catch { exit 1 }"

if not "%ERRORLEVEL%"=="0" (
  echo [WARNING] Failed to download the latest WMT-GUI.ps1. Using local copy...
)

if not exist "%SCRIPT%" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Add-Type -AssemblyName PresentationFramework; $msg='WMT-GUI.ps1 was not found and the download failed.' + [Environment]::NewLine + 'Please check your internet connection.'; [System.Windows.MessageBox]::Show($msg,'WMT Launcher Error',[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null"
  exit /b 1
)

:: 3. Guard against accidentally downloaded HTML page
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%SCRIPT%'; $head=((Get-Content -Path $p -TotalCount 120 -ErrorAction SilentlyContinue) -join \"`n\"); if($head -match '(?is)<!doctype\s+html|<html\b|<head\b|<body\b|<meta\b[^>]*charset'){ exit 42 } else { exit 0 }"

if "%ERRORLEVEL%"=="42" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Add-Type -AssemblyName PresentationFramework; $msg='Invalid WMT-GUI.ps1 detected.' + [Environment]::NewLine + 'It looks like an HTML page was downloaded instead of the raw PowerShell script.' + [Environment]::NewLine + [Environment]::NewLine + 'Please download from Releases or use the raw file link.'; [System.Windows.MessageBox]::Show($msg,'WMT Launcher Error',[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null"
  start "" "https://github.com/ios12checker/Windows-Maintenance-Tool/releases"
  exit /b 1
)

:: 4. Force Admin Escalation from the batch file
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
  "try { Start-Process -Verb RunAs -WindowStyle Hidden -FilePath 'powershell.exe' -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%SCRIPT%\"' -WorkingDirectory '%~dp0'; exit 0 } catch { exit 1 }"

:: 5. Catch if the user declines the UAC prompt or the launch fails
set "LAUNCH_EXIT=%ERRORLEVEL%"
if not "%LAUNCH_EXIT%"=="0" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Add-Type -AssemblyName PresentationFramework; $msg='Failed to start WMT-GUI.ps1.' + [Environment]::NewLine + 'Admin rights were declined or the script was blocked.' + [Environment]::NewLine + 'Launcher exit code: %LAUNCH_EXIT%' + [Environment]::NewLine + [Environment]::NewLine + 'Path:' + [Environment]::NewLine + '%SCRIPT%'; [System.Windows.MessageBox]::Show($msg,'WMT Launcher Error',[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null"
  exit /b %LAUNCH_EXIT%
)