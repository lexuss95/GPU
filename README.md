# MiniTile GPU

A small GPU, designed from scratch in SystemVerilog as a learning project.
It follows the ideas Apple GPUs use (as far as they are public): unified shader
cores running SIMD-groups, threadgroup memory, structured control flow,
unified memory, and — later — tile-based deferred rendering (TBDR).

The project also runs a realistic front-end chip flow with open-source tools:
compile, elaboration, lint, CDC/RDC, simulation with a UVM testbench,
synthesis and static timing analysis, and UPF power intent when the design
needs it.

## Quick start (Ubuntu 24.04)

```sh
tools/install.sh     # apt: verilator, iverilog; .venv: verible, pyslang, yosys, pytest
make check-tools     # print tool versions
make check           # compile, elab, lint, format-check, synth-check, smoke sim
make help            # all targets
```

## Layout

| Directory | Content |
|---|---|
| `rtl/` | SystemVerilog design (`gpu_pkg.sv` holds every spec parameter) |
| `tb/` | Smoke test now, UVM testbench later |
| `model/`, `kernels/` | Python reference model, assembler, example kernels (next) |
| `lint/`, `syn/` | Lint rules and waivers, Yosys scripts |
| `tools/` | Install and helper scripts |
| `docs/spec/` | Specification |

## Status

| Iteration | State |
|---|---|
| 1. Specification v0.1 | Done: [docs/spec](docs/spec/00_overview.md) |
| 2. Repo skeleton + tools | Done: `make check` passes, CI runs it on every push |
| 3. Reference model + assembler | Next |

See the [roadmap](docs/spec/07_roadmap.md).

## Specification

1. [Overview](docs/spec/00_overview.md): goals, key parameters, glossary
2. [Architecture](docs/spec/01_architecture.md)
3. [Shader core](docs/spec/02_shader_core.md)
4. [Instruction set](docs/spec/03_isa.md)
5. [Interfaces, registers, clock and reset](docs/spec/04_interfaces.md)
6. [Design flow and sign-off](docs/spec/05_design_flow.md)
7. [Verification plan](docs/spec/06_verification_plan.md)
8. [Roadmap](docs/spec/07_roadmap.md)
