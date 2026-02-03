# CYAN FPGA Project Documentation

## Quick Start: Where Do I Begin?

### New to the Project? Start Here:

1. **5 Minutes** - Read this Overview section
2. **15 Minutes** - Review Known Issues below
3. **30 Minutes** - Read TECHNICAL_REFERENCE.md for architecture details
4. **1 Hour** - Study IMPROVEMENT_PLAN.md for quality roadmap
5. **Ongoing** - Use the Documentation Guide below for reference

### Getting Started Workflow

Start Here (README.md) -> Understand System Architecture -> Review Known Issues -> Plan Your Work (IMPROVEMENT_PLAN.md) -> Access Technical Details (TECHNICAL_REFERENCE.md) -> Reference Materials

---

## Overview

The CYAN FPGA project is a Xilinx Artix-7 based FPGA design for Readout Integrated Circuit (ROIC) control and MIPI CSI-2 data transmission.

**Target Hardware**: Xilinx Artix-7 XC7A35TFGG484-1

**Primary Features**:
- Multi-clock domain system (200MHz, 100MHz, 20MHz, 5MHz, 1MHz)
- MIPI CSI-2 TX output for video streaming
- LVDS interface for TI ROIC data capture (12 channels)
- SPI slave interface for register control
- Configurable sequencer FSM for acquisition control
- Support for multiple acquisition modes
- Integrated ILA for debugging

---

## Current Status and Known Issues

**Status**: Development Phase with Known Issues

Critical Issues: 3 (HIGH/CRITICAL - Require Immediate Action)
High Priority: 3 (MEDIUM - Planned for Phase 2)
Low Priority: 2 (LOW - Backlog)

### Critical Issues

| Issue ID | Category | Severity | Impact |
|----------|----------|----------|--------|
| CDC-001 | CDC Violation | CRITICAL | Metastability, data corruption |
| CDC-002 | Missing Constraints | CRITICAL | Timing violations, unstable operation |
| RST-001 | Reset Inconsistency | HIGH | Unpredictable initialization |

### Low Priority Issues

| Issue ID | Category | Severity | Impact | Notes |
|----------|----------|----------|--------|-------|
| TRI-001 | Tri-State Design | LOW | Documentation | Intentional design - add comments only |


### Quality Metrics (Current vs Target)

| Metric | Current | Target (Phase 1) | Target (Final) |
|--------|---------|------------------|----------------|
| CDC Violations | 8+ | 0 | 0 |
| Reset Consistency | 30% | 100% | 100% |
| Test Coverage | 23% | 50% | 90% |
| FSM Standard Compliance | 0% | 50% | 100% |

**What needs to be done?** See IMPROVEMENT_PLAN.md for complete roadmap.

---

## Documentation Guide

### Core Documentation (Markdown)

| Document | Purpose | When to Use |
|----------|---------|-------------|
| README.md (this file) | Project overview and navigation hub | Starting point, finding resources |
| IMPROVEMENT_PLAN.md | Quality improvement roadmap, issue tracking | Planning work, understanding priorities |
| TECHNICAL_REFERENCE.md | Technical specs, module details, refactoring guidelines | Understanding implementation |

### Reference Materials (Binary Files)

| File | Purpose |
|------|---------|
| fpga_block_diagram.png | System architecture visualization |
| ROIC_timing_chart.xlsx | ROIC timing specifications |
| Xdaq_Register_Map.xlsx | Register map documentation |
| Xdaq_Register_Map_24.xlsx | Register map (24-bit version) |
| xdaq_fpga_design.pptx | Design presentation |

### How to Use Each Document

**For Project Understanding:**
1. Start with README.md (this file) for project context
2. Review fpga_block_diagram.png for visual architecture
3. Read TECHNICAL_REFERENCE.md Section 3 for ROIC Gate Driver

**For Development Work:**
1. Check IMPROVEMENT_PLAN.md for current phase priorities
2. Review TECHNICAL_REFERENCE.md Section 4 for refactoring guidelines
3. Consult ROIC_timing_chart.xlsx for timing requirements
4. Reference Xdaq_Register_Map.xlsx for register definitions

**For Issue Resolution:**
1. Look up issue ID in IMPROVEMENT_PLAN.md Issue Summary
2. Read detailed analysis in Detailed Issue Analysis section
3. Follow recommended fix with code examples
4. Verify against success criteria

---

## System Architecture

### Clock Domain Architecture

