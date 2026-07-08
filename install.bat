@echo off
setlocal EnableDelayedExpansion
rem ============================================================================
rem  Eyeless Tempering Made Easy installer (double-click me)
rem  Runs install.ps1 for you -- no PowerShell knowledge required.
rem
rem  You can also pass a game path:  install.bat -GameDir "D:\Games\Pillars of Eternity"
rem  With no arguments it auto-detects a Steam install, then prompts if it cannot find one.
rem  At the prompt, quotes are optional; paths with spaces and parentheses are OK.
rem ============================================================================

echo.
echo Installing Eyeless Tempering Made Easy...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
set "ETME_EXIT=%errorlevel%"

echo.
if "%ETME_EXIT%"=="0" (
    echo Done. You can close this window and launch the game.
) else (
    echo Something went wrong ^(exit code %ETME_EXIT%^). See the messages above.
    echo Make sure the game is closed and the folder is correct, then try again.
)
echo.
pause
endlocal
