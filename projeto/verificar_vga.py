# Verificacoes independentes: imagem MIF/HEX, pinos, ROM e modelo de estados.
# Nao substitui simulacao RTL, compilacao Quartus ou teste fisico.
from pathlib import Path
import re
m=[int(x,16) for x in Path('program.hex').read_text().split()]
assert len(m)==256
mif=[0]*256
for addr,value in re.findall(r'^\s*([0-9A-F]{2})\s*:\s*([0-9A-F]{4})\s*;',Path('program.mif').read_text(),re.M):mif[int(addr,16)]=int(value,16)
assert m==mif
pins=re.findall(r'set_location_assignment\s+(PIN_\w+)\s+-to\s+(\S+)',Path('de1_top.qsf').read_text())
assert len(set(a for a,b in pins))==len(pins)==len(set(b for a,b in pins))
assert sum(b.startswith('VGA_') for a,b in pins)==14
words=[int(x,16) for x in Path('tela.hex').read_text().split()]
assert len(words)==2048 and max(words)<2**21
for i in range(8):
 for digit in range(4):
  w=words[(6+i)*40+30+digit]
  assert (w>>8)&31==16+i and (w>>13)&15==digit
s=pc=ir=ac=0;q=0
expected={4:0xAAAA,7:0xFFFF,14:0xFFFF,17:0xFFFF}
for k in range(1,18):
 mar=0 if s==0 else ir&255 if s in (2,4,7) else pc
 if s==4: m[mar]=ac
 qnext=m[mar]
 if s==0:s=1
 elif s==1:ir=q;pc=(pc+1)&255;s=2
 elif s==2:s={0:3,1:4,2:6,3:7,4:7 if ac&0x8000 else 8}.get(ir>>8,8)
 elif s==3:ac=(ac+q)&65535;s=1
 elif s==4:s=5
 elif s==5:s=1
 elif s==6:ac=q;s=1
 elif s==7:pc=ir&255;s=1
 else:s=1
 q=qnext
 if k in expected:assert ac==expected[k]
 if k==6:assert (s,ac,q)==(3,0xAAAA,0x5555)
 if k==10:assert m[18]==0xFFFF
 if k==13:assert q==0xFFFF
 if k==17:assert pc==4
 print(f'{k:02} state={s} PC={pc:02X} IR={ir:04X} AC={ac:04X} MDR={q:04X} MEM12={m[18]:04X}')
print('PASS: modelo de referência, MIF/HEX, 14 pinos VGA sem colisões e campos da ROM.')
