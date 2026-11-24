# ModelSim-Altera: executar a partir da pasta do projeto.
if {![file isdirectory work]} {vlib work}
vmap work work
vlog scomp.v memory256.v tb_scomp.v
vsim -t 1ps -L altera_mf_ver work.tb_scomp
add wave -radix hexadecimal sim:/tb_scomp/*
add wave sim:/tb_scomp/cpu/state
run -all
