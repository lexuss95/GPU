# 03 — Instruction Set Architecture (ISA)

## Why this matters

The ISA is the contract between the software (kernels, assembler, reference
model) and the hardware. Once it is fixed, the RTL and the reference model can
be written in parallel and compared against each other.

> **How Apple does it (public info):** Apple's GPU ISA is not documented by
> Apple. Asahi Linux's reverse-engineering shows variable-length instructions,
> 16- and 32-bit register views, *uniform registers* (one value shared by the
> whole SIMD-group), and structured control flow (`if` / `else` / `pop_exec` /
> `jmp_exec_any`). MiniTile uses a much simpler fixed 32-bit format but keeps
> the structured control flow idea.

## Basics

- Every instruction is **32 bits**, stored little-endian at a 4-byte-aligned
  address. PC is a byte address.
- **16 registers** `r0`–`r15`, 32 bits each, one set **per thread**. `r0` is
  always 0.
- Integer only. Arithmetic wraps around (no overflow traps).
- Every instruction runs for all lanes of a SIMD-group; only **active** lanes
  (execution mask bit = 1) write registers or memory.
- Bits marked "0" must be zero; v0.1 hardware ignores them.

## Instruction formats

| Format | [31:26] | [25:22] | [21:18] | [17:14] | [13:0] |
|---|---|---|---|---|---|
| **R** (register) | opcode | rd | rs1 | rs2 | 0 |
| **I** (immediate) | opcode | rd | rs1 | imm18[17:14] | imm18[13:0] |
| **S** (store) | opcode | rs2 (data) | rs1 (base) | imm18[17:14] | imm18[13:0] |
| **B** (compare/branch) | opcode | cond | rs1 | rs2 | off14 |
| **J** (jump) | opcode | off26[25:0] across all lower bits | | | |
| **X** (no operands) | opcode | 0 | 0 | 0 | 0 |

- `imm18`: sign-extended to 32 bits, **except** `ANDI` / `ORI` (zero-extended),
  `SLLI` / `SRLI` (only `imm18[4:0]` used), `LUI` and `S2R` (see below).
- `off14` / `off26`: signed offset **in instructions**.
  Branch target = `PC + 4 × sign_extend(off)` (relative to the branch itself).

## Condition codes (`cond` field of B-format)

| cond | Name | True when |
|---|---|---|
| 0 | `EQ` | rs1 == rs2 |
| 1 | `NE` | rs1 != rs2 |
| 2 | `LT` | rs1 < rs2 (signed) |
| 3 | `GE` | rs1 >= rs2 (signed) |
| 4 | `LTU` | rs1 < rs2 (unsigned) |
| 5 | `GEU` | rs1 >= rs2 (unsigned) |
| 6–15 | — | reserved → illegal instruction |

## Instruction list

### Arithmetic and logic

| Opcode | Mnemonic | Fmt | Operation (per active lane) |
|---|---|---|---|
| 0x01 | `ADD rd, rs1, rs2` | R | rd = rs1 + rs2 |
| 0x02 | `SUB rd, rs1, rs2` | R | rd = rs1 − rs2 |
| 0x03 | `MUL rd, rs1, rs2` | R | rd = low 32 bits of rs1 × rs2 |
| 0x04 | `AND rd, rs1, rs2` | R | rd = rs1 & rs2 |
| 0x05 | `OR rd, rs1, rs2` | R | rd = rs1 \| rs2 |
| 0x06 | `XOR rd, rs1, rs2` | R | rd = rs1 ^ rs2 |
| 0x07 | `SLL rd, rs1, rs2` | R | rd = rs1 << rs2[4:0] |
| 0x08 | `SRL rd, rs1, rs2` | R | rd = rs1 >> rs2[4:0] (logical) |
| 0x09 | `SRA rd, rs1, rs2` | R | rd = rs1 >>> rs2[4:0] (arithmetic) |
| 0x0A | `SLT rd, rs1, rs2` | R | rd = (rs1 < rs2) signed ? 1 : 0 |
| 0x0B | `SLTU rd, rs1, rs2` | R | rd = (rs1 < rs2) unsigned ? 1 : 0 |
| 0x10 | `ADDI rd, rs1, imm` | I | rd = rs1 + sext(imm18) |
| 0x11 | `ANDI rd, rs1, imm` | I | rd = rs1 & zext(imm18) |
| 0x12 | `ORI rd, rs1, imm` | I | rd = rs1 \| zext(imm18) |
| 0x13 | `SLLI rd, rs1, sh` | I | rd = rs1 << imm18[4:0] |
| 0x14 | `SRLI rd, rs1, sh` | I | rd = rs1 >> imm18[4:0] (logical) |
| 0x15 | `LUI rd, imm` | I | rd = imm18 << 14 (rs1 field = 0) |

Loading a full 32-bit constant: `LUI rd, value[31:14]` then `ORI rd, rd, value[13:0]`.

### Memory

| Opcode | Mnemonic | Fmt | Operation (per active lane) |
|---|---|---|---|
| 0x20 | `LDG rd, [rs1 + imm]` | I | rd = global_mem[rs1 + sext(imm18)] |
| 0x21 | `STG rs2, [rs1 + imm]` | S | global_mem[rs1 + sext(imm18)] = rs2 |
| 0x22 | `LDS rd, [rs1 + imm]` | I | rd = threadgroup_mem[rs1 + sext(imm18)] |
| 0x23 | `STS rs2, [rs1 + imm]` | S | threadgroup_mem[rs1 + sext(imm18)] = rs2 |

All accesses are 32-bit words; the address must be a multiple of 4.
Threadgroup addresses must be < 1024.

