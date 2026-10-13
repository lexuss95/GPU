# 04 — Interfaces, Registers, Clock and Reset

## Why this matters

Interfaces are where blocks — and teams — meet. A precise port list and
protocol lets the RTL designer, the verification engineer and the SoC
integrator work independently and still fit together.

> **How Apple does it (public info):** Apple GPUs sit inside Apple's SoCs and
> share memory with the CPU through the SoC fabric; the driver talks to the GPU
> through memory-mapped registers and command buffers in memory. MiniTile uses
> standard, simple protocols in the same roles: APB for registers, a
> valid/ready memory interface for data.

## Top-level ports (`gpu_top`)

| Port | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | The only clock. Target 50 MHz. |
| `rst_n` | in | 1 | Active-low reset, may be asserted/deasserted asynchronously. |
| **APB slave (CSR)** | | | |
| `psel` | in | 1 | |
| `penable` | in | 1 | |
| `pwrite` | in | 1 | |
| `paddr` | in | 8 | Byte address of the register |
| `pwdata` | in | 32 | |
| `prdata` | out | 32 | |
| `pready` | out | 1 | Always 1 (no wait states) |
| `pslverr` | out | 1 | 1 for an access to an unmapped address |
| `irq` | out | 1 | Level interrupt: `\|(IRQ_STATUS & IRQ_EN)` |
| **Instruction fetch port** | | | |
| `imem_req_valid` | out | 1 | |
| `imem_req_ready` | in | 1 | |
| `imem_req_addr` | out | 32 | Byte address, 4-byte aligned |
| `imem_rsp_valid` | in | 1 | |
| `imem_rsp_data` | in | 32 | Instruction |
| **Data port** | | | |
| `dmem_req_valid` | out | 1 | |
| `dmem_req_ready` | in | 1 | |
| `dmem_req_write` | out | 1 | 1 = store, 0 = load |
| `dmem_req_addr` | out | 32 | Byte address, 4-byte aligned |
| `dmem_req_wdata` | out | 32 | Store data |
| `dmem_rsp_valid` | in | 1 | Load data valid, or store done |
| `dmem_rsp_rdata` | in | 32 | Load data (ignored for stores) |

## APB (CSR access)

Standard AMBA APB3: setup phase (`psel`=1, `penable`=0) then access phase
(`penable`=1). `pready` is tied to 1, so every access takes exactly 2 cycles.
Reads of write-only bits return 0. Writes to read-only registers are ignored
(no error). Accesses to unmapped addresses set `pslverr`=1.

## CSR register map

| Offset | Name | Access | Reset | Description |
|---|---|---|---|---|
| 0x00 | `ID` | RO | 0x4D54_4731 | ASCII "MTG1" |
| 0x04 | `VERSION` | RO | 0x0000_0001 | Spec v0.1 |
| 0x08 | `CTRL` | WO | 0 | bit 0 `START`: write 1 to launch a kernel (ignored while busy) |
| 0x0C | `STATUS` | RO | 0 | see below |
| 0x10 | `KERNEL_PC` | RW | 0 | Address of the first kernel instruction |
| 0x14 | `ARG_BASE` | RW | 0 | Address of the argument buffer |
| 0x18 | `GRID_SIZE` | RW | 0 | Number of threadgroups (≥ 1) |
| 0x1C | `TG_SIZE` | RW | 0 | Threads per threadgroup (1 … 32) |
| 0x20 | `IRQ_EN` | RW | 0 | bit 0 `DONE`, bit 1 `ERROR` |
| 0x24 | `IRQ_STATUS` | W1C | 0 | bit 0 `DONE`, bit 1 `ERROR`; write 1 to clear |
| 0x28 | `ERR_PC` | RO | 0 | PC of the instruction that caused the last error |

Config registers (`KERNEL_PC` … `TG_SIZE`) must not be changed while
`STATUS.BUSY` = 1; the dispatcher copies them at `START`.

### STATUS (0x0C)

| Bits | Name | Meaning |
|---|---|---|
| 0 | `BUSY` | A kernel is running |
| 1 | `DONE` | Last kernel finished without error (cleared at `START`) |
| 2 | `ERROR` | Last kernel stopped with an error (cleared at `START`) |
| 7:4 | `ERR_CODE` | Error cause, see table |

| `ERR_CODE` | Cause |
|---|---|
| 0 | none |
| 1 | Illegal instruction (opcode, cond or special register) |
| 2 | Misaligned memory address or misaligned `KERNEL_PC` |
| 3 | Threadgroup memory address ≥ 1024 |
| 4 | Mask stack overflow or underflow |
| 5 | Bad configuration (`TG_SIZE` 0 or > 32, `GRID_SIZE` 0) |

## Memory ports protocol

Both ports use the same rules (the imem port is just a read-only data port):

1. A **request** is transferred in a cycle where `req_valid` and `req_ready`
   are both 1. Once `req_valid` is 1, the GPU keeps it and all request fields
   stable until `req_ready` is 1.
2. Every request gets **exactly one response**, `rsp_valid` = 1 for one cycle,
   at least one cycle after the request. There is no `rsp_ready`: the GPU
   always accepts a response.
3. v0.1 has **at most one outstanding request per port**, so responses need no
   ID.
4. Both ports see the same memory (unified memory). The GPU never fetches
   instructions from an address it is writing in the same kernel.

Load with 1 wait state and a 2-cycle response:

```
cycle             0     1     2     3     4
dmem_req_valid    1     1     0     0     0
dmem_req_ready    0     1     0     0     0     <- request accepted in cycle 1
dmem_req_addr     A     A     -     -     -
dmem_rsp_valid    0     0     0     1     0     <- response in cycle 3
dmem_rsp_rdata    -     -     -     D     -
```

## Clock and reset

### Clock

- One clock, `clk`, target **50 MHz** (20 ns) for synthesis/STA in SkyWater
  130 nm. Every flop in `gpu_top` uses `clk`, rising edge.
- No clock gating, no generated clocks, no second clock domain in v0.1.

### Reset

- `rst_n` from outside may assert and deassert at any time.
- Inside `gpu_top`, a 2-flop **reset synchronizer** produces `rst_n_sync`:
  it **asserts immediately** (asynchronously) and **deasserts on a clock edge**
  (synchronously), so no flop sees reset release near its clock edge.
- All flops with reset use `rst_n_sync` as an asynchronous active-low reset:
  `always_ff @(posedge clk or negedge rst_n_sync)`.
- Large storage (register file, threadgroup memory) has **no reset**; its
  content is undefined until written. Control state (FSMs, valid bits,
  SIMD-group status, CSRs) is always reset.
- Reset must stay asserted for at least 2 `clk` cycles.

### Power

One power domain, always on. No power gating, retention or isolation in v0.1.

## Open questions

- Replace the memory ports with AXI4 when caches arrive (iteration 7+).
- Byte write strobes on `dmem` once byte stores exist.
