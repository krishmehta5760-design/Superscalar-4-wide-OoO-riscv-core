import os
import shutil
import subprocess
import json
import sys

class OoOCoreWrapper:
    """
    A clean, from-scratch software wrapper to interact with the OoO RISC-V RTL.
    """
    def __init__(self, workspace_dir="."):
        self.workspace_dir = os.path.abspath(workspace_dir)
        self.verilog_src_dir = os.path.join(self.workspace_dir, "rtl")
        
    def _copy_rtl(self):
        """Copy Verilog sources locally to avoid Makefile space-in-path issues."""
        rtl_dst = os.path.join(self.workspace_dir, "rtl")
        os.makedirs(rtl_dst, exist_ok=True)
        import glob
        for f in glob.glob(os.path.join(self.verilog_src_dir, "*.v")):
            if os.path.getsize(f) > 0:
                dst_file = os.path.join(rtl_dst, os.path.basename(f))
                if os.path.abspath(f) != os.path.abspath(dst_file):
                    shutil.copy(f, rtl_dst)

    def _write_program_mem(self, instructions: list[int]):
        """
        Creates the program.mem file that Instruction_Mem.v loads via $readmemh.
        Expects 256 words (as per the new RTL updates).
        """
        mem_path = os.path.join(self.workspace_dir, "program.mem")
        
        # Ensure we write exactly 256 words, padding with 0s if necessary
        padded_instructions = instructions.copy()
        if len(padded_instructions) < 256:
            padded_instructions.extend([0] * (256 - len(padded_instructions)))
        elif len(padded_instructions) > 256:
            print(f"[Warning] Program exceeds 256 words. Truncating.")
            padded_instructions = padded_instructions[:256]
            
        with open(mem_path, "w") as f:
            for inst in padded_instructions:
                # Write as 8-character hex string (32-bit width)
                f.write(f"{inst:08x}\n")
                
        return mem_path

    def run(self, instructions: list[int], cycles: int = 50):
        """
        Run the simulation with standard arguments.
        """
        print(f"[Wrapper] Copying RTL locally...")
        self._copy_rtl()
        
        print(f"[Wrapper] Loading {len(instructions)} instructions...")
        self._write_program_mem(instructions)
        
        # We need to make sure we don't have leftover results from previous runs
        results_path = os.path.join(self.workspace_dir, "results.json")
        if os.path.exists(results_path):
            os.remove(results_path)
            
        env = os.environ.copy()
        env["SIM_CYCLES"] = str(cycles)
        
        # Execute the Makefile
        print(f"[Wrapper] Starting simulation for {cycles} cycles...")
        
        if sys.platform == "win32":
            # Running on Windows, use WSL bridge
            cmd = ["wsl", "bash", "-c", f"export PATH=\"$HOME/.local/bin:$PATH\"; SIM_CYCLES={cycles} make"]
        else:
            # Running directly in Linux/Ubuntu
            cmd = ["make"]

        process = subprocess.run(
            cmd,
            cwd=self.workspace_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            env=env
        )
        
        if process.returncode != 0:
            print("[Error] Simulation failed:")
            print(process.stdout)
            raise RuntimeError(f"Make failed with exit code {process.returncode}")
            
        # Parse output
        if os.path.exists(results_path):
            with open(results_path, "r") as f:
                results = json.load(f)
            print("[Wrapper] Simulation executed successfully!")
            print(process.stdout)
            return results
        else:
            print(process.stdout)
            raise FileNotFoundError("Simulation did not produce a results.json file.")
