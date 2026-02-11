
import asyncio
import subprocess
import json
import sys
import os
import shutil

# Configuration
HOST = "0.0.0.0"
PORT = 8766
COMPILER = "iverilog.exe"
RUNTIME = "vvp.exe"
V_FILES = ["backend/tb_interactive.v", "smart_elevator.v"]
OUT_FILE = "backend/sim.vvp"

async def compile_verilog():
    """Compiles the Verilog files."""
    print(f"Current Working Directory: {os.getcwd()}")
    
    # Auto-detect Icarus Verilog path
    global COMPILER, RUNTIME
    potential_paths = [
        r"C:\iverilog\bin",
        r"C:\Program Files\iverilog\bin",
        r"C:\Program Files (x86)\iverilog\bin",
        os.environ.get("IVERILOG_PATH", "")
    ]
    
    if not shutil.which(COMPILER):
        found = False
        for p in potential_paths:
            if os.path.exists(os.path.join(p, "iverilog.exe")):
                print(f"Found Icarus Verilog at: {p}")
                os.environ["PATH"] += os.pathsep + p
                found = True
                break
        
        if not found and not shutil.which(COMPILER):
            print(f"ERROR: {COMPILER} not found in PATH or standard locations.")
            print("Please install Icarus Verilog from: http://bleyer.org/icarus/")
            print("After installation, add it to your PATH or restart your terminal.")
            return False
        
    print(f"Compiling Verilog with {COMPILER}...")
    cmd = [COMPILER, "-o", OUT_FILE] + V_FILES
    proc = await asyncio.create_subprocess_exec(*cmd)
    ret = await proc.wait()
    if ret != 0:
        print("Compilation failed!")
        return False
    print("Compilation successful.")
    return True

class VerilogSim:
    def __init__(self):
        self.process = None

    async def start(self):
        """Starts the VVP simulation process."""
        self.process = await asyncio.create_subprocess_exec(
            RUNTIME, OUT_FILE,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        print("Simulation started.")
        # Consume the startup messages
        while True:
            line = await self.process.stdout.readline()
            decoded = line.decode().strip()
            print(f"Sim Output: {decoded}")
            if "READY" in decoded:
                break

    def write_command(self, char):
        """Writes a single character command to the simulation."""
        if self.process and self.process.stdin:
            self.process.stdin.write(char.encode())
            return True
        return False

    async def flush(self):
        if self.process and self.process.stdin:
            await self.process.stdin.drain()

    async def read_state(self):
        """Reads lines from simulation until a STATE line is found or error."""
        if not self.process:
            return None
        
        while True:
            try:
                line = await self.process.stdout.readline()
                if not line:
                    break
                decoded = line.decode().strip()
                print(f"RAW SIM: {decoded}") # RAW LOGGING
                
                if decoded.startswith("STATE:"):
                    return self.parse_state(decoded)
                elif decoded.startswith("ACK:"):
                    print(f"Ack received: {decoded}")
                else:
                    print(f"Sim Log: {decoded}")
            except Exception as e:
                print(f"Error reading sim: {e}")
                break
        return None

    def parse_state(self, line):
        """Parses STATE:X|FLOOR:Y|... into a dict."""
        parts = line.split('|')
        state_dict = {}
        for part in parts:
            if ':' in part:
                k, v = part.split(':', 1)
                k = k.strip()
                v = v.strip()
                state_dict[k] = int(v) if v.isdigit() else v
        return state_dict

async def echo(websocket):
    print("Client connected")
    sim = VerilogSim()
    await sim.start()

    try:
        async for message in websocket:
            # print(f"Recv: {message}") # Verbose logging
            data = json.loads(message)
            cmd_type = data.get("type")

            if cmd_type == "step":
                sim.write_command("S")
                await sim.flush()
                new_state = await sim.read_state()
                if new_state:
                     # print(f"Sending State: {new_state}")
                     await websocket.send(json.dumps(new_state))
            
            elif cmd_type == "request":
                floor = data.get("floor")
                print(f"Requesting Floor: {floor}")
                if 0 <= floor <= 7:
                    sim.write_command("R")
                    sim.write_command(str(floor))
                    await sim.flush()
            
            elif cmd_type == "reset":
                print("Resetting Simulation")
                sim.write_command("X")
                await sim.flush()

            elif cmd_type == "emergency":
                print(f"Emergency Toggle: {data.get('value')}")
                is_active = data.get("value") # boolean
                sim.write_command("E")
                sim.write_command("1" if is_active else "0")
                await sim.flush()

    except Exception as e:
        print(f"Connection closed: {e}")
    finally:
        if sim.process:
            sim.process.terminate()

async def main():
    if not await compile_verilog():
        sys.exit(1)
        
    print(f"Starting WebSocket server on ws://{HOST}:{PORT}")
    try:
        import websockets
    except ImportError:
        print("Error: 'websockets' library not found. Please install it:")
        print("pip install websockets")
        sys.exit(1)
        
    async with websockets.serve(echo, HOST, PORT, ping_interval=None):
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    asyncio.run(main())
