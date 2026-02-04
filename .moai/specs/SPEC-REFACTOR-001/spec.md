# SPEC-REFACTOR-001: CYAN-FPGA 리팩토링 사양서

## 태그 블록 (TAG BLOCK)

\`\`\`
TAG: SPEC-REFACTOR-001
TITLE: CYAN-FPGA 상태 기계 리팩토링 및 모듈 분리
VERSION: 1.0
STATUS: DRAFT
PRIORITY: HIGH
DOMAIN: REFACTOR
DATE: 2026-02-03
AUTHOR: drake.lee
RELATED: FSM-001, CDC-001, CDC-002, CDC-003, RST-001, RST-002, TOP-001
\`\`\`

---

## 1. 환경 (Environment)

### 1.1 타겟 하드웨어

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| FPGA | Xilinx Artix-7 XC7A35TFGG484-1 | 타겟 디바이스 |
| 클럭 도메인 | 200MHz, 100MHz, 20MHz, 5MHz, 1MHz | 멀티-클럭 시스템 |
| 용도 | ROIC 컨트롤러 및 MIPI CSI-2 TX | Readout Integrated Circuit 제어 |

### 1.2 현재 상태 (Baseline)

| 메트릭 | 현재 값 | 목표 값 | 상태 |
|--------|---------|---------|------|
| cyan_top.sv 라인 수 | 1,261 | <300 | 진행 중 |
| CDC 위반 | 0 | 0 | 달성 |
| 리셋 일관성 | 100% (주요 모듈) | 100% | 진행 중 |
| FSM 3블록 스타일 | 50% | 100% | 진행 중 |
| 테스트 커버리지 | 23% | >70% | 계획됨 |
| 문서화 커버리지 | 30% | 100% | 진행 중 |

### 1.3 완료된 작업 (Weeks 1-5)

| 작업 | 상태 | 설명 |
|------|------|------|
| CDC-001 | 완료 | gen_sync_start 동기화 |
| CDC-002 | 완료 | 타이밍 제약 조건 추가 |
| CDC-003 | 완료 | async_fifo_24b 통합 |
| RST-001 | 완료 | 리셋 표준화 (active-LOW) |
| RST-002 | 완료 | 단일 동기화 리셋 |
| FSM-001 | 완료 | 시퀀서 FSM 3블록 리팩토링 |
| SYN-001 | 완료 | 중복 세미콜론 제거 |
| SYN-002 | 완료 | 자기 할당 제거 |

### 1.4 발견된 이슈 (25개)

| 우선순위 | 개수 | 카테고리 |
|----------|------|----------|
| P1 (Major) | 13 | 리셋 일관성, FSM 스타일, CDC 간극 |
| P2 (Minor) | 12 | 중복 코드, 주석, 사소한 문법 |

---

## 2. 가정 (Assumptions)

### 2.1 기술적 가정

- **A1**: Xilinx Vivado 2023.2 이상을 사용하여 합성 및 구현 가능
- **A2**: 기존 테스트벤치가 기능 회귀 검증에 충분함
- **A3**: 타이밍 클로저는 200MHz에서 달성 가능함
- **A4**: CDC 해결 방안이 메타스태빌리티를 방지함

### 2.2 프로젝트 가정

- **A5**: 리팩토링 중 기능 변화는 허용되지 않음
- **A6**: 모든 변경 사항은 테스트벤치로 검증되어야 함
- **A7**: 문서화는 코드와 동시에 업데이트됨

### 2.3 리스크 가정

- **R1**: 모듈 분리 시 CDC 경로 재발 가능성 -> 완화: CDC 검증 자동화
- **R2**: 리셋 일관성 누락 가능성 -> 완화: 리셋 매트릭스 문서화
- **R3**: 기능 회귀 발생 가능성 -> 완화: 회귀 테스트 스위트

---

## 3. 요구사항 (Requirements)

### 3.1 보편적 요구사항 (Ubiquitous Requirements)

#### UR-001: 리셋 정책 일관성
시스템은 **항상** 모든 플립플롭에 대해 active-LOW 리셋 신호를 **사용해야 한다**.

**RATIONALE**: 일관된 리셋 정책은 초기화 예측 가능성을 보장하고 리셋 경로를 단순화합니다.

#### UR-002: CDC 안전성
시스템은 **항상** 모든 클럭 도메인 경계에서 CDC 동기화를 **수행해야 한다**.

**RATIONALE**: 메타스태빌리티는 데이터 손상과 시스템 오동작을 유발합니다.

#### UR-003: FSM 3블록 스타일
모든 상태 기계는 **항상** 3블록 스타일(상태 레지스터, 다음 상태 로직, 출력 로직)로 **작성되어야 한다**.

**RATIONALE**: 3블록 스타일은 합성 결과를 예측 가능하게 하고 타이밍 최적화를 지원합니다.

#### UR-004: 모듈 단일 책임
각 모듈은 **항상** 단일 명확한 기능만을 **수행해야 한다**.

**RATIONALE**: 단일 책임 원칙은 코드 유지보수성과 재사용성을 향상시킵니다.

#### UR-005: 테스트 커버리지
모든 새로운 모듈은 **항상** 70% 이상의 테스트 커버리지를 **가져야 한다**.

**RATIONALE**: 충분한 테스트 커버리지는 기능 정확성을 보장합니다.

### 3.2 이벤트 기반 요구사항 (Event-Driven Requirements)

#### ED-001: 클럭 도메인 경계에서의 신호 전달
**WHEN** 신호가 클럭 도메인을 경계할 때 **THEN** 시스템은 **반드시** 2단계 이상의 플립플롭 동기화를 **수행해야 한다**.

**예외**: FIFO를 사용하는 CDC 경로는 FIFO 내부 동기화를 사용합니다.

#### ED-002: 리셋 신호의 클럭 도메인 진입
**WHEN** 리셋 신호가 다른 클럭 도메인으로 진입할 때 **THEN** 시스템은 **반드시** 리셋 브리지(동기화/해제 스탬프)를 **사용해야 한다**.

#### ED-003: 상태 기계 상태 변경
**WHEN** FSM이 상태를 변경할 때 **THEN** 시스템은 **반드시** 모든 상태 비트를 동시에 **업데이트해야 한다**.

#### ED-004: 모듈 분리 시 인터페이스 정의
**WHEN** 새로운 모듈이 분리될 때 **THEN** 시스템은 **반드시** 명확한 인터페이스와 타이밍을 **정의해야 한다**.

### 3.3 상태 기반 요구사항 (State-Driven Requirements)

#### SD-001: 리셋 중 신호 상태
**IF** 리셋이 활성화된 상태이면 **THEN** 모든 출력 신호는 **반드시** 알려진 안전한 값으로 **설정되어야 한다**.

#### SD-002: 클럭 락 탐지
**IF** PLL/MMCM이 락되지 않은 상태이면 **THEN** 시스템은 **반드시** 리셋을 **유지해야 한다**.

#### SD-003: 전원 시퀀스
**IF** 전원 초기화 단계가 진행 중이면 **THEN** 시스템은 **반드시** 정의된 순서대로 전원을 **활성화해야 한다**.

#### SD-004: 백바이어스 모드
**IF** 백바이어스 인덱스가 활성화된 상태이면 **THEN** 게이트 신호는 **반드시** 백바이어스 레벨에 맞게 **제어되어야 한다**.

### 3.4 바람직하지 않은 동작 요구사항 (Unwanted Behavior Requirements)

#### UB-001: 직접 클럭 도메인 경계 금지
시스템은 **절대로** 동기화 없이 신호가 클럭 도메인을 직접 경계하도록 **허용하지 않아야 한다**.

#### UB-002: 혼합 리셋 극성 금지
시스템은 **절대로** 동일한 클럭 도메인 내에서 active-HIGH와 active-LOW 리셋을 **혼합하지 않아야 한다**.

#### UB-003: 2블록 FSM 금지
시스템은 **절대로** 출력 로직이 상태 레지스터와 결합된 2블록 FSM을 **사용하지 않아야 한다**.

#### UB-004: 게이트된 클럭 금지
시스템은 **절대로** 로직에 의해 게이트된 클럭을 **생성하지 않아야 한다**. (클럭 이너블은 허용)

### 3.5 선택적 요구사항 (Optional Requirements)

#### OP-001: 파라미터화된 모듈
**가능하면** 모듈은 파라미터를 통해 다양한 구성을 **지원해야 한다**.

#### OP-002: 자동화된 검증
**가능하면** 모든 CDC 경로는 자동화된 CDC 검증 도구로 **검증되어야 한다**.

#### OP-003: 포맷된 코드 스타일
**가능하면** 모든 코드는 일관된 포맷팅 도구로 **포맷되어야 한다**.

---

## 4. 상세 사양 (Specifications)

### 4.1 모듈 분리 계획 (Module Extraction Plan)

#### TOP-001: cyan_top.sv <300 라인 목표

**현재 상태**: 1,261 라인
**목표 상태**: <300 라인
**제거할 라인**: 약 960 라인

| 추출 모듈 | 예상 라인 | 설명 | 우선순위 |
|-----------|-----------|------|----------|
| debug_integration.sv | ~150 | LED 인디케이터, 디버그 신호 | Week 6 |
| sync_processing.sv | ~200 | 동기화 처리, 카운터 | Week 6 |
| gate_driver_output.sv | ~120 | GF_* 출력 신호 래핑 | Week 7 |
| roic_channel_array.sv | ~250 | TI ROIC 12채널 인스턴스 | Week 7 |
| control_signal_mux.sv | ~100 | 제어 신호 멀티플렉싱 | Week 8 |
| power_control.sv | ~80 | 전원 제어, 초기화 | Week 8 |

### 4.2 FSM 리팩토링 사양

#### FSM-002: 로직 블록 리팩토링

| 모듈 | 현재 스타일 | 목표 스타일 | 상태 수 |
|------|-------------|-------------|--------|
| sequencer_fsm.sv | 3블록 | 유지 | 8 |
| ctrl_fsm_sg.sv | 분석 필요 | 3블록 | TBD |
| 새로운 FSM | N/A | 3블록 | TBD |

### 4.3 CDC 처리 사양

#### CDC-004: CDC 경로 매트릭스

| 경로 | 소스 도메인 | 목적지 도메인 | 동기화 방법 | 상태 |
|------|-------------|---------------|-------------|------|
| gen_sync_start | 100MHz | 20MHz | cdc_sync_3ff | 완료 |
| FSM 인덱스들 | 20MHz | 각 모듈 | cdc_sync_3ff | 진행 중 |
| s_axis_tdata_* | eim_clk | 100MHz | async_fifo_24b | 완료 |
| config_done | 20MHz | 각 모듈 | TBD | 계획됨 |

### 4.4 리셋 아키텍처 사양

#### RST-004: 리셋 트리 구조

리셋 규칙:
1. 모든 리셋은 active-LOW (이름: *_n*)
2. 각 클럭 도메인은 자체 동기화된 리셋을 가짐
3. 리셋 브리지는 필요시 CDC 경계에 사용

### 4.5 코드 품질 사양

#### QUAL-001: 코딩 표준

| 규칙 | 설명 | 우선순위 |
|------|------|----------|
| CS-001 | 신호명은 snake_case 사용 | SHALL |
| CS-002 | 모듈명은 lowercase_with_underscores | SHALL |
| CS-003 | 파라미터는 UPPER_CASE | SHALL |
| CS-004 | 매직 넘버는 금지, localparam 사용 | SHALL |
| CS-005 | 파일당 최대 500 라인 | SHOULD |
| CS-006 | 함수/태스크는 50 라인 이하 | SHOULD |

---

## 5. 추적성 (Traceability)

### 5.1 요구사항-테스트 매트릭스

| 요구사항 ID | 테스트 ID | 테스트 이름 |
|-------------|-----------|-------------|
| UR-001 | TST-001 | reset_consistency_tb |
| UR-002 | TST-002 | cdc_synchronizer_tb |
| UR-003 | TST-003 | fsm_3block_style_tb |
| UR-004 | TST-004 | module_single_resp_tb |
| UR-005 | TST-005 | coverage_report |
| ED-001 | TST-006 | cdc_path_verification |
| SD-001 | TST-007 | reset_state_verification |
| UB-001 | TST-008 | lint_cdc_check |

### 5.2 이슈-요구사항 매핑

| 이슈 ID | 관련 요구사항 | 해결 방법 |
|---------|---------------|-----------|
| CDC-001 | UR-002, ED-001 | cdc_sync_3ff 사용 |
| RST-001 | UR-001, SD-001 | active-LOW 통일 |
| FSM-001 | UR-003, ED-003 | 3블록 스타일 변환 |
| TOP-001 | UR-004 | 모듈 분리 |
| SYN-001 | CS-001 | 문법 수정 |

### 5.3 태그 추적

SPEC: SPEC-REFACTOR-001
- FSM: FSM-001, FSM-002
- CDC: CDC-001, CDC-002, CDC-003, CDC-004
- RST: RST-001, RST-002, RST-003, RST-004
- TOP: TOP-001
- QUAL: QUAL-001

---

## 6. 용어 정의 (Glossary)

| 용어 | 정의 |
|------|------|
| 3블록 FSM | 상태 레지스터, 다음 상태 로직, 출력 로직이 분리된 상태 기계 |
| CDC | Clock Domain Crossing, 클럭 도메인 경계 |
| Active-LOW | 논리 0일 때 활성화되는 신호 |
| MTBF | Mean Time Between Failures, 평균 고장 시간 |
| ROIC | Readout Integrated Circuit, 판독 집적 회로 |
| CSI-2 | Camera Serial Interface 2, 카메라 직렬 인터페이스 |

---

## 7. 참조 (References)

1. Xilinx UG949 - UltraFast Design Methodology Guide
2. SystemVerilog LRM IEEE 1800-2023
3. EARS (Easy Approach to Requirements Syntax) Specification
4. CYAN-FPGA Technical Reference (doc/TECHNICAL_REFERENCE.md)
5. CDC-003 Fix Summary (CDC-003_FIX_SUMMARY.md)

---

**문서 버전**: 1.0
**마지막 업데이트**: 2026-02-03
**다음 리뷰**: Week 6 시작 전
