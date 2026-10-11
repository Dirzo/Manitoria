@echo off
python -m pip install --target "%~dp0tools/narration-deps" -r "%~dp0tools/requirements-narration.txt"
pause
