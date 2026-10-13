"""Authored v4 layouts. Run after the original expansion + campaign generators."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, math
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'datafiles'
levels=json.loads((OUT/'levels.json').read_text('utf8'))
font=ImageFont.truetype('C:/Windows/Fonts/consolab.ttf',12)
def overlaps(a,b):
    return a[0]<b[0]+b[2] and a[0]+a[2]>b[0] and a[1]<b[1]+b[3] and a[1]+a[3]>b[1]
def floor_patch(d,r):
    x,y,w,h=r
    d.rectangle((x,y,x+w,y+h),fill='#3c3d48')
    for yy in range(y,y+h,8): d.line((x,yy,x+w,yy),fill='#444550')
def pane(room,d,r):
    for w in list(room['walls']):
        if w[1]==r[1] and w[3]==r[3] and w[0]<=r[0] and w[0]+w[2]>=r[0]+r[2]:
            room['walls'].remove(w)
            if r[0]>w[0]:room['walls'].append([w[0],w[1],r[0]-w[0],w[3]])
            if r[0]+r[2]<w[0]+w[2]:room['walls'].append([r[0]+r[2],w[1],w[0]+w[2]-r[0]-r[2],w[3]])
            floor_patch(d,[r[0],r[1],r[2],r[3]+6]);room['glass'].append(r);return
    raise ValueError(('No wall for glass',r))
for ch,base in enumerate(levels):
    if base.get('revision')==4:continue
    base['revision']=4;base['spawn']=[129,586];base['stairs']=[842,252]
    for fl,room in enumerate([base,base['upper']]):
        name=f'level{ch}' if fl==0 else f'upper{ch}'
        im=Image.open(OUT/(name+'.png')).convert('RGB');d=ImageDraw.Draw(im);room['glass']=[]
        if fl==0:
            for w in list(room['walls']):
                if w[2]>10 and w[3]>10 and overlaps(w,[808,216,68,65]):
                    room['walls'].remove(w);floor_patch(d,[w[0],w[1],w[2]+5,w[3]+6])
            floor_patch(d,[817,229,50,48])
            room['enemies'].append([827,253,3])
            cut=[[142,350,48,10],[142,350,48,10],[142,350,48,10],[333,390,48,10],[400,360,48,10],[135,340,48,10]][ch]
            pane(room,d,cut)
            d.text((792,204),'SECURITY / 02',font=font,fill='#eab698')
        else:
            for w in [[80,448,120,10],[190,458,10,26],[190,532,10,28]]:
                room['walls'].append(w);x,y,ww,hh=w
                d.rectangle((x+3,y+5,x+ww+3,y+hh+5),fill='#131c2b')
                d.rectangle((x,y,x+ww,y+hh),fill='#3d5763');d.line((x,y,x+ww,y),fill='#b4c4b0',width=2)
            room['doors'].append([190,484,10,48]);room['enemies'][0]=[287,367,0]
            pane(room,d,[290,420,48,10])
            d.text((89,462),'LANDING',font=font,fill='#aacbbb')
        im.save(OUT/(name+'.png'))
(OUT/'levels.json').write_text(json.dumps(levels,ensure_ascii=False),encoding='utf8')
# Heavy silhouette: broad tactical vest, bare arms, brass knuckles, bald head.
sheet=Image.new('RGBA',(320,40))
for f in range(8):
    im=Image.new('RGBA',(40,40));d=ImageDraw.Draw(im);stride=round(math.sin(f*math.pi/4)*3)
    d.rectangle((7+stride,11,18+stride,16),fill='#182330');d.rectangle((7-stride,25,18-stride,30),fill='#182330')
    d.ellipse((12,5,29,35),fill='#172331');d.rectangle((16,8,25,32),fill='#64716a')
    d.rectangle((17,11,23,29),fill='#384840')
    for yy in [12,19,26]:d.rectangle((19,yy,25,yy+3),fill='#8d9378')
    d.ellipse((22,4,31,13),fill='#c99b85');d.ellipse((22,28,31,37),fill='#c99b85')
    d.rectangle((28,8,34,12),fill='#cbb876');d.rectangle((28,29,34,33),fill='#cbb876')
    d.ellipse((22,14,34,26),fill='#4c3d3d');d.ellipse((24,15,35,24),fill='#d6b197')
    d.line((31,16,34,19),fill='#f0d2b0');d.line((31,22,35,22),fill='#644940')
    sheet.paste(im,(40*f,0))
sheet.save(OUT/'actor4.png')
# Nika's blue work jacket and tied hair; an unarmed shopkeeper silhouette.
im=Image.new('RGBA',(40,40));d=ImageDraw.Draw(im)
d.rectangle((10,12,20,17),fill='#172330');d.rectangle((10,24,20,29),fill='#172330')
d.ellipse((14,8,29,32),fill='#354656');d.rectangle((17,11,25,29),fill='#698a94')
d.line((23,12,23,28),fill='#bac0a9');d.ellipse((24,8,32,14),fill='#c29881');d.ellipse((24,26,32,32),fill='#c29881')
d.ellipse((22,14,33,26),fill='#382f34');d.ellipse((27,16,35,24),fill='#d7b296');d.ellipse((18,17,24,23),fill='#493138')
sheet=Image.new('RGBA',(320,40))
for f in range(8):sheet.paste(im,(40*f,0))
sheet.save(OUT/'actor5.png')
# Workshop is an actual traversable room connected to a street and parked car.
im=Image.new('RGB',(960,640),'#162130');d=ImageDraw.Draw(im)
for yy in range(110,470,16):
    for xx in range(230,730,16):d.rectangle((xx,yy,xx+14,yy+14),fill='#3c4850' if (xx+yy)//16%2 else '#46535a')
hubwalls=[[220,100,520,12],[220,100,12,380],[728,100,12,380],[220,470,216,12],[524,470,216,12],[300,180,360,30],[260,265,40,115],[660,265,40,115]]
for x,y,w,h in hubwalls[:5]:
    d.rectangle((x+4,y+5,x+w+4,y+h+5),fill='#0b1522');d.rectangle((x,y,x+w,y+h),fill='#556c71');d.line((x,y,x+w,y),fill='#acbcb0',width=2)
for x in [300,420,540]:
    d.rectangle((x,180,x+119,210),fill='#775a53');d.line((x,181,x+118,181),fill='#c29d7e',width=2)
    d.rectangle((x+8,188,x+109,204),fill='#243944')
for x in [260,660]:
    d.rectangle((x,265,x+40,380),fill='#21303e')
    for yy in range(270,375,22):
        d.line((x+2,yy,x+38,yy),fill='#a0a79a',width=2)
        for xx in range(x+6,x+34,10):d.rectangle((xx,yy+5,xx+6,yy+15),fill='#7d7663')
d.rectangle((432,286,528,354),fill='#957066');d.rectangle((437,291,523,349),outline='#c7aa85',width=2)
d.text((371,126),'NIKA / NIGHT SERVICE',font=font,fill='#9ce5cd')
d.text((360,226),'WEAPONS   /   BODY ARMOR',font=font,fill='#dbb78e')
for yy in range(500,640,32):d.line((200,yy,760,yy),fill='#263344')
d.rectangle((443,550,514,599),fill='#0b1522');d.rounded_rectangle((445,543,512,590),6,fill='#56646b',outline='#c4b4a0',width=2)
d.rectangle((458,548,495,555),fill='#94b6b3');d.rectangle((459,578,495,584),fill='#293949')
d.rectangle((447,544,453,548),fill='#ffdaad');d.rectangle((504,544,510,548),fill='#ffdaad')
im.save(OUT/'workshop.png');(OUT/'workshop.json').write_text(json.dumps({'walls':hubwalls}))
print('v4: six guarded stairwells, six protected landings, twelve glass shortcuts and workshop')
