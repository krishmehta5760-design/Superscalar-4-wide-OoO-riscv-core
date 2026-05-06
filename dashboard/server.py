import serial
import json
import asyncio
import websockets
import threading
import sys
import time
import os

# Configuration
BAUD_RATE = 115200
# Update this with your actual COM port (e.g., 'COM5' on Windows or '/dev/ttyUSB0' on Linux)
COM_PORT = 'COM9' 

clients = set()
latest_data = {"mode": "initializing"}

def read_serial():
    global latest_data
    try:
        print(f"Attempting to connect to {COM_PORT}...", flush=True)
        ser = serial.Serial(COM_PORT, BAUD_RATE, timeout=1)
        print(f"Connected to {COM_PORT} at {BAUD_RATE} baud.", flush=True)
    except Exception as e:
        print(f"Failed to connect to {COM_PORT}: {e}")
        print("Continuing in mock mode for UI testing...")
        ser = None

    buffer = ""
    while True:
        if ser:
            try:
                data = ser.read(ser.in_waiting or 1).decode('ascii', errors='ignore')
                if data:
                    print(f"RAW UART DATA: {repr(data)}", flush=True)
                buffer += data
            except Exception as e:
                print(f"Serial error: {e}")
                time.sleep(1)
                continue
        else:
            # Mock mode data generation
            time.sleep(0.2)
            buffer += "V,1,00,1,01,1,02\n"

        if '\n' in buffer:
            lines = buffer.split('\n')
            for line in lines[:-1]:
                line = line.strip()
                if not line: continue
                
                parts = line.split(',')
                if parts[0] == 'T':
                    if len(parts) >= 3:
                        latest_data = {
                            "mode": "turbo",
                            "cycles": int(parts[1], 16),
                            "commits": int(parts[2], 16)
                        }
                elif parts[0] == 'V':
                    # Visualizer Packet format: V,100,000,000
                    if len(parts) >= 4:
                        latest_data = {
                            "mode": "visual",
                            "dispatch": {"valid": parts[1][0] == '1', "tag": int(parts[1][1:], 16) if parts[1][1:] not in ('00', '0') else 0},
                            "execute": {"valid": parts[2][0] == '1', "tag": int(parts[2][1:], 16) if parts[2][1:] not in ('00', '0') else 0},
                            "commit": {"valid": parts[3][0] == '1', "tag": int(parts[3][1:], 16) if parts[3][1:] not in ('00', '0') else 0}
                        }
            buffer = lines[-1]

async def ws_handler(websocket):
    clients.add(websocket)
    try:
        while True:
            await websocket.send(json.dumps(latest_data))
            await asyncio.sleep(0.05)
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        clients.remove(websocket)

async def start_server():
    print("Starting WebSocket server on ws://localhost:8080", flush=True)
    async with websockets.serve(ws_handler, "localhost", 8080):
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    print("Initializing server thread...", flush=True)
    t = threading.Thread(target=read_serial, daemon=True)
    t.start()
    print("Starting async event loop...", flush=True)
    asyncio.run(start_server())
