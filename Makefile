# Top-level targets. Run `. .\tools\activate.ps1` first (Windows) or
# have iverilog/vvp/python on PATH (CI/Linux).

SIM_STAGES = 01-hdl-basics 02-golden-models 03-hdmi 06-riscv-soc

# run every simulation testbench in the repo (the full regression)
sim:
	@for d in $(SIM_STAGES); do \
		echo "=== $$d ==="; \
		$(MAKE) -C $$d || exit 1; \
	done

# alias used by CI and pre-release checks
smoke: sim

vectors:
	$(MAKE) -C 02-golden-models vectors

firmware:
	$(MAKE) -C 06-riscv-soc firmware/firmware.hex

clean:
	@for d in $(SIM_STAGES); do $(MAKE) -C $$d clean; done

.PHONY: sim smoke vectors firmware clean
