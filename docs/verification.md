# Verification

## Overview

The SPI Master Controller was verified using a **self-checking SystemVerilog testbench**. The verification environment exercises the controller in all four SPI modes and automatically compares the received data against the expected value.

The objective was to verify:

- Correct SPI clock generation
- Correct chip select behavior
- Correct MOSI transmission
- Correct MISO reception
- Support for all four CPOL/CPHA modes
- Correct full-duplex communication
- Robust operation across randomized data patterns

---

# Verification Environment

The testbench consists of the following components:

- Clock Generator
- Reset Task
- SPI Transfer Task
- Edge Synchronization Task
- Result Checker
- Directed Test Cases
- Randomized Test Cases

The testbench is fully self-checking and reports PASS/FAIL automatically.

---

# Clock Generation

The system clock is generated using a periodic process.

```systemverilog
always #(CLK_PERIOD/2)
    clk = ~clk;
```

This clock drives both the SPI controller and the verification environment.

---

# Reset

A dedicated reset task initializes the controller before any transfer.

The reset task performs the following:

- Clears input signals
- Initializes CPOL and CPHA
- Resets the DUT
- Waits for reset deassertion
- Starts testing from a known state

---

# SPI Transfer Task

The `spi_transfer()` task models an SPI slave and initiates transactions with the SPI Master.

Its responsibilities include:

- Waiting until the controller is idle
- Applying transmit data
- Generating the start pulse
- Driving MISO at the correct clock edge
- Waiting for transaction completion

The task automatically adapts its behavior based on CPHA.

This ensures accurate modeling of SPI timing for all four operating modes.

---

# Edge Synchronization

The helper task `wait_edge()` waits for the appropriate SPI clock edge before updating MISO.

Depending on CPOL and CPHA, the edge changes automatically.

This allows one verification task to support every SPI mode.

---

# Result Checker

The `check_result()` task compares the expected slave data with the data received by the SPI Master.

```text
Expected Data == rx_data
```

If the comparison succeeds:

```
PASS
```

Otherwise:

```
FAIL
```

The task also maintains:

- Total test count
- Pass count
- Fail count

---

# Directed Test Cases

Directed tests verify each SPI operating mode individually.

The following modes were tested:

| Test | CPOL | CPHA |
|------|------|------|
| Mode 0 | 0 | 0 |
| Mode 1 | 0 | 1 |
| Mode 2 | 1 | 0 |
| Mode 3 | 1 | 1 |

Each directed test uses known transmit and receive data patterns to verify protocol correctness.

---

# Randomized Verification

After the directed tests, randomized testing is performed.

For each transaction:

- Random master transmit data is generated.
- Random slave transmit data is generated.
- The transfer is executed.
- The received data is automatically verified.

Example:

```systemverilog
random_master = $urandom();
random_slave  = $urandom();
```

Randomized testing improves confidence by exercising a wide variety of input combinations beyond manually selected test vectors.

---

# Test Summary

The verification suite consists of:

| Test Type | Number of Tests |
|-----------|----------------:|
| Directed Tests | 4 |
| Random Tests | 20 |
| Total Tests | 24 |

Final simulation result:

```
TEST CASES = 24
PASSED     = 24
FAILED     = 0
```

---

# Debugging Process

Several issues were identified and resolved during verification.

## 1. Start Pulse Timing

Initially, consecutive transfers failed because the `start` pulse was asserted before the FSM had returned to the IDLE state.

The testbench was updated to wait until the controller became idle before initiating a new transfer.

---

## 2. Receive Data Update

Originally, `rx_data` was updated in the DONE state.

This caused the previous transaction's data to remain visible for one extra cycle.

The implementation was modified so that `rx_data` is updated immediately after the final sample is received.

---

## 3. Transfer Completion

The first implementation determined completion using the number of transmit shift operations.

Although this worked for some SPI modes, it failed for others because the timing relationship between shifting and sampling changes with CPHA.

The final implementation determines completion using the number of **sample events**, ensuring correct operation in every SPI mode.

---

## 4. Edge Synchronization

Special care was taken to ensure that:

- MISO changes only on shift edges.
- MISO is sampled only on sample edges.

This accurately models real SPI slave behavior.

---

# Verification Coverage

The verification environment validates:

- ✓ Reset behavior
- ✓ Clock divider operation
- ✓ FSM transitions
- ✓ Busy signal
- ✓ Done signal
- ✓ Chip Select
- ✓ MOSI transmission
- ✓ MISO reception
- ✓ All four SPI modes
- ✓ Directed testing
- ✓ Randomized testing
- ✓ Full-duplex communication

---

# Conclusion

The SPI Master Controller successfully passed all directed and randomized verification tests.

The final design demonstrates correct protocol implementation, reliable data transfer, and robust support for all four SPI operating modes.
