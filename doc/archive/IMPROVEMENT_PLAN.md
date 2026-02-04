# CYAN FPGA Quality Improvement Plan

## Executive Summary

This document outlines a comprehensive quality improvement plan for the CYAN FPGA project. The plan addresses critical design issues, establishes coding standards, and provides a phased roadmap to transform the codebase into a production-ready, maintainable system.

**Current Status**: Development phase with known critical issues
**Target Status**: Production-ready with comprehensive verification
**Timeline**: 8 weeks across 4 phases
**Priority**: HIGH - Addressing critical stability and reliability issues

---

## Issue Summary

### Critical Issues (Require Immediate Action)

| Issue ID | Category | Severity | Location | Impact |
|----------|----------|----------|----------|--------|
| CDC-001 | CDC Violation | CRITICAL | cyan_top.sv:270-276 | Metastability, data corruption |
| CDC-002 | Missing Constraints | CRITICAL | timing.xdc | Timing violations, unstable operation |
| RST-001 | Reset Inconsistency | HIGH | Multiple modules | Unpredictable initialization |

### Low Priority Issues (Deferred to Final Review)

| Issue ID | Category | Severity | Location | Impact | Notes |
|----------|----------|----------|----------|--------|-------|
| TRI-001 | Tri-State Design | LOW | cyan_top.sv:727-728 | Documentation | Intentional design for external ROIC interface - add comments only |
| FSM-001 | Non-Standard FSM | MEDIUM | sequencer_fsm.sv:299-388 | Maintainability | Phase 2 |
| TST-001 | Low Test Coverage | MEDIUM | Global | Reduced confidence | Phase 2 |
| DOC-001 | Missing Documentation | MEDIUM | Global | Knowledge transfer | Phase 3 |

---

## Detailed Issue Analysis

### CDC-001: Unsafe Clock Domain Crossings

**Severity**: CRITICAL
**Affected Files**: cyan_top.sv, read_data_mux.sv, sequencer_fsm.sv

**Problem Description**:
Multiple signals cross clock domains without proper synchronization. The most critical issue is the gen_sync_start signal crossing from 100MHz to 20MHz domain without a verified synchronizer.

**Root Cause**:
- Direct assignment of signals across clock domains
- Missing 2-flip-flop synchronizers on async signals
- Inconsistent use of synchronizer primitives

**Recommended Fix**: Use proper 2FF synchronizer module
```systemverilog
module cdc_sync_2ff (
    input  logic dst_clk,
    input  logic async_sig,
    output logic sync_sig
);
    logic sync_sig_ff1, sync_sig_ff2;
    always_ff @(posedge dst_clk) begin
        sync_sig_ff1 <= async_sig;
        sync_sig_ff2 <= sync_sig_ff1;
    end
    assign sync_sig = sync_sig_ff2;
endmodule
```

**Timeline**: Week 1 (Phase 1)
**Owner**: FPGA Design Team
**Verification**: Simulation + Formal CDC analysis

---

### TRI-001: Tri-State Bus Design

**Severity**: LOW (Documentation Only)
**Affected Files**: cyan_top.sv:727-728

**Status**: ✅ Intentional Design - Verified as correct

**Problem Description**:
None - This is intentional design for external ROIC gate driver interface.

**Implementation**:
```systemverilog
// Gate Driver STV (Start Vertical) Left/Right Control
// Intentional tri-state design for external ROIC gate driver interface
// Only one side (L or R) drives the bus at a time based on sig_gate_lr1
assign GF_STV_R = (sig_gate_lr1 == 1'b0) ? s_mask_stv : 1'bz;  // Right side active
assign GF_STV_L = (sig_gate_lr1 == 1'b1) ? s_mask_stv : 1'bz;  // Left side active
```

**Potential Alternatives** (for future consideration):
1. Use Xilinx OBUFT primitive for better timing control
2. Add explicit drive strength and slew rate specifications
3. Document tri-state timing requirements in constraint file

