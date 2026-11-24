# Gerador reproduzivel do esquematico Quartus e dos simbolos BSF.
from pathlib import Path
from collections import Counter

def name(n,w): return n if w==1 or '[' in n else f'{n}[{w-1}..0]'
def txt(t,x,y,sz=10,extra=''):
    return f'(text "{t}" (rect {x} {y} {x+max(12,len(t)*7)} {y+13})(font "Arial" (font_size {sz})){extra})'
def line(a,b,w=1):
    return f'(line (pt {a[0]} {a[1]})(pt {b[0]} {b[1]})'+ ('(line_width 3)' if w>1 else '')+')'
# (port, largura, nome da rede), entrada e saida em ordem de cima para baixo.
modules={
 'clock_control': ([("clock",1,"CLOCK_50"),("key",2,"KEY"),("sw",2,"SW[2..1]")],[("reset",1,"reset"),("enable",1,"enable"),("select_reg",2,"select_reg")]),
 'scomp': ([("clock",1,"CLOCK_50"),("reset",1,"reset"),("enable",1,"enable"),("mdr",16,"mdr")],[("ac",16,"ac"),("ir",16,"ir"),("pc",8,"pc"),("mar",8,"mar"),("mw",1,"mw"),("mem_enable",1,"mem_enable")]),
 'memory256': ([("clock",1,"CLOCK_50"),("mem_enable",1,"mem_enable"),("mw",1,"mw"),("mar",8,"mar"),("ac",16,"ac")],[("mdr",16,"mdr")]),
 'display_interface': ([("ac",16,"ac"),("ir",16,"ir"),("pc",8,"pc"),("mar",8,"mar"),("mw",1,"mw"),("mdr",16,"mdr"),("select_reg",2,"select_reg")],[("HEX0",7,"HEX0"),("HEX1",7,"HEX1"),("HEX2",7,"HEX2"),("HEX3",7,"HEX3"),("LEDR",9,"LEDR")])}
W=256

def symbol(module,inst,x,y):
    inputs,outputs=modules[module]; h=64+32*max(len(inputs),len(outputs));
    a=['(symbol',f'(rect {x} {y} {x+W} {y+h})',txt(module,8,0,10),txt(inst,8,h-15,8)]
    for direction,ports in [('input',inputs),('output',outputs)]:
        for i,(p,w,n) in enumerate(ports):
            s=name(p,w); py=32+32*i; px=0 if direction=='input' else W
            tx=21 if direction=='input' else W-21-len(s)*7
            a+=['(port',f'(pt {px} {py})',f'({direction})',txt(s,0,0,8),txt(s,tx,py-7,8),line((px,py),(16 if px==0 else W-16,py),w),')']
    a+=['(drawing',f'(rectangle (rect 16 16 {W-16} {h-16}))',')',')']
    return '\n'.join(a)

for mod in modules:
    Path(mod+'.bsf').write_text('(header "symbol" (version "1.1"))\n'+symbol(mod,'inst',0,0)+'\n')

b=['(header "graphic" (version "1.4"))']
positions={'clock_control':(384,64),'memory256':(960,64),'scomp':(384,352),'display_interface':(960,352)}
instances={'clock_control':'u_control','memory256':'u_ram','scomp':'u_cpu','display_interface':'u_display'}
for mod,(x,y) in positions.items(): b.append(symbol(mod,instances[mod],x,y))

# Nos nomeados interligam ramos sem cruzamentos. Barramentos com (bus).
def wire(a,c,n,w):
    assert a[0]==c[0] or a[1]==c[1]
    x=min(a[0],c[0]); y=min(a[1],c[1]);
    b.append('(connector\n'+txt(name(n,w),x+4,y-17,8)+'\n'+f'(pt {a[0]} {a[1]})\n(pt {c[0]} {c[1]})\n'+('(bus)\n' if w>1 else '')+')')
def pin(direction,n,w,x,y):
    # x,y: terminal da entrada/saida (coordenada absoluta).
    if direction=='input':
        start=x-168
        a=[f'(pin (input) (rect {start} {y-8} {x} {y+8})',txt('INPUT',125,0,6),txt(name(n,w),5,0,8),'(pt 168 8)','(drawing',line((84,12),(109,12)),line((84,4),(109,4)),line((113,8),(168,8)),line((84,12),(84,4)),line((109,4),(113,8)),line((109,12),(113,8)),')',txt('VCC',128,7,6),')']
    else:
        a=[f'(pin (output) (rect {x} {y-8} {x+176} {y+8})',txt('OUTPUT',1,0,6),txt(name(n,w),90,0,8),'(pt 0 8)','(drawing',line((0,8),(52,8)),line((52,4),(78,4)),line((52,12),(78,12)),line((52,12),(52,4)),line((78,4),(82,8)),line((78,12),(82,8)),')',')']
    b.append('\n'.join(a))

counts=Counter(); drivers=Counter();
# CPU e display: cinco barramentos/sinais ligados por fios continuos.
direct={'ac','ir','pc','mar','mw'}
for mod,(x,y) in positions.items():
    ins,outs=modules[mod]
    for i,(p,w,n) in enumerate(ins):
        yy=y+32+32*i; counts[(n,w)]+=1
        if mod=='clock_control':
            pin('input',n,w,224,yy); wire((224,yy),(x,yy),n,w); drivers[(n,w)]+=1
        elif mod=='display_interface' and n in direct:
            pass # conectado pelo fio que sai do processador
        else: wire((x-144,yy),(x,yy),n,w)
    for i,(p,w,n) in enumerate(outs):
        yy=y+32+32*i; counts[(n,w)]+=1; drivers[(n,w)]+=1
        if mod=='display_interface':
            pin('output',n,w,x+W+144,yy); wire((x+W,yy),(x+W+144,yy),n,w)
        elif mod=='scomp' and n in direct:
            assert positions['display_interface'][1]+32+32*i==yy
            wire((x+W,yy),(positions['display_interface'][0],yy),n,w)
        else: wire((x+W,yy),(x+W+144,yy),n,w)
assert all(v==1 for v in drivers.values()) and set(counts)==set(drivers)
Path('de1_top.bdf').write_text('\n'.join(b)+'\n')
print('BDF gerado: 4 simbolos, 8 pinos fisicos,',sum(1 for x in b if x.startswith('(connector')), 'conectores; redes com driver unico.')
