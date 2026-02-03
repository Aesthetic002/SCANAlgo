#!/bin/bash
# ==============================================================================
# Simulation Script for Smart Elevator Controller
# ==============================================================================
# This script compiles and simulates the elevator controller using Icarus Verilog
# and generates waveforms for GTKWave analysis
# ==============================================================================

echo "===================================================================="
echo "  Smart Elevator Controller - Simulation Script"
echo "===================================================================="
echo ""

# Step 1: Compile Verilog files
echo "[1/3] Compiling Verilog files..."
iverilog -o elevator_sim smart_elevator.v tb_smart_elevator.v

if [ $? -eq 0 ]; then
    echo "✓ Compilation successful"
else
    echo "✗ Compilation failed"
    exit 1
fi

echo ""

# Step 2: Run simulation
echo "[2/3] Running simulation..."
vvp elevator_sim

if [ $? -eq 0 ]; then
    echo "✓ Simulation completed"
else
    echo "✗ Simulation failed"
    exit 1
fi

echo ""

# Step 3: Open waveform viewer (optional)
echo "[3/3] Waveform generated: elevator_waveform.vcd"
echo ""
echo "To view waveforms, run:"
echo "  gtkwave elevator_waveform.vcd"
echo ""
echo "===================================================================="
echo "  Simulation Complete!"
echo "===================================================================="