### Special registers

| Opcode | Mnemonic | Fmt | Operation |
|---|---|---|---|
| 0x28 | `S2R rd, sr` | I | rd = special register number `imm18[3:0]` |

| # | Name | Value | Metal equivalent |
|---|---|---|---|
| 0 | `SR_TID` | thread index in threadgroup = `sg_id × 8 + lane` | `thread_index_in_threadgroup` |
| 1 | `SR_LANE` | lane 0…7 | `thread_index_in_simdgroup` |
| 2 | `SR_SGID` | SIMD-group index in threadgroup 0…3 | `simdgroup_index_in_threadgroup` |
| 3 | `SR_TGID` | threadgroup index in grid | `threadgroup_position_in_grid` |
| 4 | `SR_TGSIZE` | `TG_SIZE` CSR | `threads_per_threadgroup` |
| 5 | `SR_GRIDSIZE` | `GRID_SIZE` CSR | `threadgroups_per_grid` |
| 6 | `SR_GID` | `TGID × TG_SIZE + TID` | `thread_position_in_grid` |
| 7 | `SR_ARGBASE` | `ARG_BASE` CSR | (argument buffer pointer) |
| 8–15 | — | reserved → illegal instruction | |

### Control flow

| Opcode | Mnemonic | Fmt | Operation (whole SIMD-group) |
|---|---|---|---|
| 0x00 | `NOP` | X | nothing |
| 0x30 | `JMP label` | J | PC = PC + 4 × sext(off26) |
| 0x31 | `BANY cond, rs1, rs2, label` | B | if any active lane has `cond` true: PC = PC + 4 × sext(off14) |
| 0x32 | `IF cond, rs1, rs2` | B | push mask; mask = mask & cond (off14 = 0) |
| 0x33 | `ELSE` | X | mask = top & ~mask |
| 0x34 | `ENDIF` | X | mask = pop |
| 0x35 | `BAR` | X | wait for all SIMD-groups of the threadgroup |
| 0x3F | `EXIT` | X | SIMD-group finishes |

Any opcode not listed → **illegal instruction** error.

### Pseudo-instructions (assembler only)

| Pseudo | Expands to |
|---|---|
| `MOV rd, rs` | `ADD rd, rs, r0` |
| `LI rd, imm` (fits in 18 bits signed) | `ADDI rd, r0, imm` |
| `LI rd, imm` (32-bit) | `LUI rd, imm[31:14]` + `ORI rd, rd, imm[13:0]` |

## Encoding example

`ADD r3, r1, r2` → opcode 0x01, rd 3, rs1 1, rs2 2:

```
 31    26 25  22 21  18 17  14 13           0
 000001   0011   0001   0010   00000000000000   = 0x04C4_8000
```

## Kernel calling convention

- The host writes an **argument buffer** in memory and puts its address in
  `ARG_BASE`. The kernel reads it with `S2R rX, SR_ARGBASE` and `LDG`.
- The layout of the argument buffer is defined by each kernel (like a C struct
  of 32-bit fields).

## Example 1: vector add `C[i] = A[i] + B[i]`

Argument buffer: `+0` = address of A, `+4` = address of B, `+8` = address of C,
`+12` = N.

```asm
        S2R   r1, SR_GID          ; i = global thread index
        S2R   r2, SR_ARGBASE
        LDG   r3, [r2 + 0]        ; A
        LDG   r4, [r2 + 4]        ; B
        LDG   r5, [r2 + 8]        ; C
        LDG   r6, [r2 + 12]       ; N
        IF    LT, r1, r6          ; only threads with i < N
          SLLI  r7, r1, 2         ; byte offset = i * 4
          ADD   r8, r3, r7
          LDG   r9, [r8 + 0]      ; A[i]
          ADD   r8, r4, r7
          LDG   r10, [r8 + 0]     ; B[i]
          ADD   r11, r9, r10
          ADD   r8, r5, r7
          STG   r11, [r8 + 0]     ; C[i] = A[i] + B[i]
        ENDIF
        EXIT
```

Note: every lane loads the same argument words. Apple GPUs avoid that waste
with *uniform registers*; that is a good later optimization.

## Example 2: a loop with divergence

Each thread *i* computes `1 + 2 + … + i` — different threads run the loop a
different number of times.

```asm
        S2R   r1, SR_GID          ; n = i
        ADDI  r2, r0, 0           ; k = 0
        ADDI  r3, r0, 0           ; sum = 0
loop:   IF    LT, r2, r1          ; lanes that still have work
          ADDI  r2, r2, 1         ; k++
          ADD   r3, r3, r2        ; sum += k
        ENDIF
        BANY  LT, r2, r1, loop    ; repeat while any lane has k < n
        ; ... store r3 ...
        EXIT
```

## Example 3: threadgroup memory and barrier

Reverse the values inside each threadgroup.

```asm
        S2R   r1, SR_TID
        ; ... r3 = input value of this thread ...
        SLLI  r4, r1, 2
        STS   r3, [r4 + 0]        ; tgmem[tid] = value
        BAR                       ; wait until every thread has written
        S2R   r5, SR_TGSIZE
        SUB   r6, r5, r1
        ADDI  r6, r6, -1          ; j = TG_SIZE - 1 - tid
        SLLI  r6, r6, 2
        LDS   r7, [r6 + 0]        ; value of thread j
        ; ... store r7 ...
        EXIT
```

## Open questions

- Byte / half-word loads and stores? Not needed for v0.1 kernels.
- FP32 instructions (`FADD`, `FMUL`, `FFMA`, …): planned, opcode range 0x40+
  would need a wider opcode field or reuse of free codes 0x16–0x1F.
