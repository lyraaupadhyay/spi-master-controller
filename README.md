# SPI Master Controller (SystemVerilog)

A parameterizable **SPI (Serial Peripheral Interface) Master Controller** written in **SystemVerilog** supporting all four SPI modes (Mode 0, Mode 1, Mode 2, and Mode 3). The controller was designed using an FSM-based architecture, verified with directed and randomized test cases, and synthesized using Xilinx Vivado.

---

## Project Overview

SPI is a synchronous serial communication protocol widely used for communication between microcontrollers, processors, sensors, ADCs, DACs, Flash memories, and many other peripheral devices.

This project implements an SPI Master capable of:

- Transmitting data to an SPI slave
- Receiving data simultaneously (Full-Duplex)
- Supporting all four CPOL/CPHA configurations
- Configurable data width
- Configurable SPI clock divider
- FSM-based control logic
- Synthesizable RTL

---

## Features

- Parameterizable data width
- Parameterizable SPI clock frequency using programmable clock divider
- Supports SPI Modes 0, 1, 2 and 3
- Full-duplex communication
- FSM-based controller
- Separate transmit and receive shift registers
- Busy and Done status outputs
- Directed testbench
- Randomized verification
- Synthesizable on FPGA

---

## Module Parameters

| Parameter | Description |
|-----------|-------------|
| DATA_WIDTH | Number of bits transferred per frame |
| CLK_DIVIDER | Divides system clock to generate SPI clock |
| COUNTER_WID | Automatically calculated counter width |

---

## Top-Level Ports

| Signal | Direction | Description |
|---------|-----------|-------------|
| clk | Input | System clock |
| reset | Input | Active-high reset |
| start | Input | Starts SPI transaction |
| tx_data | Input | Data transmitted to slave |
| miso | Input | Master Input Slave Output |
| cpol | Input | Clock polarity |
| cpha | Input | Clock phase |
| sclk | Output | SPI clock |
| cs | Output | Chip Select |
| mosi | Output | Master Output Slave Input |
| rx_data | Output | Received data |
| busy | Output | Transaction in progress |
| done | Output | Transaction completed |

---

## Architecture

The SPI Master consists of the following functional blocks:

- Clock Divider
- Edge Detector
- CPOL/CPHA Logic
- Transmit Shift Register
- Receive Shift Register
- FSM Controller
- Output Logic

> A detailed architecture explanation is available in **docs/architecture.md**

---

## Finite State Machine

The controller is implemented using four states.
IDLE, START, TRANSFER,DONE

A detailed explanation is available in **docs/fsm.md**

---

## Supported SPI Modes

| Mode | CPOL | CPHA |
|------|------|------|
| Mode 0 | 0 | 0 |
| Mode 1 | 0 | 1 |
| Mode 2 | 1 | 0 |
| Mode 3 | 1 | 1 |

---

## Verification

The design was verified using a self-checking SystemVerilog testbench.

Verification includes:

- Directed tests for all four SPI modes
- Different transmit and receive patterns
- Randomized testing
- Automatic PASS/FAIL checking
- Functional verification of simultaneous transmit and receive

### Verification Summary

```
Total Test Cases : 24
Passed           : 24
Failed           : 0
```

Detailed verification methodology is available in **docs/verification.md**

---

## Synthesis

The RTL was synthesized using:

- Xilinx Vivado
- FPGA Target: AMD/Xilinx Artix-7 (xc7a35tcpg236-1)

The following reports are included:

- RTL Schematic
- Resource Utilization
- Timing Summary

See **docs/synthesis.md**

---

## Project Structure

```
spi-master-controller/
│
├── rtl/
│   └── spi.sv
│
├── tb/
│   └── spi_tb.sv
│
├── docs/
│   ├── architecture.md
│   ├── fsm.md
│   ├── verification.md
│   ├── timing.md
│   └── synthesis.md
│
├── waveforms/
│
├── synthesis/
│
└── 
```

---

## Future Improvements

- Multi-slave support
- Configurable bit ordering (MSB/LSB first)
- Variable frame lengths
- FIFO interface
- AXI/APB register interface
- Interrupt support
- Formal verification

---

## Tools Used

- SystemVerilog
- Xilinx Vivado
- GitHub

---


