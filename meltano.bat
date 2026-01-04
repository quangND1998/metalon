@echo off
REM Wrapper script to run meltano with UTF-8 encoding support on Windows
set PYTHONUTF8=1
set PYTHONIOENCODING=utf-8
meltano %*

