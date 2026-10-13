// MiniTile GPU - shared parameters and types.
// Single source of truth for RTL: every value here comes from docs/spec
// (00_overview.md key parameters, 03_isa.md, 04_interfaces.md).
package gpu_pkg;

  // ---------------------------------------------------------------------------
  // Key parameters (00_overview.md)
  // ---------------------------------------------------------------------------
  localparam int unsigned XLEN = 32;  // data and address width
  localparam int unsigned NUM_LANES = 8;  // threads per SIMD-group
  localparam int unsigned NUM_SG = 4;  // SIMD-group slots per core
  localparam int unsigned MAX_TG_SIZE = NUM_SG * NUM_LANES;  // 32
  localparam int unsigned NUM_REGS = 16;  // registers per thread
  localparam int unsigned TGM_BYTES = 1024;  // threadgroup memory
  localparam int unsigned MASK_STACK_DEPTH = 4;  // max IF nesting

  localparam int unsigned REG_IDX_W = $clog2(NUM_REGS);  // 4
  localparam int unsigned LANE_W = $clog2(NUM_LANES);  // 3
  localparam int unsigned SG_W = $clog2(NUM_SG);  // 2

  typedef logic [XLEN-1:0] word_t;
  typedef logic [NUM_LANES-1:0] lane_mask_t;
  typedef logic [REG_IDX_W-1:0] reg_idx_t;

  // ---------------------------------------------------------------------------
  // ISA (03_isa.md)
  // ---------------------------------------------------------------------------
  typedef enum logic [5:0] {
    OP_NOP   = 6'h00,
    OP_ADD   = 6'h01,
    OP_SUB   = 6'h02,
    OP_MUL   = 6'h03,
    OP_AND   = 6'h04,
    OP_OR    = 6'h05,
    OP_XOR   = 6'h06,
    OP_SLL   = 6'h07,
    OP_SRL   = 6'h08,
    OP_SRA   = 6'h09,
    OP_SLT   = 6'h0A,
    OP_SLTU  = 6'h0B,
    OP_ADDI  = 6'h10,
    OP_ANDI  = 6'h11,
    OP_ORI   = 6'h12,
    OP_SLLI  = 6'h13,
    OP_SRLI  = 6'h14,
    OP_LUI   = 6'h15,
    OP_LDG   = 6'h20,
    OP_STG   = 6'h21,
    OP_LDS   = 6'h22,
    OP_STS   = 6'h23,
    OP_S2R   = 6'h28,
    OP_JMP   = 6'h30,
    OP_BANY  = 6'h31,
    OP_IF    = 6'h32,
    OP_ELSE  = 6'h33,
    OP_ENDIF = 6'h34,
    OP_BAR   = 6'h35,
    OP_EXIT  = 6'h3F
  } opcode_e;

  typedef enum logic [3:0] {
    COND_EQ  = 4'd0,
    COND_NE  = 4'd1,
    COND_LT  = 4'd2,
    COND_GE  = 4'd3,
    COND_LTU = 4'd4,
    COND_GEU = 4'd5
  } cond_e;

  typedef enum logic [3:0] {
    SR_TID      = 4'd0,
    SR_LANE     = 4'd1,
    SR_SGID     = 4'd2,
    SR_TGID     = 4'd3,
    SR_TGSIZE   = 4'd4,
    SR_GRIDSIZE = 4'd5,
    SR_GID      = 4'd6,
    SR_ARGBASE  = 4'd7
  } sreg_e;

  // ---------------------------------------------------------------------------
  // CSRs (04_interfaces.md)
  // ---------------------------------------------------------------------------
  localparam int unsigned CSR_ADDR_W = 8;

  localparam logic [CSR_ADDR_W-1:0] CSR_ID = 8'h00;
  localparam logic [CSR_ADDR_W-1:0] CSR_VERSION = 8'h04;
  localparam logic [CSR_ADDR_W-1:0] CSR_CTRL = 8'h08;
  localparam logic [CSR_ADDR_W-1:0] CSR_STATUS = 8'h0C;
  localparam logic [CSR_ADDR_W-1:0] CSR_KERNEL_PC = 8'h10;
  localparam logic [CSR_ADDR_W-1:0] CSR_ARG_BASE = 8'h14;
  localparam logic [CSR_ADDR_W-1:0] CSR_GRID_SIZE = 8'h18;
  localparam logic [CSR_ADDR_W-1:0] CSR_TG_SIZE = 8'h1C;
  localparam logic [CSR_ADDR_W-1:0] CSR_IRQ_EN = 8'h20;
  localparam logic [CSR_ADDR_W-1:0] CSR_IRQ_STATUS = 8'h24;
  localparam logic [CSR_ADDR_W-1:0] CSR_ERR_PC = 8'h28;

  localparam word_t GPU_ID = 32'h4D54_4731;  // "MTG1"
  localparam word_t GPU_VERSION = 32'h0000_0001;  // spec v0.1

  typedef enum logic [3:0] {
    ERR_NONE       = 4'd0,
    ERR_ILLEGAL    = 4'd1,  // illegal opcode, cond or special register
    ERR_MISALIGNED = 4'd2,  // misaligned address or KERNEL_PC
    ERR_TGM_RANGE  = 4'd3,  // threadgroup memory address >= TGM_BYTES
    ERR_MASK_STACK = 4'd4,  // mask stack overflow or underflow
    ERR_BAD_CONFIG = 4'd5   // TG_SIZE 0 or > MAX_TG_SIZE, GRID_SIZE 0
  } err_code_e;

endpackage : gpu_pkg
