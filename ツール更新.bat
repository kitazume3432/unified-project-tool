@echo off
setlocal
pushd "%~dp0"
if errorlevel 1 (
  echo Failed to move to folder: %~dp0
  pause
  exit /b 1
)

set "LOGFILE=%cd%\update_log.txt"
echo ============================================== > "%LOGFILE%"
echo Update started: %date% %time% >> "%LOGFILE%"
echo Folder: %cd% >> "%LOGFILE%"
echo ============================================== >> "%LOGFILE%"

echo ===============================================
echo   Update tool - pushing to GitHub
echo   Current folder: %cd%
echo   (A full log is also being saved to: update_log.txt)
echo ===============================================
echo.

set "DOWNLOADS=%USERPROFILE%\Downloads"
set "NEWEST="

for /f "delims=" %%F in ('dir /b /o-d /a-d "%DOWNLOADS%\*.html" 2^>nul') do (
  if not defined NEWEST set "NEWEST=%%F"
)

if not defined NEWEST goto :nofile
goto :foundfile

:nofile
echo No .html file was found in: %DOWNLOADS%
echo Skipping the overwrite step. Continuing with the files already in this folder.
echo No html file found in Downloads. Skipped overwrite. >> "%LOGFILE%"
echo.
goto :commitpush

:foundfile
echo Newest .html file found in Downloads folder:
echo   %NEWEST%
for %%A in ("%DOWNLOADS%\%NEWEST%") do echo   Last modified: %%~tA
echo.
echo This file can be used to overwrite index.html in this folder.
set "CONFIRM="
set /p CONFIRM="Overwrite index.html with this file? (Y = overwrite / N = skip and just commit current files): "
if /i "%CONFIRM%"=="Y" goto :dooverwrite
goto :skipoverwrite

:dooverwrite
copy /Y "%DOWNLOADS%\%NEWEST%" "index.html" >nul
if errorlevel 1 goto :copyfailed
echo.
echo index.html has been updated.
echo Overwrote index.html with: %NEWEST% >> "%LOGFILE%"
echo.
goto :commitpush

:copyfailed
echo.
echo [ERROR] Failed to copy the file into index.html.
echo [ERROR] Failed to copy %NEWEST% into index.html >> "%LOGFILE%"
echo.
pause
popd
exit /b 1

:skipoverwrite
echo.
echo Skipped overwriting index.html. Continuing with files already in this folder.
echo User chose not to overwrite index.html. >> "%LOGFILE%"
echo.
goto :commitpush

:commitpush
git add -A

set "MSG="
set /p MSG="Commit message (leave blank and press Enter for default): "
if "%MSG%"=="" set "MSG=update"

echo. >> "%LOGFILE%"
echo --- git commit --- >> "%LOGFILE%"
set "COMMITTEMP=%temp%\commit_output_%random%.txt"
git commit -m "%MSG%" > "%COMMITTEMP%" 2>&1
set "COMMITRESULT=%errorlevel%"
type "%COMMITTEMP%"
type "%COMMITTEMP%" >> "%LOGFILE%"
del "%COMMITTEMP%" >nul 2>&1

if "%COMMITRESULT%"=="0" goto :dopush
goto :commitfailed

:commitfailed
echo.
echo No changes found, or commit failed.
echo (This can happen if there was nothing new to save.)
echo COMMIT RESULT: no changes or failed. >> "%LOGFILE%"
echo.
pause
popd
exit /b 1

:dopush
echo.
echo Uploading to GitHub...
echo. >> "%LOGFILE%"
echo --- git push --- >> "%LOGFILE%"
set "PUSHTEMP=%temp%\push_output_%random%.txt"
git push > "%PUSHTEMP%" 2>&1
set "PUSHRESULT=%errorlevel%"
type "%PUSHTEMP%"
type "%PUSHTEMP%" >> "%LOGFILE%"
del "%PUSHTEMP%" >nul 2>&1

if "%PUSHRESULT%"=="0" goto :pushsuccess
goto :pushfailed

:pushfailed
echo.
echo [ERROR] Push failed. Please check your network connection and login status.
echo PUSH RESULT: FAILED >> "%LOGFILE%"
echo.
pause
popd
exit /b 1

:pushsuccess
echo PUSH RESULT: SUCCESS >> "%LOGFILE%"
echo Update finished: %date% %time% >> "%LOGFILE%"
echo ============================================== >> "%LOGFILE%"
echo.
echo Update completed successfully.
echo In a few minutes, your changes will be live on GitHub Pages.
echo.
pause
popd
