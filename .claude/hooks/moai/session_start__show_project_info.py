#!/usr/bin/env python3
"""
Session Start Hook - Displays FPGA project rules automatically
Updated with Git workflow rules
"""
import os
import sys
from pathlib import Path

def main():
    project_dir = Path(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))
    rules_file = project_dir / ".claude" / "rules" / "fpga-simulation-rules.md"
    
    print("\n" + "=" * 60)
    print("🔧 CYAN-FPGA PROJECT RULES LOADED")
    print("=" * 60)
    
    if rules_file.exists():
        with open(rules_file, "r", encoding="utf-8") as f:
            content = f.read()
            # Print key rules summary
            lines = content.split("\n")
            in_section = False
            section_count = 0
            for line in lines:
                if line.startswith("###") or line.startswith("## "):
                    in_section = True
                    section_count += 1
                    if section_count <= 12:  # Increased for Git rules
                        print(line)
                elif in_section and line.startswith("|"):
                    print(line)
                elif in_section and line.startswith("**") and "error" in line.lower():
                    print(line)
                elif in_section and line and not line.startswith("#"):
                    if section_count <= 12:
                        print(line)
                if section_count > 12:
                    break
        print(f"\n📄 Full rules: .claude/rules/fpga-simulation-rules.md")
    else:
        print("⚠️  Rules file not found")
    
    print("=" * 60)
    
    # Quick Git workflow reminder
    print("\n⚡ Git Workflow Quick Check:")
    print("  Before checkout: git stash push -m 'msg'")
    print("  Merge to main:   git merge branch --no-ff")
    print("=" * 60 + "\n")

if __name__ == "__main__":
    main()
