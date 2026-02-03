# Test Descriptions — Smart Elevator Controller

Date: 2026-01-19

This document lists the 28 automated checks in `tb_smart_elevator.v` with a short explanation for each.

1. **After reset, elevator at floor 0**: Verifies `current_floor == 0` on reset (initial state).
2. **After reset, all outputs inactive**: Confirms `motor_enable == 0`, `door_open == 0`, and `alarm == 0` after reset.
3. **Motor enabled when moving to floor 3**: After requesting floor 3, `motor_enable` should assert when movement begins.
4. **Elevator reached floor 3**: Confirms `current_floor == 3` after travel completes.
5. **Door opened at floor 3**: Ensures `door_open == 1` upon arrival at the requested floor.
6. **Door closed after timeout**: Verifies the door closes after the configured open/wait timers elapse.
7. **SCAN: Reached floor 2 first**: In a multi-request upward scenario, the first served floor should be 2 (SCAN order).
8. **SCAN: Direction still UP after floor 2**: Confirms elevator maintains UP direction after serving an upward request.
9. **SCAN: Reached floor 5 second**: Confirms second stop follows SCAN ordering.
10. **SCAN: Reached floor 7 last**: Confirms last stop in that upward batch is floor 7.
11. **Direction reversed to DOWN**: When only lower requests remain from top, direction flips to DOWN as per SCAN.
12. **Reached floor 3 after direction reversal**: Verifies correct arrival after reversal.
13. **SCAN: Served floor 2 (above) before reversing**: In mixed requests, an above request is served before reversing direction.
14. **SCAN: Served floor 4 continuing upward**: Confirms continuing upward service order.
15. **SCAN: Served floor 6 (last upward request)**: Confirms last upward request served before reversing.
16. **SCAN: After all upward served, reversed to floor 0**: Verifies elevator reverses and serves lower-side requests (ends at floor 0 in test).
17. **Emergency: Alarm activated**: When `emergency` asserted during motion, `alarm` must assert immediately.
18. **Emergency: Motor disabled**: Ensures `motor_enable` is deasserted during emergency.
19. **Emergency cleared: Alarm deactivated**: After clearing `emergency`, `alarm` must clear and normal operation resumes.
20. **Door opened at floor 2**: Sanity check that door opens at the requested floor before obstruction test begins.
21. **Door remained open after obstruction**: Simulates `door_sensor` during `DOOR_WAIT` and expects FSM to reopen/keep the door open (obstruction handling).
22. **Overload: Alarm activated**: When `overload` asserted at door open, `alarm` must assert.
23. **Overload: Motor disabled**: Ensures movement is prevented while `overload` is asserted.
24. **Overload cleared: Alarm deactivated**: After clearing `overload`, `alarm` must clear and operation continues.
25. **Door opened for request at current floor**: If a request targets the current floor, door should open immediately.
26. **Motor not activated for current floor request**: Verifies motor remains off when serving a request at the current floor.
27. **Stress test: Motor active with multiple requests**: After issuing many requests, `motor_enable` should be asserted while serving.
28. **Stress test: Elevator serving requests**: Checks `current_floor` moves within 1..7 during stress activity to verify active servicing.

Notes:
- These checks are self-contained and printed by the testbench; each increments `pass_count` or `fail_count` and logs a human-readable message.
- For waveform debugging, inspect `dut.state`, `dut.current_floor`, `dut.door_open`, `dut.door_timer`, `dut.door_sensor`, and `dut.motor_enable`.

End of file.
