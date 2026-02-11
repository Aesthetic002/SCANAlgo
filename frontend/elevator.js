/**
 * Elevator Algorithm Comparison
 * SCAN vs FCFS (First-Come-First-Serve) Scheduling
 * 
 * This demonstrates the efficiency difference between algorithms
 */

// ==============================================================================
// State Definitions
// ==============================================================================
const STATES = {
    IDLE: 'IDLE',
    MOVE: 'MOVE',
    ARRIVE: 'ARRIVE',
    DOOR_OPEN: 'DOOR_OPEN',
    DOOR_WAIT: 'DOOR_WAIT',
    EMERGENCY: 'EMERGENCY'
};

const DIRECTION = {
    UP: 'UP',
    DOWN: 'DOWN'
};

// ==============================================================================
// Base Elevator Class
// ==============================================================================
class BaseElevator {
    constructor(type, config) {
        this.type = type; // 'scan' or 'fcfs'
        this.currentFloor = 0;
        this.targetFloor = 0;
        this.direction = DIRECTION.UP;
        this.state = STATES.IDLE;
        this.pendingRequests = [];
        this.emergency = false;

        // Statistics
        this.floorsTraversed = 0;
        this.requestsServed = 0;

        // Timing
        this.floorTravelTime = config?.floorTravelTime || 800;
        this.doorOpenTime = config?.doorOpenTime || 1500;
        this.doorWaitTime = config?.doorWaitTime || 500;

        // Timers
        this.moveTimer = null;
        this.doorTimer = null;

        // DOM Elements
        this.car = document.getElementById(`${type}Car`);
        this.arrow = document.getElementById(`${type}Arrow`);
        this.floorDisplay = document.getElementById(`${type}FloorDisplay`);
        this.floorsCountEl = document.getElementById(`${type}FloorsCount`);
        this.servedCountEl = document.getElementById(`${type}ServedCount`);
        this.stateEl = document.getElementById(`${type}State`);
        this.shaft = document.getElementById(`${type}Shaft`);
    }

    // Add request to queue (to be overridden)
    addRequest(floor) {
        if (floor < 0 || floor > 7 || this.emergency) return;
        if (!this.pendingRequests.includes(floor)) {
            this.pendingRequests.push(floor);
        }
        this.updateFloorIndicators();
        if (this.state === STATES.IDLE) {
            this.processNextState();
        }
    }

    // Get next target (to be overridden by subclass)
    getNextTarget() {
        return this.pendingRequests[0];
    }

    // Process state machine
    processNextState() {
        if (this.emergency) {
            this.setState(STATES.EMERGENCY);
            return;
        }

        switch (this.state) {
            case STATES.IDLE:
                if (this.pendingRequests.length > 0) {
                    const nextFloor = this.getNextTarget();
                    if (nextFloor === this.currentFloor) {
                        this.serveCurrentFloor();
                    } else {
                        this.targetFloor = nextFloor;
                        this.direction = nextFloor > this.currentFloor ? DIRECTION.UP : DIRECTION.DOWN;
                        this.setState(STATES.MOVE);
                        this.startMoveTimer();
                    }
                }
                break;

            case STATES.MOVE:
                // Move one floor
                const prevFloor = this.currentFloor;
                if (this.direction === DIRECTION.UP && this.currentFloor < 7) {
                    this.currentFloor++;
                } else if (this.direction === DIRECTION.DOWN && this.currentFloor > 0) {
                    this.currentFloor--;
                }

                if (prevFloor !== this.currentFloor) {
                    this.floorsTraversed++;
                }

                this.updatePosition();
                this.updateFloorIndicators();
                this.setState(STATES.ARRIVE);

                setTimeout(() => this.processNextState(), 100);
                break;

            case STATES.ARRIVE:
                const target = this.getNextTarget();
                if (target === this.currentFloor) {
                    this.serveCurrentFloor();
                } else if (this.pendingRequests.length > 0) {
                    this.targetFloor = this.getNextTarget();
                    this.direction = this.targetFloor > this.currentFloor ? DIRECTION.UP : DIRECTION.DOWN;
                    this.setState(STATES.MOVE);
                    this.startMoveTimer();
                } else {
                    this.setState(STATES.IDLE);
                }
                break;

            case STATES.DOOR_OPEN:
                // Timer handles transition
                break;

            case STATES.DOOR_WAIT:
                this.closeDoor();
                if (this.pendingRequests.length > 0) {
                    this.targetFloor = this.getNextTarget();
                    this.direction = this.targetFloor > this.currentFloor ? DIRECTION.UP : DIRECTION.DOWN;
                    this.setState(STATES.MOVE);
                    this.startMoveTimer();
                } else {
                    this.setState(STATES.IDLE);
                }
                break;
        }

        this.updateUI();
    }

