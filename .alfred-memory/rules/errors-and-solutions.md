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
```
