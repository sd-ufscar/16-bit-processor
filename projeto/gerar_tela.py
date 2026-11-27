from pathlib import Path
# 40 x 30 tiles de 16 x 16; glyph 8x8 em escala 2.
# Cada tile: ASCII[7:0], campo[12:8], indice[16:13], caminho[20:17].
W,H=40,30
cells=[[(32,0,0,0) for x in range(W)] for y in range(H)]
def put(x,y,s,g=0):
    for i,c in enumerate(s):
        assert 0<=x+i<W and 0<=y<H,(x,y,s)
        cells[y][x+i]=(ord(c),0,0,g)
def field(x,y,n,w,g=0):
    for i in range(w): cells[y][x+i]=(32,n,i,g)
def path(x,y,s,g): put(x,y,s,g)
def box(x,y,w,h):
    put(x,y,'+'+'-'*(w-2)+'+')
    for i in range(1,h-1): put(x,y+i,'|');put(x+w-1,y+i,'|')
    put(x,y+h-1,'+'+'-'*(w-2)+'+')
put(0,0,' UP3 - PROCESSADOR 16 BITS / DE1',10)
put(0,1,' PASSO:');field(7,1,1,4);put(13,1,'ESTADO:');field(20,1,2,12,10)
put(0,2,' ULTIMO:');field(8,2,3,12);put(22,2,'OP:');field(25,2,4,5)
put(0,3,'-'*40)
put(0,4,' CAMINHO DE DADOS');put(25,4,'RAM 256 X 16',10)
# Bus dados à esquerda; barramento AC e endereço à direita.
for y in range(6,27): put(0,y,'|',8)
for y in range(6,25): put(20,y,'|',9);put(23,y,'|',6)
box(3,5,16,3);put(5,6,'IR');field(8,6,5,4);put(13,6,'OP');field(15,6,6,2)
path(1,6,'->',1);path(19,6,'---->',2)
box(3,9,16,5);put(5,10,'B:');field(7,10,8,4);put(12,10,'A:');field(14,10,7,4)
put(5,11,'ULA:');field(10,11,9,4,3);put(5,12,'OUT:');field(10,12,10,4,3)
path(1,10,'->',3);path(19,10,'<',3);path(10,14,'v',3)
box(3,15,16,3);put(5,16,'AC:');field(10,16,7,4);path(1,16,'->',4);path(19,16,'->',5);path(21,16,'--->',5)
box(3,19,16,3);put(5,20,'PC:');field(9,20,11,2);put(12,20,'+1:');field(15,20,12,2);path(19,20,'---->',6)
box(3,22,16,3);put(5,23,'MAR:');field(10,23,13,2);path(19,23,'<----',6)
box(3,25,16,3);put(5,26,'MDR:');field(10,26,14,4);path(1,26,'<-',8)
put(25,5,'END  DADO  USO')
for i,(addr,name) in enumerate(zip([0,1,2,3,4,16,17,18],['LOAD','ADD','STORE','LOAD','JUMP','B','C','A'])):
    y=6+i;put(25,y,f'{addr:02X}:');field(30,y,16+i,4);put(35,y,name)
