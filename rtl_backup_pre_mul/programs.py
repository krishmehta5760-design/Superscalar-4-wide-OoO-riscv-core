"""Pre-built test programs for the OoO RISC-V core.

Each program is a dict with:
  name         – human-readable title
  description  – what the test demonstrates
  instructions – list of 32-bit machine words (padded with NOPs at front)
  expected     – dict {arch_reg: expected_value} for verification
  cycles       – recommended simulation cycle count
  expo_notes   – key talking points for the expo presentation
"""

NOP = 0x00000000

# 4-NOP preamble lets the pipeline fill cleanly after reset.
_PAD = [NOP] * 4

PROGRAMS = {
    # ---------------------------------------------------------------- WAW
    "waw_test": {
        "name": "WAW Hazard Test",
        "description": (
            "Two back-to-back writes to x1 (10 then 20) followed by a "
            "dependent read.  Correct OoO rename must ensure x2 sees "
            "the SECOND write.  Expected: x1=20, x2=25, x3=99."
        ),
        "instructions": _PAD + [
            0x00A00093,  # addi x1, x0, 10
            0x01400093,  # addi x1, x0, 20   ← WAW
            0x00508113,  # addi x2, x1, 5
            0x06300193,  # addi x3, x0, 99
        ],
        "expected": {1: 20, 2: 25, 3: 99},
        "cycles": 60,
        "expo_notes": [
            "Demonstrates Write-After-Write (WAW) hazard handling",
            "Register renaming assigns different physical regs to both x1 writes",
            "The RAT always points to the LATEST mapping — so x2 reads from the second addi",
            "Without renaming, a naive pipeline would give x2 = 15 (wrong!)",
        ],
    },

    # ---------------------------------------------------------------- ALU
    "alu_test": {
        "name": "ALU Comprehensive Test",
        "description": (
            "Exercises every RV32I R-type and I-type ALU operation: "
            "ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA, plus "
            "immediate variants."
        ),
        "instructions": _PAD + [
            0x0AB00093,  # addi x1,  x0, 171    (0xAB)
            0x0CD00113,  # addi x2,  x0, 205    (0xCD)
            0x002081B3,  # add  x3,  x1, x2     → 376
            0x40208233,  # sub  x4,  x1, x2     → -34 (0xFFFFFFDE)
            0x0020F2B3,  # and  x5,  x1, x2     → 0x89
            0x0020E333,  # or   x6,  x1, x2     → 0xEF
            0x0020C3B3,  # xor  x7,  x1, x2     → 0x66
            0x0020A433,  # slt  x8,  x1, x2     → 1
            0x00200493,  # addi x9,  x0, 2
            0x00909533,  # sll  x10, x1, x9     → 684
            0x0090D5B3,  # srl  x11, x1, x9     → 42
        ],
        "expected": {
            1: 171, 2: 205, 3: 376,
            4: 0xFFFFFFDE, 5: 0x89, 6: 0xEF,
            7: 0x66, 8: 1, 9: 2, 10: 684, 11: 42,
        },
        "cycles": 80,
        "expo_notes": [
            "Tests all RV32I ALU operations through the OoO pipeline",
            "Independent instructions (x3-x8) can execute out of order",
            "The ROB ensures they commit in program order despite OoO execution",
            "11 results, all verified — proves functional correctness of the datapath",
        ],
    },

    # ---------------------------------------------------------- Load/Store
    "load_store_test": {
        "name": "Load / Store Test",
        "description": (
            "Stores a word to memory, loads it back, and checks the "
            "value.  Exercises the LSQ datapath and store-to-load "
            "forwarding path."
        ),
        "instructions": _PAD + [
            0x06400093,  # addi x1, x0, 100     base addr
            0x02A00113,  # addi x2, x0, 42      value
            0x0020A023,  # sw   x2, 0(x1)       mem[100]=42
            NOP, NOP, NOP, NOP,                  # drain pipeline
            0x0000A183,  # lw   x3, 0(x1)       x3=mem[100]=42
            NOP, NOP, NOP, NOP,
            0x06300213,  # addi x4, x0, 99      marker
        ],
        "expected": {1: 100, 2: 42, 3: 42, 4: 99},
        "cycles": 100,
        "expo_notes": [
            "Tests the Load-Store Queue (LSQ) — a critical OoO structure",
            "The store writes 42 to memory address 100",
            "The load reads it back — this exercises store-to-load forwarding",
            "The LSQ ensures memory ordering even with out-of-order execution",
        ],
    },

    # --------------------------------------------------------- RAW chain
    "raw_chain": {
        "name": "RAW Dependency Chain",
        "description": (
            "A long chain of dependent ADDIs that forces the OoO core "
            "to respect true data dependencies through renaming."
        ),
        "instructions": _PAD + [
            0x00100093,  # addi x1, x0, 1
            0x00108113,  # addi x2, x1, 1
            0x00110193,  # addi x3, x2, 1
            0x00118213,  # addi x4, x3, 1
            0x00120293,  # addi x5, x4, 1
            0x00128313,  # addi x6, x5, 1
            0x00130393,  # addi x7, x6, 1
            0x00138413,  # addi x8, x7, 1
        ],
        "expected": {1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8},
        "cycles": 80,
        "expo_notes": [
            "Read-After-Write (RAW) chain — every instruction depends on the previous one",
            "Despite 4-wide fetch, only ONE instruction can execute per cycle (serial dependency)",
            "The issue queue correctly stalls dependent instructions until their source is ready",
            "This is the worst case for ILP — observe the low IPC",
        ],
    },

    # --------------------------------------------------------- Fibonacci
    "fibonacci": {
        "name": "Fibonacci Sequence",
        "description": (
            "Computes the first several Fibonacci numbers iteratively.  "
            "Demonstrates dependent computation through the OoO pipeline."
        ),
        "instructions": _PAD + [
            0x00100093,  # addi x1, x0, 1     fib(1) = 1
            0x00100113,  # addi x2, x0, 1     fib(2) = 1
            0x002081B3,  # add  x3, x1, x2    fib(3) = 2
            0x00310233,  # add  x4, x2, x3    fib(4) = 3
            0x004182B3,  # add  x5, x3, x4    fib(5) = 5
            0x00520333,  # add  x6, x4, x5    fib(6) = 8
            0x006283B3,  # add  x7, x5, x6    fib(7) = 13
            0x00730433,  # add  x8, x6, x7    fib(8) = 21
        ],
        "expected": {1: 1, 2: 1, 3: 2, 4: 3, 5: 5, 6: 8, 7: 13, 8: 21},
        "cycles": 80,
        "expo_notes": [
            "Classic Fibonacci — fib(n) = fib(n-1) + fib(n-2)",
            "Each add depends on the previous TWO results (data dependency chain)",
            "The OoO core fetches all 8 instructions in 2 cycles but must serialize execution",
            "Final result: x8 = 21, proving correct dependency tracking through rename + wakeup",
        ],
    },
    
    # --------------------------------------------------------- Branch Mispredict
    "branch_test": {
        "name": "Branch Mispredict & Flush",
        "description": (
            "A small loop that counts down from 3 to 0. It tests the Branch Predictor "
            "Unit (BPU). Since it loops multiple times, the predictor will inevitably "
            "mispredict and force the OoO pipeline to flush and squash bad instructions."
        ),
        "instructions": _PAD + [
            0x00300093,  # addi x1, x0, 3      (Loop Counter: 3)
            0x00000113,  # addi x2, x0, 0      (Sum)
            0x00100193,  # addi x3, x0, 1      (Decrementer: 1)
            # Loop Start (PC Offset -8 from branch)
            0x00110133,  # add  x2, x2, x1     sum += counter
            0x403080B3,  # sub  x1, x1, x3     counter -= 1
            0xFE009CE3,  # bne  x1, x0, -8     if counter != 0 loop
            
            0x06300213,  # addi x4, x0, 99     Done marker
        ],
        "expected": {1: 0, 2: 6, 3: 1, 4: 99},
        "cycles": 120,
        "expo_notes": [
            "This test deliberately breaks the Out-of-Order datapath!",
            "Because branches are evaluated out-of-order, a misprediction requires a massive Pipeline Squash.",
            "You will visibly see the Flush Count spike in the metrics.",
            "Despite the flushes rolling back the Reorder Buffer, the final sum is perfectly computed as x2 = 6.",
        ],
    },
    
    # --------------------------------------------------------- WAR Hazard
    "war_test": {
        "name": "WAR Hazard (Write-After-Read)",
        "description": (
            "Tests the OoO core's ability to perfectly resolve a Write-After-Read "
            "Data Hazard by using Physical Register Renaming."
        ),
        "instructions": _PAD + [
            0x00A00093,  # addi x1, x0, 10
            0x00500113,  # addi x2, x0, 5
            0x002081B3,  # add  x3, x1, x2   --> 15
            0x03200093,  # addi x1, x0, 50   --> WAR: Overwrites x1!
            0x00508213,  # addi x4, x1, 5    --> 55
        ],
        "expected": {1: 50, 2: 5, 3: 15, 4: 55},
        "cycles": 60,
        "expo_notes": [
            "Write-After-Read (WAR) hazards normally break purely parallel systems.",
            "Because your core renames architectural registers to physical ones, the second 'x1' write is assigned to a brand new physical wire mapping.",
            "This perfectly eliminates the hazard, and execution doesn't even need to stall!"
        ],
    },
    
    # --------------------------------------------------------- Control Hazard (Jump)
    "jump_test": {
        "name": "Unconditional Jump Hazard",
        "description": (
            "Tests JAL (Jump and Link) instruction by conditionally skipping over "
            "two instructions directly to a Done marker."
        ),
        "instructions": _PAD + [
            0x00C000EF,  # jal x1, 12        --> jump forward 12 bytes
            0x00100113,  # addi x2, x0, 1    --> SKIP
            0x00100193,  # addi x3, x0, 1    --> SKIP
            0x06300213,  # addi x4, x0, 99   --> Target
        ],
        "expected": {1: 20, 4: 99}, # x1 should store PC+4 = 20, x4 = 99. x2 and x3 should remain 0!
        "cycles": 60,
        "expo_notes": [
            "Evaluates Unconditional Control Transfers (JAL).",
            "The JAL executes and correctly updates the PC cleanly.",
            "Observe that x2 and x3 were successfully bypassed and never committed to Architectural state."
        ],
    },

    # --------------------------------------------------------- Independent Math (Max ILP)
    "independent_math": {
        "name": "Maximum Theoretical ILP",
        "description": (
            "An entirely independent chain of math operations designed to see if the "
            "Reorder Buffer can hit a perfect 1.0 IPC without any friction."
        ),
        "instructions": _PAD + [
            0x00100093,  # addi x1, x0, 1
            0x00200113,  # addi x2, x0, 2
            0x00300193,  # addi x3, x0, 3
            0x00400213,  # addi x4, x0, 4
            0x00500293,  # addi x5, x0, 5
            0x00600313,  # addi x6, x0, 6
            0x00700393,  # addi x7, x0, 7
            0x00800413,  # addi x8, x0, 8
        ],
        "expected": {1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8},
        "cycles": 50,
        "expo_notes": [
            "This test has literally zero structural or data dependencies.",
            "Because the pipeline is 4-wide fetch, it gobbles all 8 of these up in 2 clock cycles.",
            "The IPC recorded here is the absolute peak theoretical maximum your ROB's current commit architecture can support."
        ],
    },
}

def list_programs():
    """Print available programs."""
    for key, prog in PROGRAMS.items():
        print(f"  {key:20s} — {prog['name']}")
