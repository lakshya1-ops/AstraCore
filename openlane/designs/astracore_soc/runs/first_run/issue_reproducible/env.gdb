set env CARRY_SELECT_ADDER_MAP pdk/sky130A/libs.tech/openlane/sky130_fd_sc_hd/csa_map.v
set env CLOCK_PERIOD 10.0
set env DESIGN_NAME cpu_axi_top
set env FULL_ADDER_MAP pdk/sky130A/libs.tech/openlane/sky130_fd_sc_hd/fa_map.v
set env LIB_SYNTH ./tmp/synthesis/trimmed.lib
set env LIB_SYNTH_COMPLETE pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
set env LIB_SYNTH_COMPLETE_NO_PG ./tmp/synthesis/1-sky130_fd_sc_hd__tt_025C_1v80.no_pg.lib
set env LIB_SYNTH_NO_PG ./tmp/synthesis/1-trimmed.no_pg.lib
set env MAX_FANOUT_CONSTRAINT 6
set env MAX_TRANSITION_CONSTRAINT 0.75
set env OUTPUT_CAP_LOAD 33.442
set env PACKAGED_SCRIPT_0 nix/store/n0wqr3jrpjlfdqdp3gnlpfhn2m0n0mkp-openlane1-1.1.1/bin/scripts/yosys/synth.tcl
set env PACKAGED_SCRIPT_1 ./tmp/synthesis/synthesis.sdc
set env RIPPLE_CARRY_ADDER_MAP pdk/sky130A/libs.tech/openlane/sky130_fd_sc_hd/rca_map.v
set env SAVE_NETLIST ./results/synthesis/cpu_axi_top.v
set env SYNTH_ABC_LEGACY_REFACTOR 0
set env SYNTH_ABC_LEGACY_REWRITE 0
set env SYNTH_ADDER_TYPE YOSYS
set env SYNTH_BUFFERING 1
set env SYNTH_BUFFER_DIRECT_WIRES 1
set env SYNTH_DRIVING_CELL sky130_fd_sc_hd__inv_2
set env SYNTH_EXTRA_MAPPING_FILE 
set env SYNTH_LATCH_MAP pdk/sky130A/libs.tech/openlane/sky130_fd_sc_hd/latch_map.v
set env SYNTH_MIN_BUF_PORT sky130_fd_sc_hd__buf_2 A X
set env SYNTH_NO_FLAT 0
set env SYNTH_SHARE_RESOURCES 1
set env SYNTH_SIZING 0
set env SYNTH_SPLITNETS 1
set env SYNTH_STRATEGY DELAY 0
set env SYNTH_TIEHI_PORT sky130_fd_sc_hd__conb_1 HI
set env SYNTH_TIELO_PORT sky130_fd_sc_hd__conb_1 LO
set env TRISTATE_BUFFER_MAP pdk/sky130A/libs.tech/openlane/sky130_fd_sc_hd/tribuff_map.v
set env VERILOG_FILES openlane/designs/astracore_soc/src/if_id.v openlane/designs/astracore_soc/src/axi_uart_slave.v openlane/designs/astracore_soc/src/comparator.v openlane/designs/astracore_soc/src/hazard_detection.v openlane/designs/astracore_soc/src/dmem.v openlane/designs/astracore_soc/src/mem_wb.v openlane/designs/astracore_soc/src/ex_mem.v openlane/designs/astracore_soc/src/processing_element.v openlane/designs/astracore_soc/src/accelerator_fsm.v openlane/designs/astracore_soc/src/imem.v openlane/designs/astracore_soc/src/address_generator.v openlane/designs/astracore_soc/src/alu.v openlane/designs/astracore_soc/src/accel_regbank.v openlane/designs/astracore_soc/src/carry_save_adder.v openlane/designs/astracore_soc/src/cpu_axi_top.v openlane/designs/astracore_soc/src/pc_next.v openlane/designs/astracore_soc/src/alu_sel_control.v openlane/designs/astracore_soc/src/axi_decoder.v openlane/designs/astracore_soc/src/uart_tx.v openlane/designs/astracore_soc/src/writeback_mux.v openlane/designs/astracore_soc/src/id_ex.v openlane/designs/astracore_soc/src/wallace_multiplier.v openlane/designs/astracore_soc/src/axi_accel_slave.v openlane/designs/astracore_soc/src/axi_dmem_slave.v openlane/designs/astracore_soc/src/forwarding_unit.v openlane/designs/astracore_soc/src/mac_array.v openlane/designs/astracore_soc/src/axi_lite_master_cpu.v openlane/designs/astracore_soc/src/regfile_id.v openlane/designs/astracore_soc/src/cla_adder.v openlane/designs/astracore_soc/src/pc.v openlane/designs/astracore_soc/src/matrix_accelerator_top.v openlane/designs/astracore_soc/src/alu_opB_src_mux.v openlane/designs/astracore_soc/src/main_control.v openlane/designs/astracore_soc/src/decoder.v openlane/designs/astracore_soc/src/matrix_buffer.v openlane/designs/astracore_soc/src/axi_timer_slave.v openlane/designs/astracore_soc/src/next_pc_mux.v openlane/designs/astracore_soc/src/mac_unit.v openlane/designs/astracore_soc/src/imm_gen.v openlane/designs/astracore_soc/src/branch_target_adder.v
set env synth_report_prefix ./reports/synthesis/1-synthesis
set env synthesis_results ./results/synthesis
set env synthesis_tmpfiles ./tmp/synthesis