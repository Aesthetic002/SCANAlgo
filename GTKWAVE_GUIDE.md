# GTKWave Signal Configuration Guide

This file helps you quickly set up GTKWave for optimal waveform viewing.

## Quick Setup Instructions

1. Run simulation to generate elevator_waveform.vcd
2. Open GTKWave: `gtkwave elevator_waveform.vcd`
3. In left panel (SST), expand: tb_smart_elevator → dut
4. Add signals in the order below

## Recommended Signal Groups

### Group 1: System Control (Blue)
- clk
- reset

### Group 2: FSM State (Red)
- state[3:0]
- next_state[3:0]

**State Values Reference:**
```
0000 (0) = IDLE
0001 (1) = MOVE
0010 (2) = ARRIVE
0011 (3) = DOOR_OPEN
0100 (4) = DOOR_WAIT
0101 (5) = EMERGENCY
0110 (6) = OVERLOAD
```

### Group 3: Requests (Green)
- req[7:0]
- pending_requests[7:0]

**Format:** Right-click → Data Format → Binary (easier to see individual floors)

### Group 4: Position & Direction (Orange)
- current_floor[2:0]
- target_floor[2:0]
- direction

**Format:** Right-click → Data Format → Decimal (for floor numbers)

### Group 5: Motor Control (Purple)
- motor_enable
- travel_counter[7:0]

### Group 6: Door Control (Cyan)
- door_open
- door_sensor
- door_timer[7:0]

### Group 7: Safety (Red)
- emergency
- overload
- alarm

## Display Format Tips

### For Floor Numbers
Right-click signal → Data Format → Decimal

### For Request Vectors
Right-click signal → Data Format → Binary
(Shows individual floor requests clearly)

### For State
Right-click signal → Data Format → Decimal or ASCII
Add a filter to show state names

### Add Markers
- Right-click on waveform → Add Marker
- Use markers to highlight:
  - State transitions
  - Floor arrivals
  - Safety events
  - Direction reversals

## Time Scale

- Default: ns (nanoseconds)
- Each clock cycle = 10 ns (100 MHz)
- Zoom: Mouse wheel or View menu
- Fit all: View → Zoom → Zoom Fit

## Color Coding

Use Edit → Highlight All → Color:
- Red: Safety signals (emergency, alarm)
- Green: Normal operation (motor, door)
- Blue: System signals (clk, reset)
- Orange: Position data

## Key Observations to Look For

### 1. SCAN Algorithm Verification
**Look for:** Sequential floor service in one direction

Example:
```
Time    Floor   Direction   Pending
----    -----   ---------   -------
100ns     0        UP       00101100  (floors 2,3,5 requested)
500ns     1        UP       00101100
1000ns    2        UP       00001100  (floor 2 served)
1500ns    3        UP       00000100  (floor 3 served)
2000ns    4        UP       00000100
2500ns    5        UP       00000000  (floor 5 served)
```

### 2. Direction Reversal
**Look for:** Direction changes only when no more requests in that direction

Marker: When pending_requests has only floors below current_floor, direction switches to DOWN

### 3. Timing Verification
**Count cycles:**
- Floor-to-floor travel: 50 cycles
- Door open duration: 30 cycles
- Door wait: 20 cycles

### 4. Safety Priority
**Look for:** 
- emergency=1 → state immediately goes to 5 (EMERGENCY)
- overload=1 → state goes to 6 (OVERLOAD)
- alarm activates in both cases

### 5. Door Obstruction
**Look for:**
- In DOOR_WAIT state (4)
- door_sensor goes high
- State returns to DOOR_OPEN (3)
- door_timer resets to 0

## GTKWave Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Ctrl + + | Zoom in |
| Ctrl + - | Zoom out |
| Ctrl + 0 | Zoom fit |
| Ctrl + F | Search signals |
| Home | Jump to start |
| End | Jump to end |
| → | Step forward |
| ← | Step backward |

## Sample Session Workflow

