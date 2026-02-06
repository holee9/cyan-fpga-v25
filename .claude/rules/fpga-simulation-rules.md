# CYAN-FPGA 시뮬레이션 규칙 (Error Prevention)

## 작업 시작 전 체크리스트

### 1. 라이선스 확인
- [ ] Questa vsim 실행 가능 여부 확인
- [ ] **주의:** Windows Terminal Services(Git Bash, RDP) 세션에서는 uncounted 라이선스 사용 제한
- [ ] 라이선스 오류 발생 시:
  ```
  ** License Issue: Cannot checkout an uncounted license within a Windows Terminal Services guest session
  ```
  해결: GUI 모드 실행 또는 로컬 Windows 세션에서 실행

### 2. SVA (SystemVerilog Assertion) 구문 규칙

**❌ 잘못된 사용:**
```systemverilog
property no_data_loss;
    @(posedge clk) disable iff (!rst)
        (condition) |-> $error("message");  // X
endproperty
```

**✅ 올바른 사용:**
```systemverilog
property no_data_loss;
    @(posedge clk) disable iff (!rst)
        not (condition);
endproperty
assert property (no_data_loss)
    else $error("message");  // $error는 else 절에서 사용
```

### 3. Testbench 선언 순서 규칙

**❌ 잘못된 순서:**
```systemverilog
assign sda = (sda_dir) ? sda_out : 1'bz;  // 선언 전 사용
logic sda_dir;                             // X
logic sda_out;                             // X
```

**✅ 올바른 순서:**
```systemverilog
logic sda_dir;     // 먼저 선언
logic sda_out;
assign sda = (sda_dir) ? sda_out : 1'bz;  // 그 다음 사용
```

### 4. 모듈 이름 일치 규칙

- testbench 파일 이름과 모듈 이름이 일치해야 함
- 예: `tb_reg_map.sv` → `module tb_reg_map;`
- 불일치 시 컴파일은 성공하지만 시뮬레이션에서 "Design loading error" 발생

### 5. Critical Warning 해결 규칙

**Multi-Driven Net (Synth 8-6859/8-6858)**
- 원인: 한 신호가 여러 곳에서 구동됨
- 해결: assign 문을 registered output으로 변경

**Hold Time Violation (Timing 38-282)**
- 소위 violation (-14ps 정도)은 `set_false_path`로 해결 가능
- Timing.xdc에 false path constraint 추가

## 자주 발생하는 에러 메시지

| 에러 | 원인 | 해결 |
|------|------|------|
| `vopt-2130: Expected a system function, not system task '$error'` | SVA property consequent에 $error 사용 | `else $error(...)` 패턴 사용 |
| `vlog-2388: already declared in this scope` | 변수 중복 선언 | 선언 순서 확인 및 중복 제거 |
| `Error loading design` | 모듈 이름 불일치 | 파일명과 모듈명 일치시키기 |
| `Cannot checkout uncounted license in Terminal Services` | RDP/Git Bash 세션 | GUI 모드 또는 로컬 세션 사용 |

---

## Git 작업 에러 및 해결 방법 (최신)

### Error 1: 브랜치 전환 실패
```
error: Your local changes to the following files would be overwritten by checkout
```
- **원인:** 커밋되지 않은 변경 사항이 있는 상태에서 브랜치 전환 시도
- **해결:**
  ```bash
  git stash push -m "메시지"  # 변경 사항 저장
  git checkout target-branch
  # 작업 후 복구:
  git checkout original-branch
  git stash pop
  ```

### Error 2: .gitignore된 파일 추가 실패
```
fatal: pathspec '.claude' did not match any files
hint: Use -f if you really want to add it
```
- **원인:** .gitignore에 해당 경로가 포함되어 있음
- **해결:**
  ```bash
  git add -f file_path  # 강제 추가
  # 또는 .gitignore에서 해당 경로 제거
  ```

### Error 3: Git 작업 순서 주의사항
1. **브랜치 전환 전:** 항상 `git status`로 확인
2. **커밋되지 않은 변경:** stash 또는 commit 후 전환
3. **merge 충돌:** pull → merge → push 순서 준수

### Error 4: Git merge 전략
- main으로 머지할 때 `--no-ff` 사용하여 merge 커밋 생성
- 머지 메시지에 작업 내용 요약 포함
