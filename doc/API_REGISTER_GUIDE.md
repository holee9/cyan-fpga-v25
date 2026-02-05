# API 및 레지스터 가이드 (API & Register Guide)

**Date**: 2026-02-05
**Project**: CYAN-FPGA xdaq_top
**Interface**: SPI Slave

---

## 1. SPI 인터페이스 스펙

### 1.1 하드웨어 연결

| 신호명 | 방향 | 설명 |
|--------|------|------|
| `SPI_SCK` | 입력 | SPI 클럭 |
| `SPI_MOSI` | 입력 | Master Out Slave In |
| `SPI_MISO` | 출력 | Master In Slave Out |
| `SPI_CS_N` | 입력 | Chip Select (Active-LOW) |

### 1.2 SPI 모드

| 파라미터 | 값 |
|----------|-----|
| SPI Mode | Mode 0 (CPOL=0, CPHA=0) |
| 클럭 주파수 | 최대 25 MHz |
| 데이터 폭 | 16-bit |
| 주소 폭 | 14-bit |
| 비트 순서 | MSB First |

> **참고**: `spi_slave` 모듈은 파라미터화되어 있으며, `reg_map_integration.sv`에서
> `payload=16`, `addrsz=14`, `pktsz=32`로 오버라이드하여 사용합니다.

### 1.3 SPI 전송 형식

```
┌─────────┬─────────┬─────────┬─────────┬─────────┐
│ CS_N    │ Command │ Address │ Data[15:0]│  Dummy  │
├─────────┼─────────┼─────────┼─────────┼─────────┤
│ Active  │ 2-bit   │ 14-bit  │ 16-bit  │ (None)  │
└─────────┴─────────┴─────────┴─────────┴─────────┘
```

**패킷 구조** (총 32비트):
- Header [2]: R/W 플래그
- Address [14]: 레지스터 주소
- Data [16]: 쓰기/읽기 데이터

---

## 2. 레지스터 맵 구조

### 2.1 주소 할당

| 주소 범위 | 영역 | 접근 권한 |
|----------|------|-----------|
| `0x0000 - 0x00FF` | 제어 레지스터 | RW |
| `0x0100 - 0x01FF` | 상태 레지스터 | RO |
| `0x0200 - 0x02FF` | 데이터 버퍼 | RW |
| `0x0300 - 0x03FF` | 설정 레지스터 | RW |
| `0x0400 - 0x04FF` | 디버그 레지스터 | RW |

### 2.2 레지스터 정의

**주요 제어 레지스터**:

| 주소 | 이름 | 비트 | 리셋값 | 설명 |
|------|------|-----|---------|------|
| `0x0000` | `CTRL` | [15:0] | 0x0000 | 메인 제어 |
| `0x0001` | `STATUS` | [15:0] | - | 상태 읽기 (RO) |
| `0x0002` | `CLK_EN` | [7:0] | 0x00 | 클럭 활성화 |
| `0x0003` | `RESET` | [7:0] | 0x00 | 리셋 제어 |
| `0x0010` | `DATA_IN` | [15:0] | - | 입력 데이터 |
| `0x0011` | `DATA_OUT` | [15:0] | - | 출력 데이터 |

---

## 3. 주요 레지스터 상세

### 3.1 CTRL (0x00) - 메인 제어

| 비트 | 이름 | 설명 |
|-----|------|------|
| [0] | `ENABLE` | 1 = 활성화, 0 = 비활성화 |
| [1] | `START` | 1 = 시작 트리거 |
| [2] | `STOP` | 1 = 정지 트리거 |
| [3] | `RESET` | 1 = 소프트 리셋 |
| [7:4] | `MODE` | 동작 모드 선택 |
| [15:8] | `RESERVED` | 예약 (쓰기 금지) |
| [31:16] | `CONFIG` | 설정 파라미터 |

### 3.2 STATUS (0x01) - 상태 읽기 (RO)

| 비트 | 이름 | 설명 |
|-----|------|------|
| [0] | `BUSY` | 1 = 동작 중 |
| [1] | `READY` | 1 = 준비 완료 |
| [2] | `ERROR` | 1 = 에러 발생 |
| [3] | `LOCKED` | 1 = 클럭 락 완료 |
| [7:4] | `STATE` | FSM 상태 코드 |
| [15:8] | `ERROR_CODE` | 에러 코드 |
| [31:16] | `COUNTER` | 내부 카운터 값 |

