from wrapper import OoOCoreWrapper
from programs import PROGRAMS
import os
import json

def build_card(name, details, ipc, max_ipc, stalls, verification_pass):
    # Calculate percentages for the CSS width animations
    ipc_pct = min((ipc / max_ipc) * 100, 100) if max_ipc > 0 else 0
    stall_pct = min((stalls / 50) * 100, 100) 
    
    notes_html = "<ul>"
    for note in details.get("expo_notes", []):
        notes_html += f"<li>{note}</li>"
    notes_html += "</ul>"
    
    veri_class = "pass" if verification_pass else "fail"
    veri_text = "Verified: ✅" if verification_pass else "Data Error ❌"
    
    return f"""
    <div class="glass-card">
        <div class="card-header">
            <span class="test-name">{name}</span>
            <div>
                <span class="metric-pill veri-{veri_class}">{veri_text}</span>
                <span class="metric-pill">IPC: {ipc:.3f}</span>
            </div>
        </div>
        
        <div class="chart-container">
            <div class="bar-label">
                <span>Inst. Per Cycle (vs theoretical {max_ipc})</span>
                <span>{ipc:.2f}</span>
            </div>
            <div class="bar-bg">
                <div class="bar-fill" style="--target-width: {ipc_pct}%"></div>
            </div>
            
            <div class="bar-label">
                <span>Stalled Cycles</span>
                <span>{stalls}</span>
            </div>
            <div class="bar-bg">
                <div class="bar-fill stalls" style="--target-width: {stall_pct}%"></div>
            </div>
        </div>
        
        <div class="notes">
            {details["description"]}
            <br/><br/>
            <strong>Execution Notes:</strong>
            {notes_html}
        </div>
    </div>
    """

def generate_dashboard():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    print("[ExpoGen] Starting Expo Dashboard Generation...")
    
    core = OoOCoreWrapper()
    core._copy_rtl()
    
    total_ipc = 0
    total_tests = 0
    total_cycles = 0
    max_theoretical_ipc = 4.0 # 4-wide fetch and 4-wide retire commit width!
    
    cards_html = ""
    
    # Filter out branch mismatch test as per user request
    filtered_programs = {k: v for k, v in PROGRAMS.items() if k != "branch_test"}
    
    for key, test_data in filtered_programs.items():
        print(f"[ExpoGen] Simulating: {test_data['name']}...")
        try:
            res = core.run(test_data["instructions"], cycles=test_data["cycles"])
            summary = res.get("summary", {})
            ipc = summary.get("ipc", 0)
            stalls = summary.get("stall_cycles", 0)
            arch_regs = res.get("arch_regs", {})
            
            # Verify architectural state
            verification_pass = True
            expected = test_data.get("expected", {})
            for reg, expected_val in expected.items():
                actual_val = arch_regs.get(str(reg))
                # Hardware might hold negative in 32-bit unsigned, apply mask
                if actual_val is None:
                    verification_pass = False
                    print(f"      [Fail] Expected x{reg}={expected_val}, but it was never written.")
                elif (actual_val & 0xFFFFFFFF) != (expected_val & 0xFFFFFFFF):
                    verification_pass = False
                    print(f"      [Fail] Expected x{reg}={expected_val}, got {actual_val}.")
                    
            if verification_pass:
                print("      [Verify] Math is perfectly correct! PASS")
            
            total_ipc += ipc
            total_tests += 1
            total_cycles += test_data["cycles"]
            
            cards_html += build_card(test_data["name"], test_data, ipc, max_theoretical_ipc, stalls, verification_pass)
            
        except Exception as e:
            print(f"[ERROR] Failed test {key}: {e}")

    # Read template
    with open("template.html", "r", encoding="utf-8") as f:
        template = f.read()
        
    # Replace global stats
    avg_ipc = total_ipc / total_tests if total_tests > 0 else 0
    
    html = template.replace("{{TOTAL_TESTS}}", str(total_tests))
    html = html.replace("{{AVG_IPC}}", f"{avg_ipc:.3f}")
    html = html.replace("{{TOTAL_CYCLES}}", str(total_cycles))
    html = html.replace("<!-- INJECT_CARDS_HERE -->", cards_html)
    
    # Output file
    output_path = os.path.abspath("expo_dashboard.html")
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)
        
    print(f"\n[ExpoGen] SUCCESS! Dashboard written to: {output_path}")

if __name__ == "__main__":
    generate_dashboard()
