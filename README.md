# 🚀 Superscalar 4-Wide Out-of-Order RISC-V Core

[![Status](https://img.shields.io/badge/Status-Expo--Ready-success.svg)]()
[![Architecture](https://img.shields.io/badge/ISA-RV32I%2BM-blue.svg)]()
[![Performance](https://img.shields.io/badge/Peak--IPC-3.28-orange.svg)]()

A high-performance, synthesizable **4-wide Superscalar Out-of-Order (OoO) RISC-V Processor** implemented in Verilog. This core is designed for maximum instruction-level parallelism (ILP) using dynamic scheduling, rigorous register renaming, and speculative execution.

---

## 💎 Key Architectural Features

### 🏎️ High-Performance Back-end
*   **4-Wide Dispatch & Commit**: Capable of fetching and retiring up to 4 instructions per cycle.
*   **3-Stage Pipelined Multiplier**: (New!) High-throughput MUL/MULH unit that allows multiple math operations to overlap without stalling the pipeline.
*   **Dynamic Scheduling**: 16-entry unified Issue Queue (IQ) that dispatches instructions to execution units as soon as operands are ready.

### 🛡️ Hardware Hazard Management
*   **Full Register Renaming**: 128-entry Physical Register File (PRF) managed by a Register Alias Table (RAT) to eliminate **WAW** and **WAR** hazards entirely.
*   **Memory Disambiguation**: Advanced Load-Store Queue (LSQ) that handles out-of-order memory accesses and store-to-load forwarding.
*   **Speculative Execution**: Integrated Branch Prediction Unit (BPU) with a fast pipeline flush/squash mechanism for misprediction recovery.

---

## 📈 Verified Performance Metrics
*Measured using the automated `run_tests.py` suite.*

| Benchmark | Focus Area | Peak IPC | Status |
| :--- | :--- | :---: | :---: |
| **Maximum ILP** | Global Throughput | **3.28** | ✅ PASS |
| **WAW/WAR Tests** | Rename Logic | **3.10** | ✅ PASS |
| **Pipelined MUL** | Math Throughput | **3.10** | ✅ PASS |
| **Fibonacci** | Data Dependency | **2.19** | ✅ PASS |
| **Branch/Jump** | Control Hazards | **3.22** | ✅ PASS |

---

## 🛠️ Getting Started

### Prerequisites
*   **Simulator**: Icarus Verilog (v12.0+)
*   **Verification**: Python 3.12+ with `cocotb`
*   **Environment**: WSL2 / Ubuntu (Recommended)

### Run Benchmarks
To reproduce the IPC results and generate the hardware performance report:
```bash
python3 run_tests.py
```

---

## 📂 Internal Project Structure
- `rtl/` : Core Verilog modules (ALU, ROB, PRF, LSQ, etc.).
- `run_tests.py` : Automates the architectural benchmark suite.
- `wrapper.py` : Python-to-HDL bridge for functional verification.
- `sim_tb.py` : Cocotb-driven testbench with real-time performance tracking.

---

**Developed for the RISC-V Hardware Expo**  
Created by **Krish Mehta**
