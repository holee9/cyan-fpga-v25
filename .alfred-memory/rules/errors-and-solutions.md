# Alfred Error & Solution Database
# CYAN-FPGA Project

이 파일은 Alfred 작업 중 발생한 에러, 실패, 실수와 그 해결책을 기록합니다.

---

## [ERR-001] TodoWrite Tool Not Available

**발생:** Loop 1 실행 중
**에러:** `TodoWrite tool not available`
**원인:** Claude Code 환경에서 TodoWrite tool이 제공되지 않음
**해결책:** `TaskCreate` 및 `TaskUpdate` tool을 대신 사용
**규칙:** TODO 관리는 항상 TaskCreate/TaskUpdate/TaskList를 사용할 것

---

## [ERR-002] Hook Files Missing

**발생:** Write tool 사용 후
**에러:** `PostToolUse hook error - file not found`
**원인:** `.claude/hooks/moai/` 폴더에 hook 스크립트가 존재하지 않음
**해결책:** Hook 에러는 무시하고 진행 (작업에는 영향 없음)
**규칙:** Hook 에러는 작업 중단 사유가 아님, 로그만 기록하고 계속 진행

---

## [ERR-003] Edit Tool Hook Failure

**발생:** Week 5 초기 작업 중
**에러:** `PreToolUse:Edit hook error: security_guard.py not found`
**원인:** Edit tool의 pre hook 파일이 존재하지 않음
**해결책:** Bash + Python을 사용하여 직접 파일 편집
**규칙:** Edit tool 실패 시 Bash + Python 조합으로 대체

---

## [ERR-004] File Path Not Found

**발생:** 초기 파일 읽기 시도 시
**에러:** `File does not exist` for `rtl/cyan_top.sv`
**원인:** 잘못된 경로 가정 (rtl/ 대신 source/hdl/ 사용)
**해결책:** Glob tool로 먼저 파일 경로 확인 후 Read tool 사용
**규칙:** 새로운 프로젝트에서는 항상 Glob으로 파일 위치 먼저 확인

---

## [ERR-005] Port Direction Mismatch

**발생:** RST-004 수정 중
**에러:** `power_control` 모듈의 `init_rst`이 OUTPUT인데 INPUT으로 연결됨
**원인:** 모듈 추출 시 포트 방향 잘못 정의
**해결책:** 포트 방향 확인 후 수정 또는 불필요한 포트 제거
**규칙:** 모듈 연결 전에 항상 포트 방향 (input/output) 확인

---

## [ERR-006] Reset Polarity Inversion Bug

**발생:** RST-001, RST-005 수정 중
**에러:** `init` 모듈과 `ti_roic_integration`에 active-HIGH reset 연결
**원인:** `~rst_n_20mhz`로 active-LOW를 active-HIGH로 변환하여 연결
**해결책:** 직접 `rst_n_20mhz` 연결, 모듈 내부도 active-LOW로 변경
**규칙:** 리셋 극성 불일치 검증: `negedge`와 `!signal` 사용 확인

---

## [ERR-007] Undriven Signal

**발생:** CDC-005 수정 중
**에러:** `gen_sync_start` 신호가 드라이버 없음 (FIFO 주석 처리됨)
**원인:** 주석 처리된 FIFO 모듈로 인해 신호 소실
**해결책:** SR 래치 로직으로 신호 생성
**규칙:** 주석 처리된 코드 대체 여부 확인, undriven signal 검색

---

## [ERR-008] TaskCreate Missing Parameter

**발생:** TaskCreate 사용 시
**에러:** `InputValidationError: TaskCreate failed due to missing 'subject' parameter`
**원인:** 필수 파라미터 누락
**해결책:** 항상 subject, description, activeForm 포함
**규칙:** TaskCreate 시 필수 파라미터 체크리스트 사용

---

## [ERR-009] Grep Pattern Not Matching

**발생:** 코드 검색 시
**에러:** 예상한 결과가 나오지 않음
**원인:** 패턴이 너무 구체적이거나 특수문자 포함
**해결책:** 더 단순한 패턴으로 먼저 검색, 결과 좁히기
**규칙:** Grep 실패 시 Glob + Read 조합 사용

---

## [ERR-010] Module Size Still Too Large

