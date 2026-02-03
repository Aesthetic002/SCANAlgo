# Smart Elevator Controller Simulation Script (Windows)
# ==============================================================================
# This script compiles and simulates the elevator controller using Icarus Verilog
# and generates waveforms for GTKWave analysis on Windows
# ==============================================================================

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  Smart Elevator Controller - Simulation Script (Windows)" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Compile Verilog files
Write-Host "[1/3] Compiling Verilog files..." -ForegroundColor Yellow
iverilog -o elevator_sim.vvp smart_elevator.v tb_smart_elevator.v

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Compilation successful" -ForegroundColor Green
} else {
    Write-Host "✗ Compilation failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Note: Make sure Icarus Verilog is installed and in your PATH" -ForegroundColor Yellow
    Write-Host "Download from: http://bleyer.org/icarus/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 2: Run simulation
Write-Host "[2/3] Running simulation..." -ForegroundColor Yellow
vvp elevator_sim.vvp

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Simulation completed" -ForegroundColor Green
} else {
    Write-Host "✗ Simulation failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Inform about waveform
Write-Host "[3/3] Waveform generated: elevator_waveform.vcd" -ForegroundColor Yellow
Write-Host ""
Write-Host "To view waveforms, run:" -ForegroundColor Cyan
Write-Host "  gtkwave elevator_waveform.vcd" -ForegroundColor White
Write-Host ""
Write-Host "Or use online viewer: https://vc.drom.io/" -ForegroundColor Cyan
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  Simulation Complete!" -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Cyan
