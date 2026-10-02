@echo off
cd /d "%~dp0"
echo Rebuilding Manitoria.exe and Manitoria.pck, one moment...
copy /b /y Manitoria.exe.part000 + Manitoria.exe.part001 + Manitoria.exe.part002 + Manitoria.exe.part003 + Manitoria.exe.part004 + Manitoria.exe.part005 Manitoria.exe >nul
copy /b /y Manitoria.pck.part000 + Manitoria.pck.part001 + Manitoria.pck.part002 + Manitoria.pck.part003 + Manitoria.pck.part004 + Manitoria.pck.part005 + Manitoria.pck.part006 + Manitoria.pck.part007 + Manitoria.pck.part008 + Manitoria.pck.part009 + Manitoria.pck.part010 + Manitoria.pck.part011 + Manitoria.pck.part012 + Manitoria.pck.part013 + Manitoria.pck.part014 + Manitoria.pck.part015 + Manitoria.pck.part016 + Manitoria.pck.part017 + Manitoria.pck.part018 + Manitoria.pck.part019 Manitoria.pck >nul
for %%F in (Manitoria.pck) do if not "%%~zF"=="389603024" (echo Something went wrong - Manitoria.pck is the wrong size. & pause & exit /b 1)
for %%F in (Manitoria.exe) do if not "%%~zF"=="109268480" (echo Something went wrong - Manitoria.exe is the wrong size. & pause & exit /b 1)
del Manitoria.exe.part* Manitoria.pck.part*
echo Done! Double-click Manitoria.exe to play.
pause