### 3.3 CLK_EN (0x02) - 클럭 활성화

| 비트 | 이름 | 설명 |
|-----|------|------|
| [0] | `CLK_100M_EN` | 100MHz 클럭 활성화 |
| [1] | `CLK_20M_EN` | 20MHz 클럭 활성화 |
| [2] | `CLK_200M_EN` | 200MHz 클럭 활성화 |
| [7:3] | `RESERVED` | 예약 |

---

## 4. 프로그래밍 예제 (Python)

### 4.1 SPI 통신 기본 함수

```python
import spidev
import time

class XdaqSpi:
    def __init__(self, bus=0, device=0, max_speed_hz=25000000):
        self.spi = spidev.SpiDev(bus, device)
        self.spi.max_speed_hz = max_speed_hz
        self.spi.mode = 0  # CPOL=0, CPHA=0

    def write_register(self, addr, data):
        """레지스터 쓰기 (16-bit data, 14-bit address)"""
        # CS 활성화
        cs_pin = self._get_cs_pin()

        # 전송: [CMD(2bit) + ADDR(14bit), DATA_HI, DATA_LO]
        # addr는 14비트, data는 16비트
        tx_data = [
            (addr >> 8) & 0xFF,   # ADDR_HI (상위 6비트 + CMD 2비트)
            addr & 0xFF,          # ADDR_LO (하위 8비트)
            (data >> 8) & 0xFF,   # DATA_HI
            data & 0xFF           # DATA_LO
        ]
        rx_data = self.spi.xfer3(tx_data, cs_pin)

        return (rx_data[2] << 8) | rx_data[3]

    def read_register(self, addr):
        """레지스터 읽기 (16-bit data, 14-bit address)"""
        cs_pin = self._get_cs_pin()

        # 읽기 명령 + 주소 (CMD=0b01 for read)
        cmd_hi = 0x40 | ((addr >> 8) & 0x3F)  # Read bit + ADDR_HI
        tx_data = [cmd_hi, addr & 0xFF, 0x00, 0x00]
        rx_data = self.spi.xfer3(tx_data, cs_pin)

        return (rx_data[2] << 8) | rx_data[3]

    def _get_cs_pin(self):
        """CS 핀 번호 반환 (환경에 맞게 수정 필요)"""
        return 0  # 예시 핀 번호
```

### 4.2 초기화 시퀀스

```python
def initialize_xdaq(spi):
    """XDAQ FPGA 초기화"""

    # 1. 리셋 해제
    spi.write_register(0x0000, 0x0000)  # CTRL: RESET 비트 해제
    time.sleep(0.001)

    # 2. 클럭 활성화
    spi.write_register(0x0002, 0x0007)  # CLK_EN: 모든 클럭 활성화
    time.sleep(0.001)

    # 3. READY 확인
    while True:
        status = spi.read_register(0x0001)
        if status & 0x0002:  # READY 비트
            break
        time.sleep(0.001)

    # 4. 활성화
    spi.write_register(0x0000, 0x0001)  # CTRL: ENABLE

    print("XDAQ initialized successfully")
```

### 4.3 데이터 쓰기

```python
def write_data(spi, data):
    """데이터 쓰기"""

    # 데이터 레지스터에 쓰기
    spi.write_register(0x0010, data)

    # 시작 트리거
    spi.write_register(0x0000, 0x0002)  # START 비트

    # 완료 대기
    while True:
        status = spi.read_register(0x0001)
        if not (status & 0x0001):  # BUSY 비트 해제 확인
            break
        time.sleep(0.001)

    print("Data written successfully")
```

---

## 5. 프로그래밍 예제 (C)

### 5.1 SPI 통신 기본 함수

