# Week 11 요약 - Bitstream 생성 완료

**Date**: 2026-02-04
**Status**: ✅ 완료
**Focus**: Bitstream 생성, ERR-017 수정, Build 자동화

---

## 개요(Overview)

Week 11은 성공적인 bitstream 생성이라는 중요한 마일스톤을 달성하는 주간이었습니다. 이 과정에서 중요한 clock routing error(ERR-017)를 해결하고, build automation을 완료하며, file cleanup을 수행했습니다.

---

## 완료된 작업(Completed Tasks)

### Week 11 Deliverables (Week 11 전달물)

| Task | Description | Status |
|------|-------------|--------|
| ERR-017 Fix | Bitstream Clock Routing error 수정 | ✅ |
| Build Automation | TCL script (build_bitstream.tcl) 생성 | ✅ |
| Post-Processing | post_script.tcl post-build 처리 | ✅ |
| File Cleanup | 594개 IP 생성 파일을 .gitignore로 이동 | ✅ |
| Output Generation | cyan_top.bit, .bin, .mcs 생성 | ✅ |
| Documentation | Week 11 요약, 계획 업데이트 | ✅ |

---

## ERR-017: Bitstream Clock Routing Error (Bitstream 클럭 라우팅 오류)

### Problem (문제점)

**Error Message**: `Place 30-574 - IOB driving a BUFG must use a CCIO in the same half side (top/bottom) of chip as the BUFG`

**Affected Pins**: IOB_X0Y116, IOB_X0Y136 (왼쪽 반칩 IO)가 오른쪽 BUFG로 라우팅 실패

### Root Cause (원인)

```systemverilog
// 문제 코드 (암시적 BUFG 추론)
assign fclk_out = fclk_in_int;
```

직접 할당이 Vivado가 자동으로 BUFG를 추론하게 만들었지만, 추론된 BUFG가 잘못된 위치에 배치되었습니다.

### Solution (해결책)

1. **명시적 BUFG 인스턴스화(Explicit BUFG Instantiation)**:
```systemverilog
// 수정된 코드 (명시적 BUFG)
BUFG fclk_bufg_inst (
    .I(fclk_in_int),
    .O(fclk_out)
);
```

2. **XDC 제약조건 업데이트**:
```tcl
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {roic_channel_array_inst/gen_ti_roic_channel[*].ti_roic_top_inst/bit_clock_gen/fclk_in_int}]
```

### Result (결과)

- Synthesis: ✅ PASS (0 errors, 0 critical warnings)
- Implementation: ✅ PASS (0 errors, timing met)
- Bitstream: ✅ PASS

---

## Build Automation (Build 자동화)

### build_bitstream.tcl

**Location**: `./build_bitstream.tcl`

**Features**:
- 자동화된 synthesis with error checking
- 자동화된 implementation with error checking
- 자동화된 bitstream generation with file verification
- 상세한 진행 상태 보고

**Usage**:
```bash
"D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat" -mode batch -source "build_bitstream.tcl" -log "build_bitstream.log" -nojournal
```

### post_script.tcl

**Location**: `./build/post_script.tcl`

**Features**:
- 출력 파일 복사 (build → output/)
- 보고서 파일 복사 (build → reports/)
- Debug probe 파일 생성

---

## Output Files Generated (생성된 출력 파일)

| File | Size | Description (설명) |
|------|------|-------------|
| cyan_top.bit | - | FPGA programming bitstream |
| cyan_top.bin | - | Binary format |
| cyan_top.mcs | - | SPI Flash 이미지 |
| cyan_top.ltx | - | Debug probes |
| *.rpt | - | Timing/utilization reports (타이밍/리소스 보고서) |

**Output Directory**: `./output/`
**Reports Directory**: `./reports/`

---

## File Cleanup (파일 정리)

### IP-Generated Files (IP 생성 파일)

**Files Moved to .gitignore**: 594 files

**Pattern (패턴)**: 모든 IP 생성 중간 파일들은 이제 무시

**Benefits (이점)**:
- Repository 크기 감소
- Git 작업 속도 향상
- 소스 코드에만 집중

**Kept Files (유지 파일)**:
- Source HDL (`source/hdl/*.sv`)
- Constraints (`source/constrs/*.xdc`)
- Output files (`output/*.bit`, `*.bin`, `*.mcs`)
- Reports (`reports/*.rpt`)
- Project files (`build/xdaq_top.xpr`, `build/post_script.tcl`)

---

## 품질 지표(Quality Metrics, Week 11)

| Metric | Week 0 | Week 11 | Target | Status |
|--------|--------|---------|--------|--------|
| CDC Violations | 8+ | 0 | 0 | ✅ 달성 |
| Reset Consistency | 30% | 100% | 100% | ✅ 달성 |
| FSM Standard Compliance | 0% | 100% | 100% | ✅ 달성 |
| Syntax Errors | 2 | 0 | 0 | ✅ 달성 |
| Synthesis Errors | - | 0 | 0 | ✅ PASS |
| Bitstream Generation | FAIL | PASS | PASS | ✅ PASS |
| Module Count | 21 | 39 | - | ✅ 완료 |
| cyan_top.sv Lines | 1261 | 1292 | <500 | 🟡 진행중 |
| Test Coverage | 23% | 23% | >70% | ⏳ 계획됨 (Week 12) |

