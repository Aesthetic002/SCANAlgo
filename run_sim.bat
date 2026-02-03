@echo off
REM Smart Elevator Controller - Windows Batch Simulation Script
REM Double-click this file to run the simulation

echo ====================================================================
echo   Smart Elevator Controller - Simulation Script (Windows)
echo ====================================================================
echo.

REM Step 1: Compile Verilog files
echo [1/3] Compiling Verilog files...
iverilog -o elevator_sim.vvp smart_elevator.v tb_smart_elevator.v

if %ERRORLEVEL% EQU 0 (
    echo [OK] Compilation successful
) else (
    echo [ERROR] Compilation failed
    echo.
    echo Make sure Icarus Verilog is installed and in your PATH
    echo Download from: http://bleyer.org/icarus/
    pause
    exit /b 1
)

echo.

REM Step 2: Run simulation
echo [2/3] Running simulation...
vvp elevator_sim.vvp

if %ERRORLEVEL% EQU 0 (
    echo [OK] Simulation completed
) else (
    echo [ERROR] Simulation failed
    pause
    exit /b 1
)

echo.

REM Step 3: Inform about waveform
echo [3/3] Waveform generated: elevator_waveform.vcd
echo.
echo To view waveforms, run:
echo   gtkwave elevator_waveform.vcd
echo.
echo Or use online viewer: https://vc.drom.io/
echo.
echo ====================================================================
echo   Simulation Complete!
echo ====================================================================
echo.
pause
