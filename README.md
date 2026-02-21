# AXI3 Slave — UVM Verification

UVM-based functional verification environment for an AXI3 Slave RTL supporting FIXED, INCR, and WRAP burst types with write response and error detection.

---

## DUT — `AXI_Slave`

| Parameter | Value |
|-----------|-------|
| Protocol | AXI3 (AMBA) |
| Data Bus | 32-bit |
| Address Bus | 32-bit |
| ID Width | 4-bit (AWID, WID, BID, ARID, RID) |
| Burst Length | AWLEN[3:0] — max 16 beats |
| Transfer Size | AWSIZE[2:0] — up to 4 bytes (3'b010) |
| Burst Types | FIXED (2'b00), INCR (2'b01), WRAP (2'b10) |
| Internal Memory | `logic [7:0] memory [128]` — 128 bytes |
| Reset | Active-low synchronous (`resetn`) |
| Write Response | BRESP = OKAY (2'b00) or SLVERR (2'b10) |
| Read Response | RRESP per beat, RLAST on last beat |

### RTL Architecture — 3 Independent FSMs

```
Write Data FSM       Write Response FSM     Read FSM
──────────────       ──────────────────     ────────────
widle                bidle                  ridle
waddr_dec            bvalids                raddr_dec
wstart               bwait                  rvalids
wreadys                                     rlast_st
wlast_st
```

All 3 FSMs run in **parallel** — write data, write response, and read can operate simultaneously.

---

## Testbench Architecture

```
┌─────────────────────────────────────────────────────┐
│                     UVM Test                        │
│         (fixed / incr / wrap / error / reset)       │
└───────────────────────┬─────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────┐
│                  UVM Environment                    │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │                  UVM Agent                   │   │
│  │                                              │   │
│  │   ┌────────────┐     ┌──────────────────┐   │   │
│  │   │ Sequencer  │────►│     Driver       │───┼───┼──► DUT
│  │   └────────────┘     └──────────────────┘   │   │
│  │                      ┌──────────────────┐   │   │
│  │                      │     Monitor      │◄──┼───┼─── DUT
│  │                      └────────┬─────────┘   │   │
│  └───────────────────────────────┼─────────────┘   │
│                                  │ TLM Analysis     │
│                     ┌────────────▼──────────────┐   │
│                     │       Scoreboard          │   │
│                     │   (shadow mem + checker)  │   │
│                     └───────────────────────────┘   │
│                     ┌─────────────────────────────┐ │
│                     │         Coverage            │ │
│                     └─────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## Directory Structure

```
AXI3-Slave-UVM-Verification/
│
├── rtl/
│   └── axi_slave.sv              ← DUT : AXI3 Slave with 3 parallel FSMs
│
├── env/
│   ├── axi_interface.sv          ← Virtual interface — all AXI3 signals
│   ├── axi_transaction.sv        ← seq_item with operation enum + constraints
│   ├── axi_sequence.sv           ← Base sequence (body overridden per test)
│   ├── axi_sequencer.sv          ← UVM sequencer
│   ├── axi_driver.sv             ← Drives all 5 AXI channels
│   ├── axi_monitor.sv            ← Samples DUT every clock, writes to TLM port
│   ├── axi_agent.sv              ← Agent : driver + monitor + sequencer
│   ├── axi_coverage.sv           ← Functional covergroups (8 coverpoints)
│   ├── axi_scoreboard.sv         ← Shadow memory model + PASS/FAIL checker
│   └── axi_environment.sv        ← Env : agent + scoreboard
│
├── test/
│   ├── axi_pkg.sv                ← Package — includes all env and test files
│   ├── axi_base_test.sv          ← Base test with reset_dut task
│   ├── axi_fixed_wr_rd_test.sv   ← FIXED burst test
│   ├── axi_incr_wr_rd_test.sv    ← INCR burst test
│   ├── axi_wrap_wr_rd_test.sv    ← WRAP burst test
│   ├── axi_error_wr_rd_test.sv   ← Out-of-range address test
│   └── axi_reset_dut_test.sv     ← Reset test
│
├── top/
│   └── axi_top.sv                ← Top : DUT + interface + run_test()
│
└── sim/
    └── Makefile                  ← Compile, run, coverage, regression targets
```

---

## Transaction — `axi_transaction`

```systemverilog
typedef enum bit[2:0] {
    wrrdfixed = 0,   // FIXED burst write + read
    wrrdincr  = 1,   // INCR  burst write + read
    wrrdwrap  = 2,   // WRAP  burst write + read
    wrrderror = 3,   // Out-of-range address (SLVERR)
    rstdut    = 4    // Reset DUT
} operation;
```

**Constraints:**
- `awsize == 3'b010` (4-byte transfers fixed)
- `awburst inside {0,1,2}` (valid burst types only)
- `awlen == arlen` (write and read same length)
- `soft awaddr inside {[0:127]}` (stay within valid memory range)
- All IDs tied: `awid == wid == bid == arid == rid`

---

## Coverage — `axi_coverage`

| Coverpoint | Signal | Bins |
|------------|--------|------|
| cp1 | `awaddr` | valid range [0:127], out-of-range [128:$] |
| cp2 | `wdata` | [0:255] |
| cp3 | `araddr` | valid range [0:127], out-of-range [128:$] |
| cp4 | `rdata` | [0:255] |
| cp5 | `awvalid` | 0, 1 |
| cp6 | `wvalid` | 0, 1 |
| cp7 | `rvalid` | 0, 1 |
| cp8 | `rready` | 0, 1 |

---

## Test Suite

| Test | Burst | AWLEN | Address | Verifies |
|------|-------|-------|---------|---------|
| `axi_fixed_wr_rd_test` | FIXED (2'b00) | 7 (8 beats) | Randomized | Same address repeats — write all 8 beats, read back |
| `axi_incr_wr_rd_test` | INCR (2'b01) | 7 (8 beats) | addr=5 | Address increments by 4 each beat |
| `axi_wrap_wr_rd_test` | WRAP (2'b10) | 4 (5 beats) | addr=5 | Address wraps at boundary |
| `axi_error_wr_rd_test` | INCR (2'b01) | 7 (8 beats) | addr=129 | RRESP = SLVERR (2'b10) on out-of-range |
| `axi_reset_dut_test` | — | — | — | Reset asserted twice, DUT state clears |

---

## How to Run

```bash
cd sim/

# Step 1 — Compile
make compile

# Step 2 — Run tests individually
make tc1    # axi_fixed_wr_rd_test
make tc2    # axi_incr_wr_rd_test
make tc3    # axi_wrap_wr_rd_test
make tc4    # axi_error_wr_rd_test
make tc5    # axi_reset_dut_test

# Step 3 — Run all 5 tests
make tc

# Step 4 — Merge coverage + generate HTML report
make regression

# Clean all generated files
make clean
```

---

## Simulation Results

All 5 tests completed with **UVM_ERROR : 0 | UVM_FATAL : 0**

```
[SCO] --PASS-- rdata=6   <==> sco.rdata=6
[SCO] --PASS-- rdata=94  <==> sco.rdata=94
[SCO] --PASS-- rdata=22  <==> sco.rdata=22
[SCO] --PASS-- rdata=54  <==> sco.rdata=54
[SCO] --PASS-- rdata=61  <==> sco.rdata=61

RRESP = 10  ← SLVERR correctly asserted on address 129
```

---

## Tools

| Tool | Details |
|------|---------|
| Simulator | Synopsys VCS T-2022.06 |
| Methodology | UVM 1.2 |
| Waveform | Verdi — FSDB format |
| Coverage | VCS coverage + urg merge tool |
