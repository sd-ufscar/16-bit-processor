# Teste da interface manual usando RAM comportamental.
if {![file isdirectory work]} {vlib work}
vmap work work
vlog +define+SIM_BEHAVIORAL clock_control.v scomp.v memory256.v tb_manual.v
vsim work.tb_manual
add wave -radix hexadecimal sim:/tb_manual/*
add wave sim:/tb_manual/cpu/state
run -all
