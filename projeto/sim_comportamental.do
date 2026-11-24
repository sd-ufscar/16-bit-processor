# Alternativa: simula RAM comportamental, sem biblioteca do fabricante.
if {![file isdirectory work]} {vlib work}
vmap work work
vlog +define+SIM_BEHAVIORAL scomp.v memory256.v tb_scomp.v
vsim work.tb_scomp
add wave -radix hexadecimal sim:/tb_scomp/*
add wave sim:/tb_scomp/cpu/state
run -all