    serveCurrentFloor() {
        // Remove from pending
        const index = this.pendingRequests.indexOf(this.currentFloor);
        if (index > -1) {
            this.pendingRequests.splice(index, 1);
            this.requestsServed++;
        }
        this.updateFloorIndicators();
        this.setState(STATES.DOOR_OPEN);
        this.startDoorTimer();
    }

    setState(newState) {
        this.state = newState;
        this.updateUI();
    }

    startMoveTimer() {
        this.stopMoveTimer();
        this.moveTimer = setTimeout(() => {
            this.processNextState();
        }, this.floorTravelTime);
    }

    stopMoveTimer() {
        if (this.moveTimer) {
            clearTimeout(this.moveTimer);
            this.moveTimer = null;
        }
    }

    startDoorTimer() {
        this.stopDoorTimer();
        this.openDoor();
        this.doorTimer = setTimeout(() => {
            this.setState(STATES.DOOR_WAIT);
            setTimeout(() => this.processNextState(), this.doorWaitTime);
        }, this.doorOpenTime);
    }

    stopDoorTimer() {
        if (this.doorTimer) {
            clearTimeout(this.doorTimer);
            this.doorTimer = null;
        }
    }

    openDoor() {
        this.car.classList.add('door-open');
    }

    closeDoor() {
        this.car.classList.remove('door-open');
    }

    updatePosition() {
        const floorHeight = 60;
        const bottomPosition = 5 + (this.currentFloor * floorHeight);
        this.car.style.bottom = `${bottomPosition}px`;
        this.floorDisplay.textContent = this.currentFloor;
    }

    updateFloorIndicators() {
        const indicators = this.shaft.querySelectorAll('.floor-indicator');
        indicators.forEach(indicator => {
            const classes = indicator.className.split(' ');
            const floorClass = classes.find(c => c.startsWith('floor-'));
            if (floorClass) {
                const floor = parseInt(floorClass.split('-')[1]);
                indicator.classList.toggle('active', floor === this.currentFloor);
                indicator.classList.toggle('requested', this.pendingRequests.includes(floor));
            }
        });
    }

    updateUI() {
        // Floor display
        this.floorDisplay.textContent = this.currentFloor;

        // Stats
        this.floorsCountEl.textContent = this.floorsTraversed;
        this.servedCountEl.textContent = this.requestsServed;
        this.stateEl.textContent = this.state;

        // Direction arrow
        if (this.state === STATES.MOVE) {
            this.arrow.classList.remove('hidden');
            this.arrow.classList.toggle('down', this.direction === DIRECTION.DOWN);
        } else {
            this.arrow.classList.add('hidden');
        }
    }

    setEmergency(active) {
        this.emergency = active;
        if (active) {
            this.stopMoveTimer();
            this.stopDoorTimer();
            this.setState(STATES.EMERGENCY);
        } else {
            this.setState(STATES.IDLE);
            this.processNextState();
        }
    }

    reset() {
        this.stopMoveTimer();
        this.stopDoorTimer();
        this.currentFloor = 0;
        this.targetFloor = 0;
        this.direction = DIRECTION.UP;
        this.state = STATES.IDLE;
        this.pendingRequests = [];
        this.floorsTraversed = 0;
        this.requestsServed = 0;
        this.emergency = false;
        this.closeDoor();
        this.updatePosition();
        this.updateFloorIndicators();
        this.updateUI();
    }
}

// ==============================================================================
// SCAN Elevator (Smart Algorithm)
// ==============================================================================
class ScanElevator extends BaseElevator {
    constructor(config) {
        super('scan', config);
    }

    // SCAN: Get next request in current direction, then reverse
    getNextTarget() {
        if (this.pendingRequests.length === 0) return this.currentFloor;

        // Get requests in current direction
        let inDirection = [];
        let otherDirection = [];

        if (this.direction === DIRECTION.UP) {
            inDirection = this.pendingRequests
                .filter(f => f >= this.currentFloor)
                .sort((a, b) => a - b);
            otherDirection = this.pendingRequests
                .filter(f => f < this.currentFloor)
                .sort((a, b) => b - a);
        } else {
            inDirection = this.pendingRequests
                .filter(f => f <= this.currentFloor)
                .sort((a, b) => b - a);
            otherDirection = this.pendingRequests
                .filter(f => f > this.currentFloor)
                .sort((a, b) => a - b);
        }

        if (inDirection.length > 0) {
            return inDirection[0];
        } else if (otherDirection.length > 0) {
            // Reverse direction
            this.direction = this.direction === DIRECTION.UP ? DIRECTION.DOWN : DIRECTION.UP;
            return otherDirection[0];
        }

        return this.currentFloor;
    }
}

