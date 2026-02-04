# Alfred Operating Procedures

## 규칙: 작업 지시 시 Memory 등록 후 실행

### 1. 작업 시작 전 절차 (필수)

```
사용자 작업 지시 수신
    ↓
[1] .alfred-memory/rules/errors-and-solutions.md 확인
    ↓
[2] .alfred-memory/tasks/active.md 확인 (진행 중 작업)
    ↓
[3] 새 작업 등록: .alfred-memory/tasks/pending.md
    ↓
[4] 작업 실행
    ↓
[5] 완료/실패 기록: .alfred-memory/tasks/completed.md
```

### 2. Memory 확인 규칙

#### 2.1 작업 전 필수 확인사항

```markdown
## 작업 전 체크리스트

- [ ] .alfred-memory/rules/errors-and-solutions.md 확인
- [ ] 동일한 에러 반복 방지 규칙 확인
- [ ] 진행 중 작업 (active.md) 확인
- [ ] 충돌하는 작업 없는지 확인
```

#### 2.2 작업 등록 형식

```markdown
## [TASK-YYYY-MM-DD-001] 작업 제목

**상태:** pending | in_progress | completed | failed
**시작:** YYYY-MM-DD HH:MM
**완료:** YYYY-MM-DD HH:MM (완료 시)

### 작업 지시
(사용자의 원본 지시)

### 계획
- 단계 1: ...
- 단계 2: ...

### 실행 기록
- HH:MM - 작업 시작
- HH:MM - 단계 1 완료
- HH:MM - 에러 발생: [ERR-XXX]
- HH:MM - 해결책 적용
- HH:MM - 작업 완료

### 결과
- 성공 / 실패
- 수정된 파일: ...
- 생성된 파일: ...
```

### 3. 작업 중단 시 복구 절차

```
작업 중단 (세션 종료 등)
    ↓
다음 세션 시작 시
    ↓
[1] .alfred-memory/tasks/active.md 확인
    ↓
[2] 마지막 실행 기록 확인
    ↓
[3] 다음 단계부터 재개
```

### 4. 에러 처리 규칙

```markdown
## 에러 발생 시 처리 절차

1. 에러 분류
   - [ERR-001]~[ERR-XXX]: 이미 알려진 에러 → 해결책 즉시 적용
   - 신규 에러 → errors-and-solutions.md에 등록 후 해결

2. 해결책 없는 신규 에러
   - 에러 기록
   - 가능한 해결책 시도
   - 사용자에게 보고

3. 치명적 에러가 아닌 경우
   - 작업 계속 진행 (Hook 에러 등)
```

### 5. Tool 사용 규칙

| 상황 | 사용 Tool | 비고 |
|------|-----------|------|
| TODO 관리 | TaskCreate/Update/List | TodoWrite 없음 |
| 파일 경로 찾기 | Glob | 경로 가정 금지 |
| 파일 읽기 | Read | offset/limit 사용 |
| 파일 수정 | Edit | 실패 시 Bash+Python |
| 코드 검색 | Grep | 실패 시 Read+eyes |
| 병렬 작업 | Task (multiple) | 한 응답에 여러 개 |

### 6. FPGA/SystemVerilog 작업 특별 규칙

```markdown
## FPGA 작업 체크리스트

- [ ] Reset 극성: active-LOW (_n suffix)
- [ ] CDC 확인: cross-domain signal 검사
- [ ] FSM 스타일: 3-block 권장
- [ ] 모듈 크기: <500 lines 권장
- [ ] 포트 방향: input/output 확인
- [ ] 드라이버: undriven signal 검사
```
