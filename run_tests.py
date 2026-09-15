#!/usr/bin/env python3
import os
import sys
import subprocess
import re
from pathlib import Path

DEFAULT_AHK_PATHS = [
    r"C:\AHK\AutoHotkey_2.0.18\AutoHotkey64.exe",
    r"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe",
    r"C:\Program Files\AutoHotkey\AutoHotkey64.exe",
]

def find_ahk():
    for p in DEFAULT_AHK_PATHS:
        if os.path.isfile(p):
            return p
    return None

def main():
    ahk_bin = find_ahk()
    if not ahk_bin:
        print("ERROR: AutoHotkey v2 executable not found in default paths.", file=sys.stderr)
        sys.exit(1)
        
    repo_root = Path(__file__).resolve().parent
    failures = []
    
    # 1. ClipboardUtil Unit Test
    test1_path = repo_root / "tests" / "test_ClipboardUtil.ahk"
    if test1_path.exists():
        res1 = subprocess.run([ahk_bin, "/ErrorStdOut", str(test1_path)], cwd=str(repo_root), capture_output=True, text=True)
        if res1.returncode != 0 or "FAILURE:" in res1.stdout:
            print(f"FAILED: {test1_path.relative_to(repo_root)}")
            print(res1.stdout or res1.stderr)
            failures.append("test_ClipboardUtil.ahk")
        else:
            print(f"PASSED: {test1_path.relative_to(repo_root)}")
    else:
        print(f"SKIPPED: {test1_path.relative_to(repo_root)} (not found)")
        
    # 2. Headless FSM Regression Suite
    test2_path = repo_root / "kardenwort-window" / "tests" / "test_fsm_headless.ahk"
    results2_file = repo_root / "kardenwort-window" / "tests" / "test_fsm_headless_results.txt"
    if test2_path.exists():
        if results2_file.exists():
            try:
                results2_file.unlink()
            except Exception:
                pass
        res2 = subprocess.run([ahk_bin, str(test2_path)], cwd=str(repo_root), capture_output=True, text=True)
        results2_content = results2_file.read_text(encoding="utf-8", errors="replace") if results2_file.exists() else ""
        
        m2 = re.search(r"Tests Passed:\s*(\d+/\d+)", results2_content)
        detail2 = f" ({m2.group(1)})" if m2 else ""
        
        if res2.returncode != 0 or "FAILURES:" in results2_content:
            print(f"FAILED: {test2_path.relative_to(repo_root)}{detail2}")
            if results2_content:
                print(results2_content)
            failures.append("test_fsm_headless.ahk")
        else:
            print(f"PASSED: {test2_path.relative_to(repo_root)}{detail2}")
    else:
        print(f"SKIPPED: {test2_path.relative_to(repo_root)} (not found)")

    # 3. Kardenwort Window Comprehensive Suite
    test3_path = repo_root / "kardenwort-window" / "tests" / "test_kardenwort_window.ahk"
    results3_file = repo_root / "kardenwort-window" / "tests" / "test_results.txt"
    if test3_path.exists():
        if results3_file.exists():
            try:
                results3_file.unlink()
            except Exception:
                pass
        res3 = subprocess.run([ahk_bin, str(test3_path)], cwd=str(repo_root), capture_output=True, text=True)
        results3_content = results3_file.read_text(encoding="utf-8", errors="replace") if results3_file.exists() else ""
        
        m3 = re.search(r"Summary:\s*(\d+/\d+)\s+tests passed", results3_content)
        detail3 = f" ({m3.group(1)})" if m3 else ""
        
        if res3.returncode != 0 or "FAILURE:" in results3_content or (m3 and m3.group(1).split("/")[0] != m3.group(1).split("/")[1]):
            print(f"FAILED: {test3_path.relative_to(repo_root)}{detail3}")
            if results3_content:
                print(results3_content)
            failures.append("test_kardenwort_window.ahk")
        else:
            print(f"PASSED: {test3_path.relative_to(repo_root)}{detail3}")
    else:
        print(f"SKIPPED: {test3_path.relative_to(repo_root)} (not found)")

    print("-" * 50)
    if failures:
        print(f"FAIL: {len(failures)} suite(s) failed: {', '.join(failures)}")
        sys.exit(1)
    else:
        print("SUCCESS: All AutoHotkey test suites passed.")
        sys.exit(0)

if __name__ == "__main__":
    main()