// ==============================================================================
// FCFS Elevator (Conventional Algorithm)
// ==============================================================================
class FcfsElevator extends BaseElevator {
    constructor(config) {
        super('fcfs', config);
    }

    // FCFS: Simply get the first request in queue order
    getNextTarget() {
        if (this.pendingRequests.length === 0) return this.currentFloor;
        return this.pendingRequests[0];
    }
}

// ==============================================================================
// Remote Verilog Elevator (Connects to Backend)
// ==============================================================================
class RemoteScanElevator extends BaseElevator {
    constructor(config) {
        super('scan', config);
        this.socket = null;
        this.isConnected = false;
        this.stepping = false;
        this.connectionAttempts = 0;
        this.maxAttempts = 2; // Fall back after 2 failed attempts
        this.fallbackMode = false;
        this.fallbackElevator = null;
        this.connect();
    }

    connect() {
        if (this.fallbackMode) return;

        try {
            this.socket = new WebSocket('ws://localhost:8766');
        } catch (e) {
            console.warn("WebSocket not available, using JS fallback");
            this.activateFallback();
            return;
        }

        this.socket.onopen = () => {
            console.log("Connected to Verilog Backend");
            this.isConnected = true;
            this.connectionAttempts = 0;
            this.socket.send(JSON.stringify({ type: 'reset' }));
            this.stepping = true;
            this.processNextState();
        };

        this.socket.onmessage = (event) => {
            const data = JSON.parse(event.data);
            this.updateStateFromBackend(data);
        };

        this.socket.onerror = () => {
            console.warn("WebSocket connection error");
        };

        this.socket.onclose = () => {
            console.log("Disconnected from Backend");
            this.isConnected = false;
            this.stepping = false;
            this.connectionAttempts++;

            if (this.connectionAttempts >= this.maxAttempts) {
                console.log("Backend unavailable, switching to JS SCAN logic");
                this.activateFallback();
            } else {
                setTimeout(() => this.connect(), 2000);
            }
        };
    }

    activateFallback() {
        this.fallbackMode = true;
        console.log("🔄 Running SCAN in JavaScript mode (no Verilog backend)");
    }

    // SCAN algorithm fallback (same as ScanElevator)
    getNextTarget() {
        if (this.pendingRequests.length === 0) return this.currentFloor;

        let inDirection = [];
        let otherDirection = [];

        if (this.direction === DIRECTION.UP) {
            inDirection = this.pendingRequests
                .filter(f => f >= this.currentFloor)
                .sort((a, b) => a - b);
            otherDirection = this.pendingRequests
                .filter(f => f < this.currentFloor)
                .sort((a, b) => b - a);
        } else {
            inDirection = this.pendingRequests
                .filter(f => f <= this.currentFloor)
                .sort((a, b) => b - a);
            otherDirection = this.pendingRequests
                .filter(f => f > this.currentFloor)
                .sort((a, b) => a - b);
        }

        if (inDirection.length > 0) {
            return inDirection[0];
        } else if (otherDirection.length > 0) {
            this.direction = this.direction === DIRECTION.UP ? DIRECTION.DOWN : DIRECTION.UP;
            return otherDirection[0];
        }

        return this.currentFloor;
    }

    // Override: Send request to backend or use local logic
    addRequest(floor) {
        if (this.fallbackMode) {
            // Use base class SCAN logic
            super.addRequest(floor);
            return;
        }
        if (floor < 0 || floor > 7 || this.emergency) return;
        if (this.isConnected) {
            this.socket.send(JSON.stringify({ type: 'request', floor: floor }));
            if (!this.pendingRequests.includes(floor)) {
                this.pendingRequests.push(floor);
                this.updateFloorIndicators();
            }
        }
    }

    // Override: Emergency
    setEmergency(active) {
        if (this.fallbackMode) {
            super.setEmergency(active);
            return;
        }
        if (this.isConnected) {
            this.socket.send(JSON.stringify({ type: 'emergency', value: active }));
        }
    }

    // Override: Reset
    reset() {
        if (this.isConnected && !this.fallbackMode) {
            this.socket.send(JSON.stringify({ type: 'reset' }));
        }
        super.reset();
    }

