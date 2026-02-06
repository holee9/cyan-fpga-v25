@echo off
###############################################################################
# File: run_questa.bat
# Date: 2026-02-05
# Designer: drake.lee
# Description: Questa Simulation Launcher for Windows
#              Launches Questa 2025.3 and runs compilation + tests
#
# Usage:
#   Double-click run_questa.bat
#   Or run from command prompt: run_questa.bat
#
# Tool Paths:
#   Questa 2025.3: D:\questa_base64_2025.3
#   Compiled Libs:  D:\compile_simlib\vivado_2025_questa_2025
#
# Revision History:
#    2026.02.05 - Initial
###############################################################################

setlocal

REM Tool paths
set QUESTA_DIR=D:\questa_base64_2025.3
set QUESTA_BIN=%QUESTA_DIR%\win64

REM Add Questa to PATH
set PATH=%QUESTA_BIN%;%PATH%

REM Change to simulation directory
cd /d "%~dp0"

echo ==========================================
echo CYAN-FPGA Questa Simulation Launcher
echo ==========================================
echo Questa 2025.3: %QUESTA_DIR%
echo Working Dir: %CD%
echo ==========================================

REM Check if Questa is available
where vsim >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Questa vsim not found in PATH
    echo Please check Questa installation: %QUESTA_DIR%
    pause
    exit /b 1
)

REM Create results directory
if not exist sim_results mkdir sim_results

REM Step 1: Compile sources
echo.
echo ==========================================
echo Step 1: Compiling Source Files
echo ==========================================
call vsim -c -do "do compile_sources.do; quit"

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Source compilation failed
    pause
    exit /b 1
)

REM Step 2: Run tests
echo.
echo ==========================================
echo Step 2: Running Tests
echo ==========================================
call vsim -c -do "do run_batch_tests.do"

echo.
echo ==========================================
echo Simulation Complete!
echo ==========================================
echo Check sim_results/test_summary.log for details
echo ==========================================
pause
