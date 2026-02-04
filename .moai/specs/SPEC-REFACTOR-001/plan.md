# SPEC-REFACTOR-001: 구현 계획 (Implementation Plan)

## 태그 블록 (TAG BLOCK)

```
TAG: SPEC-REFACTOR-001
TYPE: PLAN
VERSION: 1.0
DATE: 2026-02-03
RELATED-SPEC: spec.md
```

---

## 1. 실행 단계별 마일스톤 (Phased Milestones)

### Week 6: 디버그 및 동기화 모듈 추출 (Phase 1)

| 마일스톤 | 우선순위 | 작업 | 산출물 |
|----------|----------|------|--------|
| M6-1 | Primary | debug_integration.sv 모듈 추출 | ~150 라인 |
| M6-2 | Primary | sync_processing.sv 모듈 추출 | ~200 라인 |
| M6-3 | Secondary | 테스트벤치 작성 | debug_integration_tb.sv |
| M6-4 | Secondary | 테스트벤치 작성 | sync_processing_tb.sv |

**목표 라인 수 감소**: 1,261 -> ~900 라인
**새로운 모듈**:
- debug_integration.sv: LED 인디케이터 로직, 디버그 신호 멀티플렉싱
- sync_processing.sv: gen_sync_start 처리, 카운터 동기화

### Week 7: 게이트 드라이버 및 ROIC 채널 배열 추출 (Phase 2)

| 마일스톤 | 우선순위 | 작업 | 산출물 |
|----------|----------|------|--------|
| M7-1 | Primary | gate_driver_output.sv 모듈 추출 | ~120 라인 |
| M7-2 | Primary | roic_channel_array.sv 모듈 추출 | ~250 라인 |
| M7-3 | Secondary | CDC 경로 검증 | CDC 검증 리포트 |
| M7-4 | Secondary | 테스트벤치 작성 | gate_driver_output_tb.sv |

**목표 라인 수 감소**: ~900 -> ~550 라인
**새로운 모듈**:
- gate_driver_output.sv: GF_* 출력 신호, 트라이스테이트 로직
- roic_channel_array.sv: TI ROIC 12채널 generate 블록

### Week 8: 제어 신호 및 전원 제어 추출 (Phase 3)

| 마일스톤 | 우선순위 | 작업 | 산출물 |
|----------|----------|------|--------|
| M8-1 | Primary | control_signal_mux.sv 모듈 추출 | ~100 라인 |
| M8-2 | Primary | power_control.sv 모듈 추출 | ~80 라인 |
| M8-3 | Secondary | 리셋 트리 검증 | 리셋 매트릭스 문서 |
| M8-4 | Secondary | 테스트벤치 작성 | control_signal_mux_tb.sv |

**목표 라인 수 감소**: ~550 -> ~280 라인
**목표 달성**: cyan_top.sv <300 라인

### Week 9: FSM 리팩토링 및 통합 (Phase 4)

| 마일스톤 | 우선순위 | 작업 | 산출물 |
|----------|----------|------|--------|
| M9-1 | Primary | ctrl_fsm_sg.sv 3블록 변환 | ctrl_fsm_sg_refactored.sv |
| M9-2 | Primary | FSM-002 완료 | FSM 검증 리포트 |
| M9-3 | Secondary | 회귀 테스트 실행 | 회귀 테스트 결과 |
| M9-4 | Secondary | 타이밍 클로저 검증 | 타이밍 리포트 |

### Week 10: 검증 및 문서화 (Phase 5)

| 마일스톤 | 우선순위 | 작업 | 산출물 |
|----------|----------|------|--------|
| M10-1 | Primary | 전체 시스템 시뮬레이션 | 시뮬레이션 결과 |
| M10-2 | Primary | 테스트 커버리지 >70% 달성 | 커버리지 리포트 |
| M10-3 | Secondary | 문서화 완료 | 업데이트된 README |
| M10-4 | Secondary | 릴리스 준비 | 릴리스 노트 |

---

## 2. 기술 접근 방식 (Technical Approach)

### 2.1 모듈 추출 전략

#### 단계 1: 의존성 분석
1. 신호 흐름 분석 (입력 -> 처리 -> 출력)
2. 클럭 도메인 식별
3. CDC 경로 매핑
4. 리셋 도메인 식별

#### 단계 2: 인터페이스 정의
1. 포트 리스트 정의 (clk, rst_n, 입력, 출력)
2. 파라미터 정의 (타이밍, 폭)
3. 타이밍 제약 작성

#### 단계 3: 추출 및 검증
1. 모듈 코드 작성
2. 단위 테스트벤치 작성
3. 시뮬레이션 검증
4. CDC 검증 (필요시)

### 2.2 아키텍처 설계