    // Override: Main Loop
    processNextState() {
        if (this.fallbackMode) {
            // Use base class state machine
            super.processNextState();
            return;
        }
        if (this.isConnected && !this.emergency) {
            this.socket.send(JSON.stringify({ type: 'step' }));
        } else if (!this.isConnected) {
            console.warn("Skipping step: Not connected");
        }

        // Schedule next update
        if (this.state === STATES.MOVE) {
            setTimeout(() => this.processNextState(), 100); // 100ms per step
        } else {
            setTimeout(() => this.processNextState(), 200); // Slower when idle
        }
    }

    openDoor() {
        super.openDoor();
        // Backend handles timing, frontend just visualizes
    }

    updateStateFromBackend(data) {
        // Map backend state enum to frontend string
        const stateMap = {
            0: STATES.IDLE,
            1: STATES.MOVE,
            2: STATES.ARRIVE,
            3: STATES.DOOR_OPEN,
            4: STATES.DOOR_WAIT,
            5: STATES.EMERGENCY,
            6: 'OVERLOAD'
        };

        const prevFloor = this.currentFloor;
        const prevState = this.state;

        this.state = stateMap[data.STATE] || STATES.IDLE;
        this.currentFloor = data.FLOOR;
        this.direction = data.DIR === 1 ? DIRECTION.UP : DIRECTION.DOWN;

        // Track floors traversed
        if (this.currentFloor !== prevFloor) {
            this.floorsTraversed += Math.abs(this.currentFloor - prevFloor);
        }

        // Clear request when door opens at a floor
        if (this.state === STATES.DOOR_OPEN || this.state === STATES.DOOR_WAIT) {
            const index = this.pendingRequests.indexOf(this.currentFloor);
            if (index > -1) {
                this.pendingRequests.splice(index, 1);
                this.requestsServed++;
            }
            this.car.classList.add('door-open');
        } else {
            this.car.classList.remove('door-open');
        }

        // Emergency flag sync
        if (this.state === STATES.EMERGENCY) {
            this.emergency = true;
        } else if (this.emergency && this.state !== STATES.EMERGENCY) {
            this.emergency = false;
        }

        this.updatePosition();
        this.updateFloorIndicators();
        this.updateUI();
    }
}


// ==============================================================================
// Comparison Controller
// ==============================================================================
class ElevatorComparison {
    constructor() {
        const config = {
            floorTravelTime: 700,
            doorOpenTime: 1200,
            doorWaitTime: 400
        };

        this.scanElevator = new RemoteScanElevator(config);
        this.fcfsElevator = new FcfsElevator(config);
        this.sharedRequests = new Set();
        this.emergency = false;

        // Cache for preventing flickering
        this.lastQueueHtml = '';
        this.lastButtonStates = {};

        // DOM Elements
        this.queueDisplay = document.getElementById('queueDisplay');
        this.alarmOverlay = document.getElementById('alarmOverlay');
        this.scanBar = document.getElementById('scanBar');
        this.fcfsBar = document.getElementById('fcfsBar');
        this.scanTotal = document.getElementById('scanTotal');
        this.fcfsTotal = document.getElementById('fcfsTotal');
        this.efficiencyValue = document.getElementById('efficiencyValue');

        this.init();
    }

