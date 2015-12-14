@echo off
REM Remove and block the "Get Windows 10" background downloader and notification icon.
REM bw.aljex@gmail.com
REM Based on http://superuser.com/a/922921
REM This may need to be re-run any time one of the blocked KBs is updated by MicroSoft,
REM and any time more KBs are added to the list.
REM Add more KBs to KBLIST and re-run any time.
REM 20151008 bkw - Added more KB's
REM                Added reg entries to block gwx and disable os upgrades
REM                CD to zip unpack dir and test for .vbs
REM                Automatically request admin rights on demand
REM 20151213 bkw - Delete GWX home & download directory

REM As of 2015-10-08:
REM 2952664 Compatibility update for upgrading Windows 7
REM 2990214 Update that enables you to upgrade from Windows 7 to a later version of Windows
REM 3022345 Update to enable the Diagnostics Tracking Service in Windows
REM 3080149 Replaces 3200345
REM 3035583 Update enables additional capabilities for Windows Update notifications in Windows 8.1 and Windows 7 SP1
REM 3021917 Update to Windows 7 SP1 for performance improvements

REM TODO: GWXUX

REM List of updates to block
REM These are KB ID numbers, like KB3035583, without the "KB"
set KBLIST=2952664 2990214 3035583 3021917 3022345 3080149

REM cd to wherever ourself is (SFX temp dir) and verify .vbs file is present
set HKB=HideUpdatesByKB.vbs
cd %~p0
if exist %HKB% goto :UAC
echo Could not find %HKB%
echo Perhaps "cd %%~p0" failed?
echo %%0=%0
echo %%~p0=%~p0
echo CD=%CD%
pause
exit

REM If we don't have admin rights already, get them (re-exec ourselves)
:UAC
net file 1>nul 2>nul && goto :RUN
powershell -ex unrestricted -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/c %~fnx0 %*'" && exit
echo This script requires Administrator rights to work.
pause
exit

:RUN
echo Killing GWX.exe if present
taskkill /IM GWX.exe /T /F

echo Disabling GWX.exe from running in future even if it reappears 
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\GWX /v DisableGWX /d 1 /f

echo Disabling "OS upgrades" (not to be confused with Windows Updates)
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v DisableOSUpgrade /d 1 /f
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade /v ReservationsAllowed /d 0 /f
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade /v AllowOSUpgrade /d 0 /f

echo Uninstalling: %KBLIST%
for %%U in (%KBLIST%) do (
	echo KB%%U
	start "Uninstalling KB%%U" /b /wait wusa.exe /kb:%%U /uninstall /quiet /norestart
)
echo.

echo Hiding: %KBLIST%
start "Hiding KBs %KBLIST%" /b /wait cscript.exe %HKB% %KBLIST%
echo.

set GWXDIR=%SYSTEMROOT%\System32\GWX
echo Deleting GWX home and download directory \"%GWXDIR%\"
takeown /a /r /d Y /f %GWXDIR%
icacls %GWXDIR% /grant administrators:F
rd /s /q %GWXDIR%

echo COMPLETED. Please reboot now.
pause
