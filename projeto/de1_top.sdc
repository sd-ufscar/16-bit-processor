create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
# Entradas assincronas sao sincronizadas no primeiro FF.
set_false_path -from [get_ports {KEY[*] SW[*]}]
# LEDs/displays sao observacao humana, sem requisito de interface sincrona.
set_false_path -to [get_ports {HEX0[*] HEX1[*] HEX2[*] HEX3[*] LEDR[*]}]