    init() {
        // Floor buttons
        document.querySelectorAll('.floor-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const floor = parseInt(btn.dataset.floor);
                this.requestFloor(floor);
            });
        });

        // Random button
        document.getElementById('randomBtn').addEventListener('click', () => {
            this.randomRequests();
        });

        // Reset button
        document.getElementById('resetBtn').addEventListener('click', () => {
            this.reset();
        });

        // Emergency button
        document.getElementById('emergencyBtn').addEventListener('click', () => {
            this.toggleEmergency();
        });

        // Dismiss alarm
        document.getElementById('dismissAlarm').addEventListener('click', () => {
            this.toggleEmergency();
        });

        // Start comparison update loop
        this.updateLoop();
    }

    requestFloor(floor) {
        if (this.emergency) return;

        this.sharedRequests.add(floor);
        this.scanElevator.addRequest(floor);
        this.fcfsElevator.addRequest(floor);
        this.updateQueueDisplay();
        this.updateFloorButtons();
    }

    randomRequests() {
        // Generate 3 random unique floors
        const floors = [];
        while (floors.length < 3) {
            const floor = Math.floor(Math.random() * 8);
            if (!floors.includes(floor)) {
                floors.push(floor);
            }
        }

        // Add with slight delay for visual effect
        floors.forEach((floor, i) => {
            setTimeout(() => this.requestFloor(floor), i * 200);
        });
    }

    toggleEmergency() {
        this.emergency = !this.emergency;
        document.getElementById('emergencyBtn').classList.toggle('active', this.emergency);
        this.alarmOverlay.classList.toggle('active', this.emergency);

        this.scanElevator.setEmergency(this.emergency);
        this.fcfsElevator.setEmergency(this.emergency);
    }

    reset() {
        this.sharedRequests.clear();
        this.scanElevator.reset();
        this.fcfsElevator.reset();
        this.emergency = false;
        document.getElementById('emergencyBtn').classList.remove('active');
        this.alarmOverlay.classList.remove('active');
        this.updateQueueDisplay();
        this.updateFloorButtons();
        this.updateComparison();
    }

    updateQueueDisplay() {
        // Get pending requests - show requests that are still pending in EITHER elevator
        const scanPending = new Set(this.scanElevator.pendingRequests);
        const fcfsPending = new Set(this.fcfsElevator.pendingRequests);

        // A request is "pending" if it's in at least one elevator's queue
        const allPending = new Set([...scanPending, ...fcfsPending]);

        let newHtml;
        if (allPending.size === 0) {
            newHtml = '<span class="no-requests">No pending requests</span>';
        } else {
            const sorted = Array.from(allPending).sort((a, b) => a - b);
            let html = '';
            sorted.forEach(floor => {
                // Show which elevator(s) still have this request pending
                const inScan = scanPending.has(floor);
                const inFcfs = fcfsPending.has(floor);
                let statusClass = 'queue-item';
                if (inScan && !inFcfs) {
                    statusClass += ' scan-only';
                } else if (!inScan && inFcfs) {
                    statusClass += ' fcfs-only';
                }
                html += `<span class="${statusClass}">${floor}</span>`;
            });
            newHtml = html;
        }

        // Only update DOM if content changed (prevents flickering)
        if (newHtml !== this.lastQueueHtml) {
            this.queueDisplay.innerHTML = newHtml;
            this.lastQueueHtml = newHtml;
        }
    }

    updateFloorButtons() {
        const scanPending = new Set(this.scanElevator.pendingRequests);
        const fcfsPending = new Set(this.fcfsElevator.pendingRequests);
        const allPending = new Set([...scanPending, ...fcfsPending]);

        document.querySelectorAll('.floor-btn').forEach(btn => {
            const floor = parseInt(btn.dataset.floor);
            const shouldBeRequested = allPending.has(floor);
            const currentState = this.lastButtonStates[floor];

            // Only update if state changed
            if (currentState !== shouldBeRequested) {
                btn.classList.toggle('requested', shouldBeRequested);
                this.lastButtonStates[floor] = shouldBeRequested;
            }
        });
    }

    updateComparison() {
        const scanFloors = this.scanElevator.floorsTraversed;
        const fcfsFloors = this.fcfsElevator.floorsTraversed;

        // Only update if values changed
        if (this.lastScanFloors === scanFloors && this.lastFcfsFloors === fcfsFloors) {
            return;
        }
        this.lastScanFloors = scanFloors;
        this.lastFcfsFloors = fcfsFloors;

        const maxFloors = Math.max(scanFloors, fcfsFloors, 1);

        // Update bar widths based on max (so one is always full)
        const scanPercent = (scanFloors / maxFloors) * 50;
        const fcfsPercent = (fcfsFloors / maxFloors) * 50;

        this.scanBar.style.width = `${scanPercent}%`;
        this.fcfsBar.style.width = `${fcfsPercent}%`;

        // Update values
        this.scanTotal.textContent = scanFloors;
        this.fcfsTotal.textContent = fcfsFloors;

        // Calculate efficiency
        if (fcfsFloors > 0 && scanFloors > 0) {
            const efficiency = ((fcfsFloors - scanFloors) / fcfsFloors * 100).toFixed(0);
            if (efficiency > 0) {
                this.efficiencyValue.textContent = `+${efficiency}%`;
                this.efficiencyValue.style.color = '#22c55e';
            } else if (efficiency < 0) {
                this.efficiencyValue.textContent = `${efficiency}%`;
                this.efficiencyValue.style.color = '#ef4444';
            } else {
                this.efficiencyValue.textContent = '0%';
                this.efficiencyValue.style.color = '#eab308';
            }
        } else {
            this.efficiencyValue.textContent = '--%';
        }
    }

    updateLoop() {
        this.updateQueueDisplay();
        this.updateFloorButtons();
        this.updateComparison();

        // Use 200ms update rate for smooth, flicker-free updates
        setTimeout(() => this.updateLoop(), 200);
    }
}

// ==============================================================================
// Initialize
// ==============================================================================
document.addEventListener('DOMContentLoaded', () => {
    window.comparison = new ElevatorComparison();
});
