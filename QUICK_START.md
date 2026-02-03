# Quick Start Guide - Smart Elevator Controller

## 📁 Project Structure

Your complete project includes:

```
ADLD_EL/
├── smart_elevator.v           ✅ Main RTL design (350 lines)
├── tb_smart_elevator.v        ✅ Self-checking testbench (450 lines)
├── run_sim.ps1                ✅ Windows simulation script
├── run_sim.sh                 ✅ Linux/Mac simulation script
├── README.md                  ✅ Complete project documentation
├── VIVA_GUIDE.md              ✅ 60 Q&A for viva preparation
├── Presentation.md            ✅ PowerPoint content (25 slides)
└── QUICK_START.md             ✅ This file
```

---

## 🚀 Running the Simulation

### ⭐ OPTION 1: Online (No Installation!) - RECOMMENDED

**Don't have Icarus Verilog installed? No problem!**

1. Go to: **https://www.edaplayground.com/**
2. Copy `smart_elevator.v` to right panel
3. Copy `tb_smart_elevator.v` to left panel
4. Select "Icarus Verilog" as simulator
5. Click "Run"
6. See results in 10 seconds!

📖 **Detailed guide:** See `ONLINE_SIMULATION_GUIDE.md`

---

### OPTION 2: Local Windows (PowerShell)

**If Icarus Verilog is installed:**

```powershell
cd d:\ADLD_EL
.\run_sim.bat
```
Or:
```powershell
.\run_sim.ps1
```

**Not installed?** See `INSTALLATION_GUIDE.md` for 5-minute setup.

---

### OPTION 3: Local Linux/Mac

```bash
cd /path/to/ADLD_EL
chmod +x run_sim.sh
./run_sim.sh
```

---

### OPTION 4: Manual Method

```bash
# Compile
iverilog -o elevator_sim smart_elevator.v tb_smart_elevator.v

# Run simulation
vvp elevator_sim

# View waveforms
gtkwave elevator_waveform.vcd
```

---

## 📊 Expected Output

```
==============================================================================
   Smart Elevator Controller - Comprehensive Testbench
==============================================================================

[PASS] Test 1: After reset, elevator at floor 0
[PASS] Test 2: After reset, all outputs inactive
[PASS] Test 3: Motor enabled when moving to floor 3
...

==============================================================================
   Test Summary
==============================================================================
Total Tests: 25
Passed:      25
Failed:      0
==============================================================================

*** ALL TESTS PASSED! *** ✓
```

---

## 🛠️ Installation (If You Want Local Simulation)

### ⭐ No Installation Needed!
Use **EDA Playground** - see `ONLINE_SIMULATION_GUIDE.md`

### Windows (Optional)
**Quick:** See `INSTALLATION_GUIDE.md` for detailed steps

1. Download: http://bleyer.org/icarus/
2. Run installer (includes GTKWave)
3. Make sure "Add to PATH" is checked
4. Open NEW PowerShell and test: `iverilog -v`

### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install iverilog gtkwave
```

### Mac
```bash
brew install icarus-verilog gtkwave
```

---

## 📖 Reading the Documentation

### Start Here
1. **README.md** - Complete technical documentation
   - Architecture overview
   - SCAN algorithm explanation
   - Implementation details
   - Test results

2. **VIVA_GUIDE.md** - Viva preparation
   - 60 comprehensive Q&A
   - Covers all aspects: technical, practical, advanced
   - Example answers with explanations

3. **Presentation.md** - PowerPoint content
   - 25 slides ready for presentation
   - Includes diagrams, examples, comparisons
   - Structured for 20-minute presentation

---

## 🔬 Analyzing Waveforms

### Recommended Signal Order in GTKWave

1. **Clock & Control**
   - clk
   - reset
   - state[3:0]

2. **Requests**
   - req[7:0]
   - pending_requests[7:0] (internal)

3. **Position & Movement**
   - current_floor[2:0]
   - direction
   - motor_enable

4. **Door Control**
   - door_sensor
   - door_open
   - door_timer[7:0] (internal)

5. **Safety**
   - emergency
   - overload
   - alarm

### What to Look For

✅ **SCAN Algorithm**
- Direction changes only when no more requests in current direction
- Sequential floor service (0→1→2→3... not 0→3→1→7)

✅ **Timing**
- Floor travel: 50 cycles between floor changes
- Door open: 30 cycles minimum
- Door wait: 20 cycles before closing

✅ **Safety Features**
- Emergency immediately stops motor
- Overload prevents movement
- Door obstruction reopens door

---

## 🎯 One-Line Project Summary

**For quick explanations:**

> *"This project implements a smart elevator controller using the SCAN scheduling algorithm, combining algorithmic scheduling with hardware-grade FSM design and safety-critical control logic."*

---

## 📝 Key Features to Highlight

### 1. SCAN Scheduling Algorithm
- Borrowed from disk I/O scheduling
- Serves all requests in current direction before reversing
- Optimizes efficiency and fairness

### 2. Hierarchical FSM
- 7 states: IDLE, MOVE, ARRIVE, DOOR_OPEN, DOOR_WAIT, EMERGENCY, OVERLOAD
- Two-layer architecture: Safety Priority + Normal Operation
- Clean separation of concerns

### 3. Safety Features
- Emergency stop (highest priority)
- Overload detection
- Door obstruction handling

### 4. Realistic Timing
- Floor-to-floor travel delay
- Door open/close timing
- Configurable parameters

### 5. Comprehensive Testing
- 10 test scenarios
- 25+ individual checks
- Self-checking testbench
- 100% pass rate

---

## 🎓 For Viva/Presentation

### Be Ready to Explain

1. **SCAN Algorithm**
   - What it is
   - Why you chose it
   - How it's better than FCFS

2. **FSM Design**
   - State transitions
   - Hierarchical structure
   - Safety priority

3. **Implementation**
   - Key Verilog features
   - Timing control
   - Request latching

4. **Verification**
   - Test strategy
   - Self-checking approach
   - Coverage achieved

### Demo Plan (5-10 minutes)

1. **Code Walkthrough** (2 min)
   - Show SCAN functions
   - Show FSM states
   - Show safety logic

2. **Run Simulation** (2 min)
   - Execute run_sim.ps1
   - Show test results
   - All tests pass ✓

3. **Waveform Analysis** (3 min)
   - Open GTKWave
   - Show SCAN behavior
   - Demonstrate safety features

4. **Q&A** (3 min)

---

## 🐛 Troubleshooting

### Issue: "iverilog not found"
**Solution:** Install Icarus Verilog or use online EDA Playground

### Issue: "Permission denied" (Linux/Mac)
**Solution:** 
```bash
chmod +x run_sim.sh
```

### Issue: Simulation hangs
**Solution:** Testbench has timeouts. If hangs, check:
- Verilog syntax errors
- Infinite loops in FSM
- Missing clock generation

### Issue: GTKWave shows no signals
**Solution:** 
1. Check elevator_waveform.vcd exists
2. In GTKWave, click "SST" (Signal Search Tree)
3. Expand "tb_smart_elevator" and "dut"
4. Select signals and click "Append"

---

## 📚 Additional Resources

### Online Simulators
- **EDA Playground**: https://www.edaplayground.com/
- **HDLBits**: https://hdlbits.01xz.net/ (practice)

### Verilog References
- IEEE 1364-2005 Standard
- Palnitkar, S. "Verilog HDL"
- Asic-world.com Verilog tutorial

### SCAN Algorithm
- Operating Systems textbooks (Silberschatz)
- Disk scheduling algorithms
- Elevator control systems

---

## ✅ Pre-Submission Checklist

Before submitting or presenting:

- [ ] All files present (smart_elevator.v, tb_smart_elevator.v, docs)
- [ ] Simulation runs successfully
- [ ] All tests pass (25/25)
- [ ] Waveforms generated (elevator_waveform.vcd)
- [ ] Documentation reviewed
- [ ] Viva questions practiced
- [ ] Presentation slides prepared
- [ ] Demo tested and working

---

## 🏆 Project Highlights

**What Makes This Industry-Grade:**

✅ Proven algorithm (SCAN used in production)  
✅ Safety-first design (hierarchical priority)  
✅ Comprehensive testing (automated verification)  
✅ Clean architecture (modular, maintainable)  
✅ Complete documentation (README + Viva guide)  
✅ Realistic timing (accurate models)  
✅ Professional code quality (comments, naming)  

**vs. Basic Student Projects:**

| Feature | Basic Project | This Project |
|---------|--------------|--------------|
| Scheduling | FCFS or none | **SCAN algorithm** |
| Safety | Basic | **Multi-layer priority** |
| Testing | Manual | **Automated self-check** |
| Documentation | Minimal | **Professional-grade** |
| Verification | "It works" | **25 test cases** |

---

## 📞 Support

If you have questions:

1. Check **VIVA_GUIDE.md** - 60 Q&A covering most topics
2. Review **README.md** - Technical deep dive
3. Check **Presentation.md** - Visual explanations
4. Review testbench comments - Shows expected behavior

---

## 🎉 You're Ready!

You now have:

✅ **Working RTL design** (smart_elevator.v)  
✅ **Comprehensive testbench** (tb_smart_elevator.v)  
✅ **Simulation scripts** (run_sim.ps1/sh)  
✅ **Complete documentation** (README.md)  
✅ **Viva preparation** (60 Q&A in VIVA_GUIDE.md)  
✅ **Presentation content** (25 slides in Presentation.md)  

**Go forth and ace that viva! 🚀**

---

*Last Updated: January 18, 2026*  
*Project: Smart Elevator Controller with SCAN Algorithm*
