# Reset Architecture - Active-LOW Unification

**Date**: 2025-02-03
**Status**: Implemented

## Overview

All reset signals unified to active-LOW polarity.

## Reset Signal Convention

- Active-LOW signals use _n suffix (e.g., rst_n, reset_n)
- Always_ff blocks use negedge for active-LOW resets

## Internal Reset Signals

- s_seq_reset_n: from rst_n_20mhz (direct)
- deser_reset_n: from ~ti_roic_deser_reset (inverted)
- s_reset_n: from ~rst_n_200mhz (inverted)
- init_rst_n: from init module (active-LOW)

## Module Changes

### sequencer_fsm.sv
- reset_i (active-HIGH) -> reset_n_i (active-LOW)
- All always_ff use negedge reset_n_i

### init.sv
- reset input changed to active-LOW
- init_rst -> init_rst_n (active-LOW output)

### cyan_top.sv
- Added unified reset inversion logic
- All always_ff use negedge with _n signals

## Related Files

- source/hdl/cyan_top.sv
- source/hdl/sequencer_fsm.sv
- source/hdl/init.sv
- source/hdl/reg_map_refacto.sv