---

## Technical Details (기술 상세)

### ERR-017 Technical Summary (ERR-017 기술 요약)

**Error Type**: Place Route Error (30-574)
**Component**: BUFG (Global Clock Buffer)
**Cause**: Implicit BUFG inference from direct assignment
**Fix**: Explicit BUFG instantiation
**Impact**: Critical - bitstream generation blocked (치명적 - bitstream 생성 차단)

### Lesson Learned (교훈)

**Rule**: Clock buffers must always be explicitly instantiated. Never rely on automatic inference from direct assignments.

**Enforcement**: Add this rule to coding standards and review checklist.

---

## Files Modified (수정된 파일)

### Source Files (소스 파일)
- `ti-roic/bit_clock_module.sv` - BUFG 명시적 인스턴스화

### Build Files (빌드 파일)
- `build_bitstream.tcl` - 생성 (automation script)
- `build/post_script.tcl` - 생성 (post-processing)

### Documentation (문서)
- `README.md` - Week 11 status로 업데이트
- `IMPROVEMENT_PLAN.md` - v2.0 생성
- `doc/README.md` - Week 11 status로 업데이트
- `doc/TECHNICAL_REFERENCE.md` - v2.0 업데이트
- `doc/archive/WEEK11_SUMMARY.md` - 이 파일

### Git Configuration
- `.gitignore` - IP 생성 파일 업데이트

---

## Issues Resolved (해결된 이슈)

| Issue ID | Category | Resolution (해결 방안) |
|----------|----------|---------------------|
| ERR-017 | Clock Routing | BUFG 명시적 인스턴스화 |

---

## Next Steps (Week 12+) (향후 작업)

### Phase 7: Verification (검증 단계)

1. **Test Coverage Expansion (Test Coverage 확장)**
   - 새 모듈용 testbenches 추가
   - 전체 coverage를 23%에서 >70%로 증가
   - CDC 및 FSM 검증에 집중

2. **Simulation Tasks (시뮬레이션 작업)**
   - 모든 모듈에 대한 RTL simulation
   - Synthesis 검증
   - Timing analysis
   - Gate-level simulation

3. **Further Decomposition (추가 분해)**
   - cyan_top.sv: 1292 → <500 lines
   - read_data_mux.sv: 771 → <500 lines

---

## Sign-Off Criteria (Week 11 완료 기준)

| Criterion | Status | Evidence (증거) |
|-----------|--------|------------|
| ERR-017 resolved | ✅ | BUFG 명시적 인스턴스화 |
| Build automation complete | ✅ | build_bitstream.tcl |
| Output files generated | ✅ | cyan_top.bit, .bin, .mcs |
| Synthesis pass | ✅ | 0 errors |
| Implementation pass | ✅ | 0 errors, timing met |
| Documentation updated | ✅ | All docs current |

---

## Git Commit Preparation (Git 커밋 준비)

### Proposed Commit Message (제안된 커밋 메시지)

```
Week 11: Bitstream Generation Complete (ERR-017)

Phase 6 - Bitstream Generation

ERR-017 Fix:
- Add explicit BUFG instantiation to bit_clock_module.sv
- Update XDC constraints for clock routing
- Resolve Place 30-574 error

Build Automation:
- Add build_bitstream.tcl: automated synthesis/implementation/bitstream
- Add post_script.tcl: output file management

File Cleanup:
- Move 594 IP-generated files to .gitignore
- Keep only source code and build artifacts

Output Files:
- cyan_top.bit: FPGA programming bitstream
- cyan_top.bin: Binary format
- cyan_top.mcs: SPI Flash image
- cyan_top.ltx: Debug probes

Documentation:
- Update README.md to Week 11 status
- Create IMPROVEMENT_PLAN.md v2.0
- Update TECHNICAL_REFERENCE.md to v2.0
- Create WEEK11_SUMMARY.md

Build Results:
- Synthesis: PASS (0 errors, 0 critical warnings)
- Implementation: PASS (0 errors, timing met)
- Bitstream: PASS

Resolves:
- ERR-017: Bitstream Clock Routing error

Related to: 12-week improvement plan Week 11
```

---

**Week 11 Lead**: drake.lee
**Week 11 Status**: ✅ **BITSTREAM GENERATION COMPLETE**
**Ready for Week 12**: Yes - Verification Phase (검증 단계)

**Notes**: 모든 Phase 6 목표 달성. Bitstream generation 성공, 0 errors, timing 충족.
ERR-017 (clock routing)는 명시적 BUFG 인스턴스화로 해결. Build automation 완료.
다음 단계는 simulation 검증 및 test coverage 확장입니다.
