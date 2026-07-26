# Finite State Machine (FSM)

## Overview

The SPI Master Controller is implemented using a **4-state Finite State Machine (FSM)**. The FSM coordinates every stage of an SPI transaction, from waiting for a transfer request to completing data transmission and reception.

The four states are:

- IDLE
- LOAD
- TRANSFER
- DONE

---



---

# State Description

## 1. IDLE

This is the default state after reset.

### Responsibilities

- Wait for the user to assert `start`
- Keep Chip Select inactive
- Keep SPI clock at its idle level
- Clear Busy signal

### Outputs

| Signal | Value |
|---------|-------|
| CS | High |
| Busy | 0 |
| Done | 0 |
| SCLK | CPOL |

### Exit Condition

```
start == 1
```

Transitions to:

```
LOAD
```

---

## 2. LOAD

The LOAD state initializes the controller before communication begins.

### Operations

- Load transmit data into the TX shift register
- Clear RX shift register
- Reset sample counter
- Reset clock divider
- Assert Chip Select

This state lasts exactly one clock cycle.

### Outputs

| Signal | Value |
|---------|-------|
| CS | Low |
| Busy | 1 |
| Done | 0 |

### Exit Condition

Automatically transitions to

```
TRANSFER
```

---

## 3. TRANSFER

This is the main operating state.

During this state the controller simultaneously:

- Generates SPI clock
- Shifts transmit data
- Samples receive data
- Counts received bits

The CPOL/CPHA logic determines:

- Shift edge
- Sample edge

The transfer ends only after the final bit has been **sampled**, ensuring correct operation for all four SPI modes.

### Outputs

| Signal | Value |
|---------|-------|
| CS | Low |
| Busy | 1 |
| Done | 0 |

### Exit Condition

```
sample_count == DATA_WIDTH
```

Transitions to

```
DONE
```

---

## 4. DONE

The DONE state indicates that the SPI transaction has completed successfully.

### Operations

- Deassert Chip Select
- Assert Done signal
- Make received data available on `rx_data`

### Outputs

| Signal | Value |
|---------|-------|
| CS | High |
| Busy | 0 |
| Done | 1 |

### Exit Condition

```
start == 0
```

Transitions back to

```
IDLE
```

---

# State Transition Table

| Current State | Condition | Next State |
|---------------|-----------|------------|
| IDLE | start = 1 | LOAD |
| LOAD | Always | TRANSFER |
| TRANSFER | sample_count == DATA_WIDTH | DONE |
| DONE | start = 0 | IDLE |

---

# Why Completion is Based on Samples

An important design decision in this controller is that the end of a transfer is determined by the **number of received samples**, not by the number of transmitted shifts.

Initially, completion was detected using the shift counter. While this worked for some SPI modes, it failed for others because the relationship between shifting and sampling changes with the value of CPHA.

The final implementation instead counts **sample events**, ensuring that:

- every transmitted bit has been received,
- all four SPI modes behave identically,
- the last received bit is never missed.

This approach makes the controller independent of CPHA timing differences and results in a cleaner, more robust implementation.

---

# Design Summary

- Four-state Moore FSM
- One-clock LOAD state
- Full-duplex data transfer
- Completion based on received samples
- Supports all SPI modes
- Simple and synthesizable implementation