```c
#include <stdint.h>
#include <linux/spi/spidev.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>

// SPI 파일 디스크립터
static int spi_fd = -1;

int spi_init(const char *device) {
    spi_fd = open(device, O_RDWR);
    if (spi_fd < 0) return -1;

    // SPI 모드 설정
    uint32_t mode = SPI_MODE_0;
    ioctl(spi_fd, SPI_IOC_WR_MODE, &mode);

    // 클럭 속도 설정
    uint32_t speed = 25000000;
    ioctl(spi_fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);

    return 0;
}

uint32_t spi_write_register(uint16_t addr, uint16_t data) {
    struct spi_ioc_transfer tr = {
        .tx_buf = (unsigned long)tx_data,
        .rx_buf = (unsigned long)rx_data,
        .len = 4,
        .cs_change = 1,
    };

    // CMD(2bit) + ADDR(14bit) + DATA(16bit) = 4 bytes
    uint8_t tx_data[4] = {
        (addr >> 8) & 0xFF,   // ADDR_HI (6bit) + CMD(2bit)
        addr & 0xFF,          // ADDR_LO (8bit)
        (data >> 8) & 0xFF,   // DATA_HI
        data & 0xFF           // DATA_LO
    };
    uint8_t rx_data[4] = {0};

    ioctl(spi_fd, SPI_IOC_MESSAGE(1), &tr);

    return (rx_data[2] << 8) | rx_data[3];
}

uint32_t spi_read_register(uint16_t addr) {
    struct spi_ioc_transfer tr = {
        .tx_buf = (unsigned long)tx_data,
        .rx_buf = (unsigned long)rx_data,
        .len = 4,
        .cs_change = 1,
    };

    // Read command: CMD=0b01
    uint8_t cmd_hi = 0x40 | ((addr >> 8) & 0x3F);
    uint8_t tx_data[4] = {cmd_hi, addr & 0xFF, 0x00, 0x00};
    uint8_t rx_data[4] = {0};

    ioctl(spi_fd, SPI_IOC_MESSAGE(1), &tr);

    return (rx_data[2] << 8) | rx_data[3];
}
```

---

## 6. 초기화 시퀀스

### 6.1 파워업 시퀀스

```
1. VCC_3V3 안정화
2. VCC_1V8 안정화
3. FPGA 구성 비트스트림 로드
4. SPI_CS_N deasserted
5. 리셋 해제
6. 클럭 락 대기 (~10ms)
7. READY 비트 확인
8. 일반 동작 시작
```

### 6.2 레지스터 초기화

```python
def power_on_sequence(spi):
    """파워업 초기화"""

    # 1. 대기
    time.sleep(0.1)

    # 2. 초기화 함수 호출
    initialize_xdaq(spi)

    # 3. 기본 설정
    spi.write_register(0x0030, 0x1234)  # 설정 레지스터

    # 4. 활성화
    spi.write_register(0x0000, 0x0001)

    print("Power-on sequence complete")
```

---

## 7. 에러 코드

### 7.1 STATUS 레지스터 에러 코드

| 코드 | 이름 | 설명 |
|------|------|------|
| 0x00 | `NO_ERROR` | 에러 없음 |
| 0x01 | `SPI_ERROR` | SPI 통신 에러 |
| 0x02 | `CLK_ERROR` | 클럭 에러 |
| 0x03 | `MEM_ERROR` | 메모리 에러 |
| 0x04 | `TIMEOUT` | 타임아웃 발생 |

### 7.2 에러 처리

```python
def check_error(spi):
    """에러 확인"""
    status = spi.read_register(0x0001)

    if status & 0x0004:  # ERROR 비트
        error_code = (status >> 8) & 0xFF

        if error_code == 0x01:
            print("SPI Error detected")
        elif error_code == 0x02:
            print("Clock Error detected")
        elif error_code == 0x04:
            print("Timeout Error detected")

        # 에러 복구: 리셋
        spi.write_register(0x0003, 0x0001)  # RESET 레지스터
        time.sleep(0.01)
        spi.write_register(0x0003, 0x0000)  # 리셋 해제
```

---

## 8. 고급 기능

### 8.1 버스트 쓰기

```python
def burst_write(spi, start_addr, data_list):
    """버스트 쓰기 (연속 쓰기)"""

    for i, data in enumerate(data_list):
        spi.write_register(start_addr + i, data)

    # 전체 데이터 쓰기 후 시작 트리거
    spi.write_register(0x0000, 0x0002)
```

### 8.2 FIFO 제어

```python
def write_fifo(spi, data):
    """FIFO에 데이터 쓰기"""

    # FIFO FULL 확인
    status = spi.read_register(0x0001)
    while status & 0x0080:  # FULL 비트
        time.sleep(0.001)
        status = spi.read_register(0x0001)

    # 데이터 쓰기
    spi.write_register(0x0010, data)
```

---

## 9. 참고 자료

- 엑셀 파일: `doc/Xdaq_Register_Map.xlsx`
- 엑셀 파일: `doc/Xdaq_Register_Map_24.xlsx`
- 관련 모듈: `rf_spi_controller.sv`

---

**END OF API & REGISTER GUIDE**