path(23,14,'->',7);put(25,14,'END RAM:');field(34,14,13,2,7)
put(25,15,'MW:');field(29,15,15,1,5);put(32,15,'NEG:  ');field(38,15,24,1)
put(25,17,'ULT. END RAM:');field(38,17,25,2)
put(25,18,'MDR VALIDO:');field(37,18,26,1)
put(25,19,'OPERANDO IR:');field(38,19,27,2)
put(25,21,'PROXIMA ACAO',10)
field(25,22,28,15,10)
field(25,23,29,15,10)
put(25,25,'AZUL: ATIVO',10)
put(25,26,'VERMELHO: WRITE',5)
put(0,28,'-'*40)
put(0,29,' KEY0 RESET | KEY1 AVANCA UM ESTADO')
# Write 21-bit packed tile map. 2048 words padded to power of two.
words=[c|(f<<8)|(i<<13)|(g<<17) for row in cells for c,f,i,g in row]
words += [32]*(2048-len(words));Path('tela.hex').write_text(''.join(f'{n:06X}\n' for n in words))
# Font 5x7 centered in 8x8; custom bus and arrow glyphs fill tile.
font={
'0':'01110 10001 10011 10101 11001 10001 01110','1':'00100 01100 00100 00100 00100 00100 01110','2':'01110 10001 00001 00010 00100 01000 11111','3':'11110 00001 00001 01110 00001 00001 11110','4':'00010 00110 01010 10010 11111 00010 00010','5':'11111 10000 10000 11110 00001 00001 11110','6':'01110 10000 10000 11110 10001 10001 01110','7':'11111 00001 00010 00100 01000 01000 01000','8':'01110 10001 10001 01110 10001 10001 01110','9':'01110 10001 10001 01111 00001 00001 01110',
'A':'01110 10001 10001 11111 10001 10001 10001','B':'11110 10001 10001 11110 10001 10001 11110','C':'01111 10000 10000 10000 10000 10000 01111','D':'11110 10001 10001 10001 10001 10001 11110','E':'11111 10000 10000 11110 10000 10000 11111','F':'11111 10000 10000 11110 10000 10000 10000','G':'01111 10000 10000 10111 10001 10001 01111','H':'10001 10001 10001 11111 10001 10001 10001','I':'01110 00100 00100 00100 00100 00100 01110','J':'00111 00010 00010 00010 10010 10010 01100','K':'10001 10010 10100 11000 10100 10010 10001','L':'10000 10000 10000 10000 10000 10000 11111','M':'10001 11011 10101 10101 10001 10001 10001','N':'10001 11001 10101 10011 10001 10001 10001','O':'01110 10001 10001 10001 10001 10001 01110','P':'11110 10001 10001 11110 10000 10000 10000','Q':'01110 10001 10001 10001 10101 10010 01101','R':'11110 10001 10001 11110 10100 10010 10001','S':'01111 10000 10000 01110 00001 00001 11110','T':'11111 00100 00100 00100 00100 00100 00100','U':'10001 10001 10001 10001 10001 10001 01110','V':'10001 10001 10001 10001 10001 01010 00100','W':'10001 10001 10001 10101 10101 10101 01010','X':'10001 10001 01010 00100 01010 10001 10001','Y':'10001 10001 01010 00100 00100 00100 00100','Z':'11111 00001 00010 00100 01000 10000 11111',':':'00000 00100 00100 00000 00100 00100 00000','/':'00001 00001 00010 00100 01000 10000 10000','.':'00000 00000 00000 00000 00000 00100 00100','?':'01110 10001 00001 00010 00100 00000 00100'}
bitmaps={ord(k):[int('0'+r+'00',2) for r in v.split()]+[0] for k,v in font.items()}
bitmaps.update({ord('-'):[0,0,0,255,255,0,0,0],ord('|'):[24]*8,ord('+'):[24,24,24,255,255,24,24,24],ord('>'):[0,8,4,254,254,4,8,0],ord('<'):[0,16,32,127,127,32,16,0],ord('v'):[24,24,24,24,90,60,24,0]})
bitmaps.update({ord('['):[28,16,16,16,16,16,28,0],ord(']'):[56,8,8,8,8,8,56,0]})
Path('font8.v').write_text('module font8(input wire [7:0] ch, input wire [2:0] x,y, output wire ink);\nreg [63:0] glyph;\nalways @* begin case(ch)\n'+''.join(f"8'h{k:02X}: glyph=64'h{''.join(f'{b:02X}' for b in v)};\n" for k,v in sorted(bitmaps.items()))+"default: glyph=64'b0;\nendcase end\nassign ink=glyph[63-{y,x}];\nendmodule\n")
# Preview at pending ADD (passo 6), generated using identical tiles and font.
if __name__=='__main__':
    try:
        from PIL import Image
        vals={1:'0006',2:'EXEC ADD',3:'DECODE',4:'ADD',5:'0011',6:'00',7:'AAAA',8:'5555',9:'ADD',10:'FFFF',11:'02',12:'03',13:'02',14:'5555',15:'0',16:'0210',17:'0011',18:'0112',19:'0212',20:'0304',21:'AAAA',22:'5555',23:'0000',24:'1',25:'11',26:'1',27:'11',28:'AC <- AC+MDR',29:'LER PROX. INST'}
        im=Image.new('RGB',(640,480),'white');pix=im.load()
        for y,row in enumerate(cells):
            for x,(c,f,i,g) in enumerate(row):
                if f: c=ord(vals.get(f,'').ljust(16)[i])
                color=(0,0,255) if g in (3,6,7,8,9,10) else (0,0,0)
                for gy,b in enumerate(bitmaps.get(c,[0]*8)):
                    for gx in range(8):
                        if b&(128>>gx):
                            for a in range(2):
                                for d in range(2):pix[x*16+gx*2+a,y*16+gy*2+d]=color
        im.save('preview_ADD.png')
    except ImportError: pass
