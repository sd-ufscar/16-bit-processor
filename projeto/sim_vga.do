# Renderer e porta de diagnostico da RAM (sem PLL, ModelSim-Altera).
if {![file isdirectory work]} {vlib work}
vmap work work
vlog +define+SIM_BEHAVIORAL scomp.v memory256.v font8.v datapath_renderer.v tb_vga.v
vsim work.tb_vga
add wave -radix hexadecimal sim:/tb_vga/*
run -all
