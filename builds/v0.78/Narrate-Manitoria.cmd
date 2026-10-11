@echo off
python "%~dp0tools/narrated_playtest.py" --game "%~dp0Manitoria.exe" %*
if errorlevel 1 pause
