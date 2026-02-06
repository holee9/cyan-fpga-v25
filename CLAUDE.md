# CYAN-FPGA Project Rules for Claude Code

## 작업 시작 전 필독 사항

### 1. Questa 라이선스 확인
```
** License Issue: Cannot checkout an uncounted license within a Windows Terminal Services guest session
```
→ 해결: Questa GUI 모드 먼저 실행 후 진행

### 2. SVA 구문 규칙
- ❌ `(cond) |-> $error("msg")`  
- ✅ `not (cond); assert property ... else $error("msg")`

### 3. Testbench 선언 순서
- logic 선언 → assign 사용 (순서 지킴)

### 4. 모듈 이름 일치
- `tb_name.sv` → `module tb_name;`

### 5. Multi-Driven Net 해결
- assign → register intermediate 사용

자세한 내용: `.claude/rules/fpga-simulation-rules.md`
