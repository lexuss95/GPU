# MiniTile GPU - flow entry points. Run `make help`.
SHELL := /bin/bash
VENV  := .venv/bin
export PATH := $(CURDIR)/$(VENV):$(PATH)

TOP      := gpu_top
FILELIST := rtl/files.f
RTL      := $(shell grep -v '^//' $(FILELIST))
BUILD    := build
TB       := tb/smoke/tb_smoke.sv

VERILATOR_LINT := verilator --lint-only -Wall --timing lint/waivers.vlt

.PHONY: help install check-tools compile elab lint format format-check synth-check sim check clean

help: ## Show this help
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-14s %s\n", $$1, $$2}'

install: ## Install tools (apt + .venv)
	tools/install.sh

check-tools: ## Show tool versions, fail if one is missing
	tools/check_tools.sh

compile: ## Compile RTL with Verilator and Icarus
	@mkdir -p $(BUILD)
	verilator --cc -Wno-fatal --top-module $(TOP) -Mdir $(BUILD)/vl_compile $(RTL)
	iverilog -g2012 -s $(TOP) -o $(BUILD)/$(TOP).vvp $(RTL)
	@echo "compile: PASS"

elab: ## Strict elaboration with slang (warnings are errors)
	python tools/elab.py -f $(FILELIST) --top $(TOP)

lint: ## Verilator -Wall + Verible lint (0 warnings allowed)
	$(VERILATOR_LINT) --top-module $(TOP) $(RTL)
	verible-verilog-lint --rules_config lint/verible.rules $(RTL)
	@echo "lint: PASS"

format: ## Reformat RTL and testbench in place with Verible
	verible-verilog-format --flagfile=lint/verible.format --inplace $(RTL) $(TB)

format-check: ## Fail if any file is not formatted
	@for f in $(RTL) $(TB); do verible-verilog-format --flagfile=lint/verible.format --verify $$f >/dev/null \
	  || { echo "not formatted: $$f (run make format)"; exit 1; }; done
	@echo "format-check: PASS"

synth-check: ## Generic Yosys synthesis: synthesizable, no latches
	@mkdir -p $(BUILD)
	yowasp-yosys -q -l $(BUILD)/synth_check.log -p "read_slang -j 1 $(RTL) --top $(TOP); script syn/synth_check.ys"
	@echo "synth-check: PASS (report: $(BUILD)/synth_check.log)"

sim: ## Run the smoke test with Verilator
	@mkdir -p $(BUILD)
	verilator --binary --timing -Wno-lint -Wno-style --top-module tb_smoke -Mdir $(BUILD)/tb_smoke \
	  -o tb_smoke $(RTL) tb/smoke/tb_smoke.sv >$(BUILD)/tb_smoke_build.log
	$(BUILD)/tb_smoke/tb_smoke | tee $(BUILD)/tb_smoke.log
	@grep -q '^PASS' $(BUILD)/tb_smoke.log

check: compile elab lint format-check synth-check sim ## Run the whole regression
	@echo "check: ALL PASS"

clean: ## Remove build outputs
	rm -rf $(BUILD) obj_dir