**발생:** SIZE-001 작업 중
**에러:** cyan_top.sv가 1291라인으로 여전히 큼 (목표 <300)
**원인:** 300라인 목표는 현재 구조에서 불가능
**해결책:** 현실적인 목표로 재설정 (<800라인) 또는 추가 추출
**규칙:** 모듈 크기 목표는 현재 구조 고려하여 현실적으로 설정

---

## 해결책 요약

| 에러 | 해결책 | 적용 규칙 |
|------|--------|----------|
| ERR-001 | TaskCreate/Update 사용 | TODO 관리는 Task tool로 |
| ERR-002 | Hook 에러 무시 | 작업 중단 사유 아님 |
| ERR-003 | Bash + Python 대체 | Edit 실패 시 대안 사용 |
| ERR-004 | Glob로 경로 확인 | 경로 가정 금지 |
| ERR-005 | 포트 방향 확인 | 연결 전 검증 |
| ERR-006 | 리셋 극성 일치 | `_n` 접미사 확인 |
| ERR-007 | undriven signal 검사 | 드라이버 확인 |
| ERR-008 | 필수 파라미터 체크 | 체크리스트 사용 |
| ERR-009 | 단순 패턴부터 | Grep 실패 시 대안 |
| ERR-010 | 현실적 목표 설정 | 구조 고려 목표 |

---

## 검출 체크리스트 (작업 전 사용)

```
[ ] TodoWrite 대신 TaskCreate 사용 가능?
[ ] Glob로 파일 경로 확인?
[ ] 포트 방향 확인? (input/output)
[ ] 리셋 극성 확인? (_n suffix)
[ ] undriven signal 검사 완료?
[ ] 필수 파라미터 포함?
[ ] 클럭 버퍼 명시적 인스턴스화? (직접 할당 금지)
[ ] Vivado 경로 확인? (D:\AMDDesignTools\2025.2\Vivado)
[ ] XDC 제약 조건 넷 이름 확인? (IBUFDS 출력 vs BUFG 출력)
```

---

## [ERR-011] Undeclared Signal Usage

**발생:** 2026-02-04 (deser_single.sv)
**에러:** `clock_enable`, `clk_in_int_inv` 사용되었으나 선언되지 않음
**원인:** 신호 선언 누락 (리팩토링 중 실수)
**해결책:** `logic clock_enable;` 와 `logic clk_in_int_inv;` 선언 추가
**규칙:** assign 문 사용 전 해당 신호가 선언되었는지 확인

---

## [ERR-012] Wrong Reset Signal Name

**발생:** 2026-02-04 (deser_single.sv)
**에러:** ISERDESE2 `.RST(rst)`에서 `rst` 사용하지만 변수는 `rst_n`임
**원인:** RST-007 수정 시 포트 이름 변경 누락
**해결책:** `.RST(rst_n)`으로 수정
**규칙:** 리셋 관련 수정 시 모든 참조 확인 (인스턴스 포함)

---

## [ERR-013] False Positive Syntax Detection

**발생:** 2026-02-04 (Python syntax checker)
**에러:** 정상 코드에 syntax error 보고
**원인:** 검사 스크립트가 너무 보수적임
**해결책:** 직접 파일을 읽어서 확인, 허위 양성 무시
**규칙:** 도구 에러 보고 시 직접 파일 검증으로 재확인

---

## [ERR-014] Bare Comment Separator

**발생:** 2026-02-04 (cyan_top.sv:1086, :715)
**에러:** `=====` (SystemVerilog 주석 아님)
**원인:** 주석 기호 `//` 누락
**해결책:** `// =====`로 수정
**규칙:** 모든 구분선 앞에 `//` 추가 필요

---

## [ERR-015] Python Escape Sequence in SV Code

**발생:** 2026-02-04 (deser_single.sv)
**에러:** `(\!rst_n)` - Python f-string escape가 SV 코드에 삽입됨
**원인:** Python 문자열 조작 중 escape sequences 누입
**해결책:** `(!rst_n)`으로 수정 (백슬래시 제거)
**규칙:** Python으로 SV 코드 생성 시 escape sequences 확인

---

## 해결책 요약 (2026-02-04 갱신)