| Clock Domain | Frequency | Description | Primary Usage |
|--------------|-----------|-------------|---------------|
| CLK_200MHZ | 200 MHz | DPHY high-speed clock | MIPI CSI-2 TX data path |
| CLK_100MHZ | 100 MHz | Main system clock | Register map, control logic |
| CLK_20MHZ | 20 MHz | Processing clock | Data reordering, sequencer |
| CLK_5MHZ | 5 MHz | Slow clock | Timing generation |
| CLK_1MHZ | 1 MHz | Very slow clock | Low-speed timers |

**Where are the technical specs?** See TECHNICAL_REFERENCE.md for detailed architecture.

---

## Development Roadmap

### 4-Phase Improvement Plan (8 Weeks)

| Phase | Focus | Duration | Status |
|-------|-------|----------|--------|
| Phase 1 | Critical Safety | Week 1 | Not Started |
| Phase 2 | Design Robustness | Weeks 2-3 | Planned |
| Phase 3 | Quality Infrastructure | Weeks 4-6 | Planned |
| Phase 4 | Optimization | Weeks 7-8 | Planned |

### Current Phase: Phase 1 - Critical Safety

**Key Tasks:**
- [ ] Fix all CDC violations (Days 1-3)
- [ ] Add comprehensive timing constraints (Days 1-2)
- [ ] Standardize reset strategy (Days 2-3)
- [ ] Remove internal tri-state buses (Day 1)
- [ ] Create CDC testbenches (Days 3-5)

**Detailed roadmap**: See IMPROVEMENT_PLAN.md for complete task breakdown.

---

## Quick Reference

### Project Status
- Current Quality Metrics: IMPROVEMENT_PLAN.md - Code Quality Metrics
- Issue Tracking: IMPROVEMENT_PLAN.md - Issue Summary
- Success Criteria: IMPROVEMENT_PLAN.md - Success Criteria

### Technical Information
- System Architecture: TECHNICAL_REFERENCE.md - Complete technical specs
- HDL Coding Standards: TECHNICAL_REFERENCE.md - Section 1
- ROIC Gate Driver: TECHNICAL_REFERENCE.md - Section 3
- Refactoring Guidelines: TECHNICAL_REFERENCE.md - Section 4

### Reference Data
- Register Maps: Xdaq_Register_Map.xlsx, Xdaq_Register_Map_24.xlsx
- Timing Specifications: ROIC_timing_chart.xlsx
- Architecture Diagram: fpga_block_diagram.png
- Design Presentation: xdaq_fpga_design.pptx

---

## Common Questions

**Where do I start?**
1. Read this README.md (5 min)
2. Review Known Issues above
3. Study IMPROVEMENT_PLAN.md for roadmap (30 min)
4. Review TECHNICAL_REFERENCE.md for architecture (45 min)

**What is the current status?**
- Phase: Development with critical issues
- CDC Violations: 8+ (require immediate fix)
- Test Coverage: 23% (target: 90%)
- Next Phase: Phase 1 - Critical Safety (Week 1)

**What needs to be done?**
- Immediate: Fix CDC violations (see IMPROVEMENT_PLAN.md)
- This Week: Standardize resets, add timing constraints
- Detailed task list: IMPROVEMENT_PLAN.md

**Where are the technical specs?**
- Architecture: TECHNICAL_REFERENCE.md
- Timing: ROIC_timing_chart.xlsx
- Registers: Xdaq_Register_Map.xlsx
- Block Diagram: fpga_block_diagram.png

**How do I find register info?**
- Primary: Xdaq_Register_Map.xlsx (current version)
- Alternative: Xdaq_Register_Map_24.xlsx (24-bit version)
- For implementation: TECHNICAL_REFERENCE.md Section 3

---

## Document Maintenance

| Document | Last Updated | Maintainer | Review Cycle |
|----------|--------------|------------|--------------|
| README.md | 2026-02-03 | FPGA Design Team | Weekly |
| IMPROVEMENT_PLAN.md | 2026-02-03 | FPGA Design Team | End of each phase |
| TECHNICAL_REFERENCE.md | 2026-02-03 | FPGA Design Team | As needed |

---

**Project**: CYAN FPGA - Xilinx Artix-7 ROIC Controller
**Document Version**: 2.0
**Last Updated**: 2026-02-03

---

## Navigation Summary

This README is your central hub for:
- Understanding the project (Overview section)
- Checking current status (Known Issues)
- Finding what to work on (Development Roadmap or IMPROVEMENT_PLAN.md)
- Getting technical details (TECHNICAL_REFERENCE.md)
- Looking up register info (Xdaq_Register_Map.xlsx)
- Reviewing timing specs (ROIC_timing_chart.xlsx)
- Seeing architecture (fpga_block_diagram.png)
