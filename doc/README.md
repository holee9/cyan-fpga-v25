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

**Status**: ✅ **Active Development** - Week 4 Complete

**Recent Achievements:**
- ✅ Week 1: All CDC violations fixed (CDC-001, CDC-002)
- ✅ Week 2: Reset standardization complete (RST-001, RST-002)
- ✅ Week 3: FSM refactoring & testbench complete (FSM-001)
- ✅ Week 3: CDC-003 resolved (IP Core has internal CDC)

**Remaining Work:**
- Week 4-8: Top-level decomposition, testing expansion

Open Issues: 1 (LOW - Documentation improvement)
Critical Issues: 0 ✅

### Completed Issues ✅

| Issue ID | Category | Status | PR | Solution |
|----------|----------|--------|-----|----------|
| CDC-001 | CDC Violation | ✅ Fixed | #1 | 3-stage synchronizer for gen_sync_start |
| CDC-002 | Missing Constraints | ✅ Fixed | #1 | Clock groups + CDC false paths |
| CDC-003 | MIPI Data CDC | ✅ Fixed | #1 | async_fifo_24b module created |
| RST-001 | Reset Inconsistency | ✅ Fixed | #1 | reset_sync modules, active-LOW standard |
| RST-002 | Multiple Async Resets | ✅ Fixed | #1 | Single synchronized reset per domain |
| FSM-001 | Non-Standard FSM | ✅ Fixed | #2 | 3-block FSM refactoring, 577→490 lines |

### Open Issues

| Issue ID | Category | Severity | Impact | Notes |
|----------|----------|----------|--------|-------|
| *None* | - | - | - | All critical and high priority issues resolved ✅ |

### Low Priority Issues

| Issue ID | Category | Severity | Impact | Notes |
|----------|----------|----------|--------|-------|
| TRI-001 | Tri-State Design | LOW | Documentation | Intentional design - add comments only |


### Quality Metrics (Progress)

| Metric | Week 0 | Week 3 | Week 4 | Target (Final) | Status |
|--------|--------|--------|--------|----------------|--------|
| CDC Violations | 8+ | 3 | 0 ✅ | 0 | ACHIEVED |
| Reset Consistency | 30% | 60% | 100% ✅ | 100% | ACHIEVED |
| FSM Standard Compliance | 0% | 100% ✅ | 100% ✅ | 100% | ACHIEVED |
| Module Decomposition | 0% | 0% | 25% | 50% | In Progress |
| Test Coverage | 23% | 23% | 23% | >70% | Planned (Week 6) |

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
| Phase 1 | Critical Safety (CDC) | Week 1 | ✅ COMPLETE |
| Phase 2 | Reset Standardization | Week 2 | ✅ COMPLETE |
| Phase 3 | FSM Refactoring | Weeks 3-4 | In Progress |
| Phase 4 | Testing & Verification | Weeks 5-6 | Planned |
| Phase 5 | Top-Level Decomposition | Week 7 | Planned |
| Phase 6 | Advanced Verification | Week 8 | Planned |

### Current Phase: Phase 4 - Top-Level Decomposition (Week 4) ✅ COMPLETE

**Completed:**
- ✅ Week 1: CDC violations fixed (CDC-001, CDC-002)
- ✅ Week 2: Reset standardization (RST-001, RST-002)
- ✅ Week 3: FSM refactoring (FSM-001)
- ✅ Week 4: CDC fixes, reset unification, module extraction

**Week 4 Deliverables:**
- ✅ clock_gen_top.sv created (82 lines)
- ✅ ti_roic_integration.sv created (154 lines)
- ✅ reg_map_integration.sv created (279 lines)
- ✅ CDC-003, CDC-004, CDC-005 resolved
- ✅ Reset polarity unified to active-LOW

**Completed:**
- [x] Week 1: Fix all CDC violations ✅
- [x] Week 2: Reset standardization ✅

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
- Phase: Week 3 (FSM Refactoring) - Active Development
- CDC Violations: 0 ✅ (Week 1 complete)
- Reset Consistency: 100% ✅ (Week 2 complete)
- Test Coverage: 23% → Target >70% (Week 6)
- Next Phase: Complete FSM refactoring, expand testing

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
**Document Version**: 2.1 (Week 2 Update)
**Last Updated**: 2025-02-03 (Week 2 Complete)

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