1. **Initial Setup (3 min)**
   - Open VCD file
   - Add all signals from groups 1-7
   - Set appropriate data formats
   - Color code signal groups

2. **SCAN Verification (5 min)**
   - Find a test with multiple requests
   - Place markers at each floor arrival
   - Verify sequential service
   - Check direction reversal

3. **Safety Testing (3 min)**
   - Find emergency test section
   - Verify immediate response
   - Check alarm activation
   - Confirm motor stop

4. **Timing Analysis (4 min)**
   - Zoom into single floor movement
   - Count cycles: should be 50
   - Check door timers
   - Verify all timing parameters

5. **Export (optional)**
   - File → Print To File → PNG
   - Capture key waveforms for report

## Advanced: Signal Filters

To show state names instead of numbers:

1. Right-click state signal
2. Select "Data Format" → "Translate Filter File"
3. Create a filter file (state_names.txt):

```
00 IDLE
01 MOVE
02 ARRIVE
03 DOOR_OPEN
04 DOOR_WAIT
05 EMERGENCY
06 OVERLOAD
```

4. Load filter file
5. State now shows names!

## Debugging Tips

### If you see unexpected behavior:

**Motor doesn't stop during emergency:**
- Check emergency signal is high
- Check state transitions to EMERGENCY (5)
- Verify motor_enable goes low

**Direction doesn't reverse:**
- Check pending_requests pattern
- Verify has_request_above/below logic
- Look at direction signal timing

**Floors skipped:**
- Normal! SCAN only stops at requested floors
- Check pending_requests has bit set for that floor

**Door doesn't reopen on obstruction:**
- Check door_sensor timing
- Verify state is DOOR_WAIT (4) when sensor triggers
- Look for state transition back to DOOR_OPEN (3)

## Screenshot Recommendations

For your report/presentation, capture:

1. **SCAN Algorithm**
   - Show multiple floors being served sequentially
   - Highlight pending_requests, current_floor, direction

2. **Direction Reversal**
   - Show direction bit changing
   - Show before/after pending_requests pattern

3. **Emergency Stop**
   - Show emergency activation
   - Show immediate motor disable
   - Show alarm activation

4. **Complete Test Cycle**
   - Zoomed out view of entire test
   - Shows multiple state transitions
   - Good overview diagram

## Waveform Analysis Checklist

Before concluding analysis:

- [ ] Verified SCAN serves floors in order
- [ ] Confirmed direction reversal logic
- [ ] Checked all timing parameters (50, 30, 20 cycles)
- [ ] Tested emergency interrupt
- [ ] Tested overload handling
- [ ] Verified door obstruction response
- [ ] Checked request latching works
- [ ] Confirmed no glitches on outputs
- [ ] Verified reset behavior
- [ ] Captured screenshots for report

## Common GTKWave Issues

**Issue: No signals visible**
- Click SST (left panel)
- Expand tree to find signals
- Select and drag to waveform area

**Issue: Everything shows 'x' or 'z'**
- Check VCD file was generated
- Verify testbench has $dumpvars
- Re-run simulation

**Issue: Time scale confusing**
- View → Time/Frame → Set to ns
- Check timescale in Verilog: `timescale 1ns/1ps`

**Issue: Can't see changes**
- Zoom in more (Ctrl++)
- Check signal has transitions
- Verify simulation ran long enough

## Presentation Tips

When showing waveforms in presentation:

1. **Zoom appropriately**
   - Not too much detail
   - Show 2-3 interesting events

2. **Use markers**
   - Highlight key transitions
   - Add text annotations

3. **Simplify signal list**
   - Only show relevant signals for that slide
   - Remove clutter

4. **Color code**
   - Make important signals stand out
   - Use contrasting colors

5. **Export high quality**
   - File → Print → PDF
   - Or screenshot at high resolution

---

**With proper waveform analysis, you can:**
- Prove your design works correctly
- Debug any issues quickly
- Demonstrate understanding in viva
- Create impressive report figures

Happy waveform viewing! 📊
