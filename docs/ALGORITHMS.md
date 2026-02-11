# Algorithm Documentation: SCAN Scheduling

## 1. Introduction
The **SCAN Scheduling Algorithm**, often referred to as the "Elevator Algorithm," is a disk scheduling strategy that is also the standard for elevator control. It determines the order in which requests are serviced to minimize total travel time and prevent starvation.

### Core Principle
The algorithm dictates:
> "Continue in the current direction until there are no more requests in that direction, then reverse and service requests in the opposite direction."

This contrasts with:
*   **FCFS (First-Come, First-Served)**: Service requests strictly in arrival order (highly inefficient for elevators).
*   **SSTF (Shortest Seek Time First)**: Service the closest request next (can lead to starvation of distant requests).

---

## 2. SCAN Algorithm Logic

### Pseudocode
```python
current_direction = UP
current_floor = 0

function get_next_target(pending_requests):
    if pending_requests is empty:
        return current_floor (IDLE)

    # Filter requests based on direction
    requests_above = [r for r in pending_requests if r >= current_floor]
    requests_below = [r for r in pending_requests if r < current_floor]

    if current_direction == UP:
        if requests_above is not empty:
            return minimize(requests_above)  # Keep going UP to closest request
        elif requests_below is not empty:
            current_direction = DOWN         # REVERSE direction
            return maximize(requests_below)  # Start going DOWN from highest floor
    
    else (current_direction == DOWN):
        if requests_below is not empty:
            return maximize(requests_below)  # Keep going DOWN to closest request
        elif requests_above is not empty:
            current_direction = UP           # REVERSE direction
            return minimize(requests_above)  # Start going UP from lowest floor
```

### Example Scenario
**Initial State**: Floor 2, Direction UP.
**Requests Arrive**: Floor 5, Floor 1, Floor 7 (in that order).

1.  **Step 1**: Current Direction (UP). Check for requests > 2.
    *   Found: 5, 7.
    *   Target: 5 (closest). **Move to Floor 5**.
2.  **Step 2**: Current Direction (UP). Check for requests > 5.
    *   Found: 7.
    *   Target: 7. **Move to Floor 7**.
3.  **Step 3**: Current Direction (UP). Check for requests > 7.
    *   Found: None.
    *   **Action**: Reverse Direction to DOWN.
4.  **Step 4**: Current Direction (DOWN). Check for requests < 7.
    *   Found: 1.
    *   Target: 1. **Move to Floor 1**.

**Total Travel**: 2->5->7->1 (Total 3 + 2 + 6 = 11 floors).

---

## 3. Comparison: SCAN vs. FCFS

Our project includes a live simulation demonstrating the superiority of SCAN over FCFS.

### FCFS (First-Come, First-Served) Behavior
Using the same example:
**Initial State**: Floor 2.
**Requests Arrive**: Floor 5, Floor 1, Floor 7.

1.  **Target 1**: Floor 5 (First request). **Move 2->5**. (3 floors)
2.  **Target 2**: Floor 1 (Second request). **Move 5->1**. (4 floors)
3.  **Target 3**: Floor 7 (Third request). **Move 1->7**. (6 floors)

**Total Travel**: 3 + 4 + 6 = **13 floors**.

### Performance Metrics
*   **Throughput**: SCAN serves more requests per unit of time/distance.
*   **Average Wait Time**: improved for most users (though slightly worse for the edge request that causes a reversal).
*   **Efficiency**: SCAN reduces unnecessary reversals (changing direction consumes energy and time).

### Why SCAN is Industry Standard
1.  **Predictability**: Passengers know the elevator will continue in one direction.
2.  **Fairness**: Every request is guaranteed service in at most 2 sweeps (one up, one down).
3.  **Hardware Implementation**: Can be effectively implemented with simple comparison logic (as seen in our Verilog design).