#### 새로운 모듈 계층 구조

```
cyan_top.sv (<300 라인)
├── clock_gen_top.sv (완료)
├── mipi_integration.sv (완료)
├── reg_map_integration.sv (완료)
├── data_path_integration.sv (완료)
├── sequencer_wrapper.sv (완료)
├── ti_roic_integration.sv (완료)
├── debug_integration.sv (신규, Week 6)
├── sync_processing.sv (신규, Week 6)
├── gate_driver_output.sv (신규, Week 7)
├── roic_channel_array.sv (신규, Week 7)
├── control_signal_mux.sv (신규, Week 8)
└── power_control.sv (신규, Week 8)
```

### 2.3 CDC 처리 전략

#### 동기화 계층

| 계층 | 목적 | 구현 |
|------|------|------|
| L1 | 단일 비트 신호 | cdc_sync_3ff |
| L2 | 멀티비트 데이터 | async_fifo_24b |
| L3 | 리셋 브리지 | reset_bridge (동기화/해제) |
| L4 | 핸드셰이크 | 2-핑 핸드셰이크 프로토콜 |

### 2.4 리셋 아키텍처

#### 리셋 도메인

```
외부 nRST (active-LOW)
    |
    v
clock_gen_top
    |--> rst_n_200mhz --> 200MHz 도메인
    |--> rst_n_100mhz --> 100MHz 도메인
    |--> rst_n_20mhz  --> 20MHz 도메인
    |--> rst_n_eim    --> eim_clk 도메인
    |--> rst_n_5mhz   --> 5MHz 도메인
    |--> rst_n_1mhz   --> 1MHz 도메인
```

### 2.5 테스트 전략

#### 테스트 피라미드

```
         /\
        /  \  E2E (통합)
       /----\
      /      \ 단위 (모듈)
     /________\
```

| 테스트 레벨 | 범위 | 커버리지 목표 | 실행 주기 |
|-------------|------|---------------|-----------|
| 단위 테스트 | 모듈별 | 80% | 커밋 시 |
| 통합 테스트 | 모듈 간 | 70% | PR 시 |
| E2E 테스트 | 시스템 | 60% | 릴리스 시 |

---

## 3. 리스크 완화 계획 (Risk Mitigation)

### 3.1 리스크 식별

| 리스크 ID | 설명 | 확률 | 영향 | 점수 |
|-----------|------|------|------|------|
| R1 | CDC 경로 재발 | 중간 | 높음 | 높음 |
| R2 | 리셋 일관성 누락 | 낮음 | 중간 | 중간 |
| R3 | 기능 회귀 | 중간 | 높음 | 높음 |
| R4 | 타이밍 위반 | 낮음 | 높음 | 중간 |
| R5 | 테스트 커버리지 부족 | 중간 | 중간 | 중간 |

### 3.2 완화 전략

#### R1: CDC 경로 재발 완화

**전략**: CDC 검증 자동화
1. Vivado CDC Report 사용
2. 커스텀 CDC 검증 스크립트
3. 코드 리뷰 체크리스트

```tcl
# Vivado CDC 검증
report_cdc -details
report_timing -max_paths 100 -delay_type max -sort_by slack
```

#### R2: 리셋 일관성 완화

**전략**: 리셋 매트릭스 문서화
1. 모든 리셋 신호 매트릭스 작성
2. 리셋 극성 자동 검증 스크립트
3. 코드 리뷰 시 확인

#### R3: 기능 회귀 완화

**전략**: 회귀 테스트 스위트
1. 기존 테스트벤치 유지
2. 회귀 테스트 자동화
3. PR 전 자동 실행

#### R4: 타이밍 위반 완화

**전략**: 타이밍 제약 업데이트
1. 모든 새로운 모듈에 타이밍 제약 추가
2. 합성 후 타이밍 리포트 확인
3. 주요 경로에 파이프라이닝 적용

#### R5: 테스트 커버리지 부족 완화

**전략**: 커버리지 추적
1. 커버리지 리포트 자동화
2. PR 시 커버리지 확인
3. 커버리지 기준선 설정

### 3.3 대체 계획 (Contingency Plan)

| 시나리오 | 트리거 | 대체 조치 |
|----------|--------|-----------|
| CDC 재발 | Vivado CDC Report 에러 | Week 6 연장, CDC 전문가 상담 |
| 타이밍 실패 | WNS < 0 | 파이프라이닝 추가, 주파수下调 |
| 리소스 초과 | 리소스 > 90% | 최적화 Week 추가 |
| 기능 회귀 | 회귀 테스트 실패 | 롤백, 원인 분석 후 재작업 |

---

## 4. 품질 게이트 (Quality Gates)

### 4.1 단계별 품질 게이트

#### Week 6 품질 게이트

