# MiniTile GPU — Specification v0.1: Overview

| Item | Value |
|---|---|
| Spec version | v0.1 (first iteration) |
| Status | Draft, no RTL yet |
| HDL | SystemVerilog (IEEE 1800-2017) |
| Scope of v0.1 | Compute only: 1 shader core, command/control, memory interfaces |

## Why this matters

A specification is the contract that everything else is checked against:
the RTL implements it, the testbench verifies against it, and synthesis/STA
use the targets it sets. Writing it first forces us to decide *what* we are
building before we think about *how*.

## Goals

1. Learn how a GPU works by building a small but real one, step by step.
2. Follow the same ideas Apple GPUs use (as far as they are public), so the
   vocabulary and concepts carry over to real Apple GPU work.
3. Run a realistic front-end flow on it: compile, elaboration, lint, CDC, RDC,
   synthesis + STA, UPF, and a UVM testbench, using open-source tools.
4. Keep every iteration small. **Start as simple as possible and only add
   complexity when the design actually needs it.**

## Non-goals for v0.1

- Graphics (vertices, triangles, textures, TBDR). Compute first.
- Floating point. Integer only.
- Caches, AXI, multiple cores, pipelining, multiple clock or power domains.
- Performance. v0.1 is correct-first, not fast.

All of these are on the [roadmap](07_roadmap.md).

## How this relates to Apple GPUs (public info only)

Apple does not publish its GPU microarchitecture. What is public comes from
the Metal documentation, WWDC talks, and the Asahi Linux project's reverse
engineering of the Apple "AGX" GPU. From those sources:

| Apple GPU (public info) | MiniTile v0.1 |
|---|---|
| **Unified shader cores** — the same cores run vertex, fragment and compute work | One shader core, compute only for now |
| **SIMD-groups of 32 threads** (Metal `threadExecutionWidth` = 32) | SIMD-groups of **8** threads (smaller, same idea) |
| Each core holds many SIMD-groups in flight and switches between them to hide memory latency | 4 SIMD-groups per core, round-robin switching |
| **Threadgroup memory** — fast on-chip memory shared by a threadgroup (up to 32 KB per threadgroup in Metal) | 1 KB threadgroup memory |
| **Structured control flow** with an execution-mask stack (Asahi docs: `if`, `else`, `pop_exec`, `jmp_exec_any` style instructions) | `IF` / `ELSE` / `ENDIF` / `BANY` instructions with a mask stack |
| **Unified memory** — CPU and GPU share one physical memory | One shared memory, reached through two simple ports |
| **Tile-based deferred rendering (TBDR)** with on-chip tile memory | Future iteration (graphics) |

The name *MiniTile* is a reminder of where we are going: a tile-based GPU.

## Document map

| Doc | Content |
|---|---|
| [01_architecture.md](01_architecture.md) | Top-level block diagram, life of a kernel launch |
| [02_shader_core.md](02_shader_core.md) | Inside the shader core |
| [03_isa.md](03_isa.md) | Instruction set: formats, encodings, examples |
| [04_interfaces.md](04_interfaces.md) | Ports, CSR register map, memory protocol, clock and reset |
| [05_design_flow.md](05_design_flow.md) | Tools and pass criteria for each flow step, coding rules |
| [06_verification_plan.md](06_verification_plan.md) | UVM environment, tests, coverage, assertions |
| [07_roadmap.md](07_roadmap.md) | Iteration plan |

## Key parameters (single source of truth)

Every other document uses these values. If one changes, it changes here first.

| Parameter | Value | Why |
|---|---|---|
| `NUM_LANES` | 8 | Threads per SIMD-group and ALU lanes. Apple uses 32; 8 keeps the RTL small and waveforms readable. |
| `NUM_SG` | 4 | SIMD-group slots per core. Enough to show scheduling between groups. |
| `MAX_TG_SIZE` | 32 | Max threads per threadgroup = `NUM_SG × NUM_LANES`. |
| `NUM_REGS` | 16 | 32-bit general registers per thread (`r0` is always zero). |
| `TGM_BYTES` | 1024 | Threadgroup memory size. |
| `MASK_STACK_DEPTH` | 4 | Max nesting of `IF` blocks per SIMD-group. |
| `XLEN` | 32 | Data width and address width. |
| Clock target | 50 MHz | Easily reachable in SkyWater 130 nm with a non-pipelined design. |

## Glossary

| Term | Meaning |
|---|---|
| **Kernel** | A small program that runs on the GPU, once per thread. |
| **Thread** | One execution of the kernel, with its own registers. |
| **SIMD-group** | A group of threads that execute the same instruction at the same time on parallel lanes (Apple/Metal name; NVIDIA calls it a *warp*, AMD a *wavefront*). |
| **Lane** | One slot of a SIMD-group; lane *i* runs thread *i* of the group. |
| **Execution mask** | One bit per lane: 1 = the lane is active and its results are written. |
| **Divergence** | Lanes of one SIMD-group want to take different paths in an `if`. Handled with the execution mask. |
| **Threadgroup** | A set of threads that run on the same core, can share threadgroup memory and synchronize with barriers. |
| **Grid** | All threadgroups of one kernel launch. |
| **Threadgroup memory** | Small on-chip memory shared by one threadgroup. |
| **Barrier** | A point where all threads of a threadgroup wait for each other. |
| **CSR** | Control and status register — how the host (CPU) talks to the GPU. |
| **TBDR** | Tile-based deferred rendering: the screen is split into tiles, each rendered entirely on chip. Apple's graphics architecture; future work here. |

## References (public)

- Apple, *Metal Shading Language Specification* and *Metal Feature Set Tables*.
- Apple WWDC sessions on Apple GPU architecture, e.g. "Explore the new GPU
  architecture" type talks on TBDR, tile memory and SIMD-groups.
- Asahi Linux, Apple GPU (AGX) documentation and ISA notes (reverse engineered).
- `tiny-gpu` (open-source minimal GPU in Verilog) — a good model of how small a
  first GPU can be.

## Open questions

- None blocking v0.1. Questions specific to each block are listed at the end
  of each document.