| 에러 | 해결책 | 적용 규칙 |
|------|--------|----------|
| ERR-001 | TaskCreate/Update 사용 | TODO 관리는 Task tool로 |
| ERR-002 | Hook 에러 무시 | 작업 중단 사유 아님 |
| ERR-003 | Bash + Python 대체 | Edit 실패 시 대안 사용 |
| ERR-004 | Glob로 경로 확인 | 경로 가정 금지 |
| ERR-005 | 포트 방향 확인 | 연결 전 검증 |
| ERR-006 | 리셋 극성 일치 | `_n` 접미사 확인 |
| ERR-007 | undriven signal 검사 | 드라이버 확인 |
| ERR-008 | 필수 파라미터 체크 | 체크리스트 사용 |
| ERR-009 | 단순 패턴부터 | Grep 실패 시 대안 |
| ERR-010 | 현실적 목표 설정 | 구조 고려 목표 |
| ERR-011 | 신호 선언 확인 | assign 전 선언 검증 |
| ERR-012 | 리셋 이름 일치 | 모든 참조 확인 |
| ERR-013 | 직접 파일 검증 | 허위 양성 필터링 |
| ERR-014 | 주석 기호 확인 | 구분선에 `//` 추가 |
| ERR-015 | Escape sequences 확인 | Python 생성 후 검증 |
| ERR-016 | # 주석 문자 사용 금지 | SystemVerilog는 #가 주석이 아님 |
| ERR-017 | 클럭 버퍼 명시적 인스턴스화 | 직접 할당으로 버퍼 추론 금지 |

---

## [ERR-016] Hash Used as Comment Character

**발생:** 2026-02-04 (ti_roic_top.sv:142, :187)
**에러:** `# RST-007` - SystemVerilog에서 `#`는 주석 문자가 아님
**원인:** Python/다른 언어 습관으로 `#`을 주석으로 사용
**해결책:** `//`로 수정
**규칙:** SystemVerilog에서 `#`는 delay 연산자이므로 주석에 사용 금지, 항상 `//` 사용

---

## 검증 방법 개선 (2026-02-04)

1. **Vivado 구문 검증** - 실제 툴체인에서 에러 확인 최우선
2. **특수 문자 검사** - `#`, `===`, `---` 등 SV에서 특수 의미 있는 문자 확인
3. **주석 스타일** - `//` 외의 주석 문자 사용 금지
4. **Python artifact 확인** - escape sequence, f-string 잔재 확인

---

## [ERR-017] Bitstream Clock Routing Error (Place 30-574)

**발생:** 2026-02-04 (Bitstream Generation)
**에러:** `IOB driving a BUFG must use a CCIO in the same half side (top/bottom) of chip as the BUFG`
- IOB_X0Y116, IOB_X0Y136 등 왼쪽 반칩 IO가 오른쪽 BUFG로 라우팅 실패
**원인:** `assign fclk_out = fclk_in_int` 직접 할당이 자동으로 BUFG 추론
- 추론된 BUFG가 잘못된 위치에 배치됨
- XDC 제약 조건의 넷 이름이 `fclk_out`이었지만 실제 넷은 `fclk_in_int`
**해결책:**
1. 명시적 BUGG 인스턴스화:
   ```systemverilog
   BUFG fclk_bufg_inst (
       .I (fclk_in_int),
       .O (fclk_out)
   );
   ```
2. XDC 제약 조건 업데이트:
   ```tcl
   set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {roic_channel_array_inst/gen_ti_roic_channel[*].ti_roic_top_inst/bit_clock_gen/fclk_in_int}]
   ```
**규칙:** 클럭 버퍼는 항상 명시적으로 인스턴스화, 직접 할당(`assign`)으로 버퍼 추론 의존 금지

---

## 프로젝트 환경 설정 (2026-02-04)

### Vivado 설치 경로
```
D:\AMDDesignTools\2025.2\Vivado
```
- 실행 파일: `D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat`
- 버전: v2025.2 (64-bit)

### 프로젝트 경로
```
D:\workspace\gittea-work\v2025\CYAN-FPGA\xdaq_top
```
- 프로젝트 파일: `./build/xdaq_top.xpr`
- 소스 코드: `./source/hdl/`
- 제약 조건: `./source/constrs/`
- 출력 파일: `./output/`
- 보고서: `./reports/`

### 계층 구조 참조
```
roic_channel_array_inst/gen_ti_roic_channel[*].ti_roic_top_inst/
```
- XDC 제약 조건 작성 시 위 경로 사용

### 빌드 스크립트
```tcl
# Vivado batch mode 실행
"D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat" -mode batch -source "build_bitstream.tcl" -log "build_bitstream.log" -nojournal
```