**Action Items**:
1. Add inline comments explaining tri-state usage (1 hour)
2. Verify synthesis warnings are acceptable (30 min)
3. Consider OBUFT primitive refactoring in Phase 4 (4 hours, optional)

**Timeline**: Phase 4 (Optional) / Final Review
**Owner**: FPGA Design Team
**Priority**: LOW - Documentation and verification only

---

## Improvement Phases

### Phase 1: Critical Safety (Week 1)

**Objective**: Address stability and reliability issues

**Tasks**:
1. Fix all CDC violations (Days 1-3)
2. Add comprehensive timing constraints (Days 1-2)
3. Standardize reset strategy (Days 2-3)
4. Create CDC testbenches (Days 3-5)
5. Document tri-state design (Day 1) - **New**

**Deliverables**:
- All CDC paths verified and fixed
- Complete timing constraints with clock groups
- Standardized reset strategy implemented
- CDC testbench suite created
- Documented tri-state interface design

---

### Phase 2: Design Robustness (Weeks 2-3)

**Objective**: Improve code quality and maintainability

**Tasks**:
1. Refactor top-level into sub-blocks (Days 3-5)
2. Convert FSMs to 3-block style (Days 5-7)
3. Create testbenches for remaining modules (Days 7-10)
4. Add assertions and coverage metrics (Days 3-5)
5. Code review and cleanup (Days 3)

**Deliverables**:
- Top-level module <500 lines
- All FSMs using 3-block style
- Test coverage >80%
- Assertion-based verification implemented

---

### Phase 3: Quality Improvement (Weeks 4-6)

**Objective**: Production-ready documentation and infrastructure

**Tasks**:
1. Create architecture specification (Days 5)
2. Create timing specification (Days 3)
3. Write integration guide (Days 3)
4. Establish automated regression (Days 5)
5. Implement CI/CD pipeline (Days 5)

---

### Phase 4: Optimization (Weeks 7-8)

**Objective**: Performance and resource optimization

**Tasks**:
1. Timing closure improvements (Days 5)
2. Resource utilization optimization (Days 3)
3. Power analysis and optimization (Days 3)
4. Performance benchmarking (Days 3)
5. Review tri-state implementation (Optional, Day 1)

---

## Code Quality Metrics

### Target Metrics

| Metric | Current | Target (Phase 1) | Target (Phase 2) | Target (Phase 3) |
|--------|---------|------------------|------------------|------------------|
| CDC Violations | 8+ | 0 | 0 | 0 |
| Reset Consistency | 30% | 100% | 100% | 100% |
| FSM Standard Compliance | 0% | 50% | 100% | 100% |
| Test Coverage | 23% | 50% | 80% | 90% |
| Documentation Coverage | 10% | 30% | 70% | 100% |

---

## Success Criteria

### Phase 1 Success Criteria
- [ ] Zero CDC violations
- [ ] Comprehensive timing constraints
- [ ] Standardized reset strategy
- [ ] Tri-state design documented (intentional design preserved)
- [ ] CDC testbenches created

### Phase 2 Success Criteria
- [ ] All FSMs in 3-block style
- [ ] Top-level <500 lines
- [ ] Test coverage >80%
- [ ] Zero lint warnings
- [ ] Code review complete

### Phase 3 Success Criteria
- [ ] Complete documentation set
- [ ] Automated regression infrastructure
- [ ] CI/CD pipeline functional
- [ ] Formal design review complete

### Phase 4 Success Criteria
- [ ] Timing closure at 200MHz
- [ ] Resource utilization <80%
- [ ] Power consumption within budget
- [ ] Performance benchmarks met
- [ ] Final verification approved

---

**Document Version**: 1.1
**Last Updated**: 2026-02-03
**Maintained By**: FPGA Design Team
**Next Review**: End of Phase 1 (Week 1)

**Change Log**:
- v1.1 (2026-02-03): TRI-001 downgraded to LOW priority, confirmed as intentional design
- v1.0 (2026-02-03): Initial version

*This improvement plan is a living document. Update as new issues are discovered or priorities change.*