| 항목 | 기준 | 검증 방법 |
|------|------|-----------|
| 모듈 추출 | 2개 모듈 완료 | 코드 리뷰 |
| CDC 검증 | 0개 위반 | Vivado CDC Report |
| 테스트 통과 | 100% | 시뮬레이션 |
| 라인 수 | <900 | wc -l cyan_top.sv |

#### Week 7 품질 게이트

| 항목 | 기준 | 검증 방법 |
|------|------|-----------|
| 모듈 추출 | 4개 모듈 완료 | 코드 리뷰 |
| CDC 검증 | 0개 위반 | Vivado CDC Report |
| 테스트 통과 | 100% | 시뮬레이션 |
| 라인 수 | <550 | wc -l cyan_top.sv |

#### Week 8 품질 게이트

| 항목 | 기준 | 검증 방법 |
|------|------|-----------|
| 모듈 추출 | 6개 모듈 완료 | 코드 리뷰 |
| 리셋 일관성 | 100% | 리셋 매트릭스 |
| 테스트 통과 | 100% | 시뮬레이션 |
| 라인 수 | <300 | wc -l cyan_top.sv |

#### Week 9-10 품질 게이트

| 항목 | 기준 | 검증 방법 |
|------|------|-----------|
| FSM 3블록 | 100% | 코드 리뷰 |
| 테스트 커버리지 | >70% | 커버리지 리포트 |
| 타이밍 | WNS > 0 | Vivado 타이밍 리포트 |
| 회귀 | 0개 | 회귀 테스트 |

### 4.2 최종 품질 게이트

| 카테고리 | 항목 | 기준 |
|----------|------|------|
| 코드 | cyan_top.sv 라인 | <300 |
| 코드 | 모든 리셋 | active-LOW |
| 코드 | 모든 FSM | 3블록 스타일 |
| CDC | CDC 위반 | 0 |
| 타이밍 | WNS | >0 |
| 테스트 | 커버리지 | >70% |
| 회귀 | 회귀 | 0 |

---

## 5. 의존성 관리 (Dependency Management)

### 5.1 작업 의존성 그래프

```
Week 6 (debug_integration, sync_processing)
    |
    v
Week 7 (gate_driver_output, roic_channel_array)
    |        ^-- Week 6 완료 필요
    v
Week 8 (control_signal_mux, power_control)
    |        ^-- Week 7 완료 필요
    v
Week 9 (FSM 리팩토링)
    |        ^-- Week 8 완료 필요
    v
Week 10 (검증 및 문서화)
             ^-- Week 9 완료 필요
```

### 5.2 병렬 실행 가능

다음 작업은 독립적으로 병렬 실행 가능:
- debug_integration.sv 추출 || sync_processing.sv 추출
- gate_driver_output.sv 추출 || roic_channel_array.sv 추출
- control_signal_mux.sv 추출 || power_control.sv 추출

---

## 6. 자원 할당 (Resource Allocation)

### 6.1 인력

| 역할 | 책임 | 가용성 |
|------|------|--------|
| FPGA 설계자 | 모듈 추출, FSM 리팩토링 | 100% |
| 검증 엔지니어 | 테스트벤치 작성, 시뮬레이션 | 80% |
| 리뷰어 | 코드 리뷰, CDC 검증 | 20% |

### 6.2 도구

| 도구 | 용도 | 버전 |
|------|------|------|
| Xilinx Vivado | 합성, 타이밍 분석 | 2023.2+ |
| ModelSim/Questa | 시뮬레이션 | 2024+ |
| Verilator | 리트 시뮬레이션 | 5.0+ |
| Git/GitHub | 버전 관리 | 최신 |

---

## 7. 추적성 (Traceability)

### 7.1 계획-요구사항 매핑

| 마일스톤 | 관련 요구사항 | 태그 |
|----------|---------------|-----|
| M6-1, M6-2 | UR-004 | TOP-001 |
| M7-1, M7-2 | UR-002, ED-001 | CDC-004 |
| M8-1, M8-2 | UR-001, SD-001 | RST-004 |
| M9-1, M9-2 | UR-003, ED-003 | FSM-002 |
| M10-1, M10-2 | UR-005 | QUAL-001 |

### 7.2 진척도 추적

```
TAG: SPEC-REFACTOR-001
- Week 6: [][][][][][] 0% (0/4 완료)
- Week 7: [][][][][][] 0% (0/4 완료)
- Week 8: [][][][][][] 0% (0/4 완료)
- Week 9: [][][][][][] 0% (0/4 완료)
- Week 10: [][][][][][] 0% (0/4 완료)
```

---

**문서 버전**: 1.0
**작성일**: 2026-02-03
**다음 업데이트**: Week 6 완료 시
