# Mesmo teste com ALTSYNCRAM. Requer biblioteca altera_mf_ver mapeada.
if {![file isdirectory work]} {vlib work}
vmap work work
vlog scomp.v memory256.v font8.v datapath_renderer.v tb_vga.v
vsim -t 1ps -L altera_mf_ver work.tb_vga
add wave -radix hexadecimal sim:/tb_vga/*
run -all
