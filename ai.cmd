@echo off
REM Lanceur simple : ai "ma tache"  |  ai  (reprendre)  |  ai -Mode opencode "ma tache"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ai-dev.ps1" %*
