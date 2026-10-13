# 07 — Roadmap

Each iteration is small and ends with something that works and is checked.
Complexity is added only when the design needs it.

| # | Iteration | Output | Flow steps exercised |
|---|---|---|---|
| 1 | **Specification v0.1** ✔ | `docs/spec/` (this document set) | — |
| 2 | Repo skeleton + tools | Directory layout, Makefile, Verilator/Verible/slang/Yosys/OpenSTA installed, `gpu_pkg.sv` with all parameters | compile, lint |
| 3 | Reference model + assembler | Python assembler and ISA model; example kernels assemble and run on the model | — |
| 4 | Single-lane core | Shader core RTL with 1 lane, 1 SIMD-group: fetch, decode, ALU, register file, load/store | compile, elab, lint, simple sim |
| 5 | Full v0.1 core | 8 lanes, 4 SIMD-groups, scheduler, mask stack, threadgroup memory, barrier, CSR, dispatcher | lint, RDC-lite |
| 6 | UVM testbench | Env, agents, scoreboard, tests T1–T16, coverage | simulation, coverage |
| 7 | Synthesis + STA | Yosys on sky130, SDC, timing closed at 50 MHz | synthesis, STA |

## After v0.1 (each one only when we decide we need it)

| Topic | What it teaches | New flow steps |
|---|---|---|
| Pipelining the core | Hazards, forwarding, performance | — |
| FP32 ALU (`FADD`, `FMUL`, `FFMA`) | Floating-point hardware | — |
| Uniform registers | Apple-style scalar values shared by a SIMD-group | — |
| Instruction and data caches, AXI4 | Memory hierarchy, standard SoC bus | — |
| Memory system on its own clock | Async FIFOs, synchronizers | **CDC** |
| Soft reset of the shader core only | Reset domains | **RDC** |
| Power-gating the shader core | Isolation, power sequencing | **UPF** |
| Multiple shader cores | Work distribution, shared L2 | — |
| SIMD-group width 32 | Same as Apple | — |
| TBDR graphics: vertex stage, tiler, rasterizer, hidden-surface removal, tile memory | How Apple GPUs render | — |
