# SPI Timing and Clock Modes

## Overview

SPI is a synchronous serial communication protocol in which data transfer is coordinated by the SPI clock (`SCLK`). Two configuration signals determine the timing relationship between the clock and data:

- **CPOL (Clock Polarity)**
- **CPHA (Clock Phase)**

By selecting different combinations of CPOL and CPHA, the SPI protocol defines four operating modes.

This SPI Master Controller supports all four standard SPI modes.

---

# Clock Polarity (CPOL)

CPOL determines the idle state of the SPI clock.

| CPOL | Idle Clock Level |
|------|------------------|
| 0 | Low |
| 1 | High |

### CPOL = 0

```
SCLK

______/‾‾‾‾\______/‾‾‾‾\______
```

The clock remains LOW whenever no transfer is taking place.

---

### CPOL = 1

```
SCLK

‾‾‾‾‾\______/‾‾‾‾‾\______/‾‾‾
```

The clock remains HIGH whenever no transfer is taking place.

---

# Clock Phase (CPHA)

CPHA determines **when data is sampled** and **when data is shifted**.

- Sample → Receiver captures data.
- Shift → Transmitter changes data.

### CPHA = 0

- Sample on the **first** clock edge.
- Shift on the **second** clock edge.

### CPHA = 1

- Shift on the **first** clock edge.
- Sample on the **second** clock edge.

---

# SPI Modes

| Mode | CPOL | CPHA | Idle Clock |
|------|------|------|------------|
| Mode 0 | 0 | 0 | Low |
| Mode 1 | 0 | 1 | Low |
| Mode 2 | 1 | 0 | High |
| Mode 3 | 1 | 1 | High |

---

# Edge Selection

Instead of hardcoding four separate implementations, this controller converts the physical clock edges into two abstract signals:

- **first_edge**
- **second_edge**

These are selected based on CPOL.

### If CPOL = 0

```
first_edge  = Rising Edge
second_edge = Falling Edge
```

### If CPOL = 1

```
first_edge  = Falling Edge
second_edge = Rising Edge
```

The controller then uses CPHA to determine the functional meaning of those edges.

### If CPHA = 0

```
sample_edge = first_edge
shift_edge  = second_edge
```

### If CPHA = 1

```
shift_edge  = first_edge
sample_edge = second_edge
```

This abstraction allows one implementation to support every SPI mode.

---

# Internal Edge Mapping

| CPOL | CPHA | First Edge | Second Edge | Sample Edge | Shift Edge |
|------|------|------------|-------------|-------------|------------|
| 0 | 0 | Rising | Falling | Rising | Falling |
| 0 | 1 | Rising | Falling | Falling | Rising |
| 1 | 0 | Falling | Rising | Falling | Rising |
| 1 | 1 | Falling | Rising | Rising | Falling |

---

# Timing During Data Transfer

During every SPI transaction:

1. The transmitter updates MOSI on the **shift edge**.
2. The receiver samples MISO on the **sample edge**.
3. This process repeats for `DATA_WIDTH` bits.
4. The transfer completes after the **last sample**, ensuring that the final received bit is captured correctly.

---

# Why the Controller Counts Sample Events

A complete SPI transaction is defined by receiving all bits successfully.

Although data transmission is initiated by shift events, the final received bit is only guaranteed to be available after the last sample event.

For this reason, the controller determines the end of a transfer by counting **sample events** rather than **shift events**.

This approach:

- guarantees correct reception of the last bit,
- supports all four SPI modes,
- avoids CPHA-dependent timing issues,
- keeps the implementation consistent for every operating mode.

---

# Timing Summary

| Operation | Controlled By |
|-----------|---------------|
| Idle Clock Level | CPOL |
| First Clock Edge | CPOL |
| Second Clock Edge | CPOL |
| Data Shift | CPHA |
| Data Sample | CPHA |
| End of Transfer | Sample Counter |

---

# Design Highlights

- Supports all four SPI modes
- Parameterizable SPI clock frequency
- Single edge-selection logic for all modes
- CPOL/CPHA independent implementation
- Completion based on received samples for robust operation
