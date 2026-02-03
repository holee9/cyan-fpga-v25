# Week 3: FSM Refactoring Plan

## Date: 2025-02-03
## Branch: week3-fsm-refactor
## Issue: FSM-001

---

## Current FSM Structure (sequencer_fsm.sv)

### Problems
1. **Non-standard FSM**: Single always_ff block mixing state/next/output logic
2. **Complexity**: 577 lines (target: <400 lines)
3. **Maintainability**: Hard to understand and modify
4. **Code Review**: Difficult to verify changes

---

## 3-Block FSM Style (Xilinx Recommended)

### Structure
```
┌─────────────────────────────────────────┐
│ Block 1: State Register (Sequential)        │
│ - current_state_reg <= next_state;          │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ Block 2: Next State Logic (Combinational)  │
│ - next_state = current_state;              │
│ - state transition conditions              │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│ Block 3: Output Logic (Combinational)     │
│ - outputs = decode(current_state);        │
│ - registered or direct                    │
└─────────────────────────────────────────┘
```

---

## Refactoring Strategy

### Phase 1: Separate State Register
- Keep: always_ff @(posedge clk or posedge fsm_rst)
- Extract only state register logic

### Phase 2: Extract Next State Logic
- Create combinational logic for state transitions
- Move from always_ff to combinational always_comb

### Phase 3: Extract Output Logic  
- Create combinational logic for all outputs
- Separate decode logic

---

## Expected Results
- Lines: 577 → <400
- Clarity: 3 distinct blocks with clear purposes
- Maintainability: Easier to understand and modify
- Verification: Easier to add assertions and coverage

