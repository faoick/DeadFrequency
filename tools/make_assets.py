"""Original deterministic pixel artwork and synthesizer audio for Dead Frequency."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, math, random, wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'datafiles'
OUT.mkdir(exist_ok=True)
random.seed(91)
INK = '#10121f'
font = ImageFont.truetype('C:/Windows/Fonts/consolab.ttf', 10)
big = ImageFont.truetype('C:/Windows/Fonts/impact.ttf', 32)

def make_level(index):
    im = Image.new('RGB', (960,640), '#111421'); d = ImageDraw.Draw(im)
    walls=[]; props=[]
    def rect(box,c): d.rectangle(box, fill=c)
    def label(pos,text,c='#7a8796',f=font): d.text(pos,text,font=f,fill=c)
    def wall(x,y,w,h):
        walls.append([x,y,w,h]); rect((x+4,y+6,x+w+4,y+h+6),'#090d17')
        rect((x,y,x+w,y+h),'#17212e'); rect((x,y,x+w-1,y+2),'#75908a')
        rect((x,y+3,x+2,y+h),'#49676a'); rect((x+3,y+4,x+w-2,y+h-2),'#304552')
        rect((x,y+h-2,x+w,y+h),'#091420')
    def floor(box,kind):
        x1,y1,x2,y2=box
        cols=[('#253541','#293a47'),('#363040','#3d3446'),('#3b343a','#443c41')][kind]
        rect(box,cols[0])
        for y in range(y1,y2,16):
            for x in range(x1,x2,16):
                rect((x,y,min(x+14,x2),min(y+14,y2)),cols[(x//16+y//16)%2])
                if kind==2: d.line((x,y+7,min(x+14,x2),y+7),fill='#302c35')
        d.rectangle((x1+3,y1+3,x2-3,y2-3),outline='#4a4650')
    def rug(x,y,w,h):
        rect((x,y,x+w,y+h),'#4c2944');d.rectangle((x+3,y+3,x+w-3,y+h-3),outline='#ae5a65',width=2)
        for u in range(x+10,x+w-8,12):
            for v in range(y+10,y+h-8,12): d.polygon([(u,v-3),(u+3,v),(u,v+3),(u-3,v)],fill='#64334f')
    def furniture(x,y,w,h,kind):
        if kind!='plant': props.append([x,y,w,h])
        rect((x+3,y+4,x+w+3,y+h+4),'#121621')
        if kind=='bed':
            rect((x,y,x+w,y+h),'#382c35');rect((x+2,y+3,x+w-2,y+h-2),'#af9ca1')
            rect((x+4,y+4,x+w-4,y+16),'#dbc8bb');rect((x+3,y+22,x+w-3,y+h-4),'#3d6b6a')
            for u in range(x+6,x+w-4,8): d.line((u,y+24,u,y+h-5),fill='#54807a')
            d.line((x+3,y+23,x+w-3,y+23),fill='#7ba094',width=2)
        elif kind=='sofa':
            rect((x,y,x+w,y+h),'#392a3f');rect((x+3,y+3,x+w-3,y+h-3),'#7b3b60')
            rect((x+5,y+6,x+w-5,y+h-6),'#a05276')
            for u in range(x+8,x+w-8,18):d.line((u,y+6,u,y+h-6),fill='#663154')
            d.line((x+2,y+2,x+w-2,y+2),fill='#c07689')
        elif kind=='desk':
            rect((x,y,x+w,y+h),'#25252f');rect((x+2,y+2,x+w-2,y+h-2),'#76544d')
            d.line((x+3,y+3,x+w-3,y+3),fill='#b9836f');rect((x+7,y+6,x+23,y+18),'#171d2b')
            rect((x+9,y+8,x+21,y+15),'#4c9b91');rect((x+w-15,y+6,x+w-6,y+16),'#d3bda5')
        elif kind=='bar':
            rect((x,y,x+w,y+h),'#261d2c');rect((x+2,y+2,x+w-2,y+h-2),'#5f4250')
            d.line((x+2,y+2,x+w-2,y+2),fill='#bb7189',width=2)
            for u in range(x+9,x+w-6,17):rect((u,y+7,u+3,y+15),'#84a78b');rect((u+1,y+4,u+2,y+6),'#b9cfb3')
        elif kind=='server':
            rect((x,y,x+w,y+h),'#101827');rect((x+2,y+2,x+w-2,y+h-2),'#334554')
            for v in range(y+5,y+h-3,7):
                rect((x+4,v,x+w-4,v+4),'#172533');rect((x+6,v+1,x+7,v+2),'#87eac9');rect((x+w-8,v+1,x+w-6,v+2),'#c7776e')
        elif kind=='pool':
            rect((x,y,x+w,y+h),'#644344');rect((x+4,y+4,x+w-4,y+h-4),'#377b70')
            for u,v in [(x+5,y+5),(x+w-5,y+5),(x+5,y+h-5),(x+w-5,y+h-5)]:d.ellipse((u-2,v-2,u+2,v+2),fill=INK)
            d.line((x+12,y+20,x+w-14,y+h-12),fill='#dbbe8a',width=2)
            d.ellipse((x+27,y+16,x+30,y+19),fill='#e7ddbf');d.ellipse((x+44,y+30,x+47,y+33),fill='#d58a43')
        elif kind=='plant':
            rect((x+6,y+9,x+16,y+20),'#917068')
            for a in range(0,360,45):
                dx=math.cos(math.radians(a))*12;dy=math.sin(math.radians(a))*9
                d.polygon([(x+11,y+10),(x+11+dx,y+10+dy),(x+13+dx*.5,y+8+dy*.5)],fill=['#396553','#5b9272'][a%90==0])

    # Asphalt, road markings, storm drains and rain reflections.
    for y in range(0,640,5):
        for x in range(0,960,7):
            if random.random()<.2:rect((x,y,x+2,y),'#1d2231')
    for x in range(80,940,105):rect((x,614,x+48,616),'#5b515c')
    for y in [32,585]:d.line((40,y,920,y),fill='#36404c')
    for x in [46,904]:
        rect((x,360,x+10,390),'#080e18')
        for y in range(363,390,4):d.line((x,y,x+9,y),fill='#45505b')
    floor((80,70,880,560),index)
    floor((80,290,880,350),0)
    rug(97,304,766,29)
    floor((600,70,880,290),0)
    # Door gaps at x 120, 260, 470, 735, and along the spine.
    for a in [(70,60,820,10),(70,60,10,510),(880,60,10,510),
              (70,560,40,10),(150,560,740,10),
              (80,282,140,10),(260,282,190,10),(490,282,220,10),(750,282,130,10),
              (80,350,140,10),(260,350,190,10),(490,350,220,10),(750,350,130,10),
              (350,70,10,212),(590,70,10,212),(375,360,10,74),(375,478,10,82),
              (650,360,10,74),(650,478,10,82)]:wall(*a)
    for x,y in [(220,282),(450,282),(710,282),(220,350),(450,350),(710,350),(110,560)]:
        d.line((x,y+4,x+39,y+4),fill='#d0ab7d',width=2)
        d.line((x+2,y+9,x+35,y+9),fill='#855575')
    if index==0:
        for x in [105,235]:furniture(x,95,52,83,'bed');furniture(x+58,101,28,27,'desk')
        rug(133,208,147,46); furniture(374,92,96,31,'desk');furniture(539,108,28,93,'server')
        furniture(398,196,106,30,'sofa');furniture(682,100,116,35,'bar');furniture(704,189,83,54,'pool')
        furniture(101,389,110,29,'sofa');furniture(297,399,43,87,'desk');rug(111,461,115,57)
        furniture(409,388,66,77,'bed');furniture(526,389,67,77,'bed');furniture(685,392,132,37,'bar')
        furniture(737,487,99,29,'sofa')
    elif index==1:
        furniture(102,92,210,32,'bar');furniture(106,224,70,29,'sofa');furniture(263,224,68,29,'sofa')
        furniture(382,97,164,35,'desk');rug(391,169,156,75)
        for x in [391,519]:furniture(x,205,30,45,'server')
        furniture(636,107,110,30,'sofa');furniture(769,210,81,30,'sofa');furniture(708,181,55,38,'desk')
        for x in range(112,327,24):
            for y in range(403,532,24):rect((x,y,x+20,y+20),['#61405a','#345166','#695c60'][(x//24+y//24)%3])
        furniture(405,384,78,51,'pool');furniture(545,475,75,50,'pool');furniture(692,386,141,33,'bar');furniture(788,469,55,64,'server')
    else:
        for x in [101,177,253]:furniture(x,98,44,88,'server')
        furniture(117,227,176,32,'desk');furniture(381,99,168,37,'desk');furniture(399,220,105,27,'sofa')
        for x in [629,697,765,830]:furniture(x,94,27,99,'server')
        furniture(646,219,178,31,'desk');furniture(105,391,111,34,'desk');furniture(278,472,56,57,'server')
        furniture(408,386,200,38,'desk');furniture(417,492,61,32,'sofa');furniture(548,494,59,32,'sofa')
        furniture(688,386,56,60,'server');furniture(789,389,57,61,'server');furniture(728,501,71,27,'desk')
    for x,y in [(91,252),(320,78),(854,248),(345,529),(849,531),(618,376)]:furniture(x,y,20,22,'plant')
    # Deliberately placed everyday clutter, not noise textures: paper, ashtrays,
    # wall art, vents and foot-worn parquet strips.
    for x,y in [(201,146),(287,251),(454,168),(822,245),(261,408),(509,498),(810,455)]:
        rect((x+2,y+2,x+13,y+11),'#1c2330');rect((x,y,x+10,y+8),'#bcb4a5')
        for v in [y+2,y+4,y+6]:d.line((x+2,v,x+7,v),fill='#6d7681')
    for x,y in [(316,155),(565,238),(833,90),(238,534),(630,510),(673,485)]:
        d.ellipse((x,y,x+8,y+8),fill='#101923');d.ellipse((x+1,y+1,x+6,y+6),fill='#6a7379')
        d.line((x-2,y+3,x+4,y+5),fill='#d4bba1',width=1);d.point((x-2,y+3),fill='#e18577')
    for x,y in [(183,81),(491,80),(791,78),(245,366),(597,366)]:
        rect((x,y,x+24,y+18),'#171a28');rect((x+2,y+2,x+22,y+16),'#8a6b71')
        d.ellipse((x+11,y+4,x+19,y+12),fill='#c69988');d.polygon([(x+3,y+15),(x+9,y+6),(x+18,y+15)],fill='#344d56')
    for x,y in [(320,186),(565,146),(852,203),(350,380)]:
        rect((x,y,x+13,y+28),'#1a2533');rect((x+1,y+1,x+12,y+27),'#4c5c64')
        for v in range(y+4,y+26,4):d.line((x+3,v,x+10,v),fill='#253440')
    for x,y in [(210,273),(440,273),(700,273),(210,360),(440,360),(700,360)]:
        for k in range(5):d.line((x+k*6,y,x+k*6+4,y+3),fill='#786b6e')
    for x,y in [(93,288),(379,288),(602,288),(854,353)]:
        rect((x,y,x+12,y+3),'#202b38');rect((x+3,y+1,x+9,y+2),'#f398b0')
    for x,y in [(175,285),(395,285),(642,285),(820,353)]:rect((x,y,x+27,y+1),'#68d7c8')
    # Wall fixtures, printed floor signage and exterior sign.
    labels=[['01 / ROOMS','02 / OFFICE','03 / LOUNGE'],['01 / BAR','02 / SOUND','03 / VIP'],['01 / RELAYS','02 / CONTROL','03 / SERVERS']][index]
    for x,t in zip([103,380,626],labels):label((x,76),t,'#b5a196')
    label((286,314),'NO VACANCY   /   KEEP MOVING','#c18589')
    label((90,542),'EXIT','#c4e6ce')
    label((694,580),['PALM MOTOR INN','CLUB / LOWLIFE','CHANNEL 09'][index],'#d6a6b2',big)
    # A getaway car at the curb.
    rect((87,591,152,626),'#080e18');rect((83,594,150,620),'#577e84');rect((96,596,136,618),'#92b5af')
    rect((101,598,127,617),'#293649');rect((86,599,92,615),'#cb9ea1');rect((145,598,150,603),'#f2d6a2')
    rect((92,591,106,594),INK);rect((132,591,144,594),INK);rect((92,621,106,624),INK);rect((132,621,144,624),INK)
    im.save(OUT/f'level{index}.png')
    return {'walls':walls+props,'spawn':[129,536],'exit':[129,586],
            'enemies':[[190,458,0],[310,513,1],[438,492,1],[584,526,0],[755,461,2],[826,315,1],[728,245,1],[840,166,0],[516,249,2],[411,152,1],[300,224,0],[179,208,1]]}

levels=[make_level(i) for i in range(3)]
levels[0]['enemies'][6]=[728,261,1]
levels[1]['enemies'][3]=[635,526,0]
levels[1]['enemies'][8]=[499,251,2]
levels[1]['enemies'][10]=[287,192,0]
levels[2]['enemies'][1]=[310,450,1]
levels[2]['enemies'][2]=[438,467,1]
levels[2]['enemies'][3]=[586,467,0]
levels[2]['enemies'][6]=[745,267,1]
levels[2]['enemies'][7]=[817,204,0]
(OUT/'levels.json').write_text(json.dumps(levels),encoding='utf8')

def actor(kind):
    sheet=Image.new('RGBA',(32*4,32))
    for frame in range(4):
        im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
        def r(box,col):d.rectangle(box,fill=col)
        coat=['#cbbab3','#d5c2a0','#ae5770','#5e8f98'][kind]
        shade=['#806c88','#918477','#763751','#355c72'][kind]
        step=[0,2,0,-2][frame]
        r((8-step,8,14-step,12),INK);r((8+step,20,14+step,24),INK)
        r((10-step,9,16-step,11),'#393549');r((10+step,21,16+step,23),'#393549')
        r((11,8,21,24),INK);r((12,9,19,23),shade);r((15,9,22,23),coat)
        r((18,10,25,13),coat);r((18,20,26,23),shade)
        r((23,12,26,14),'#deb196');r((24,19,27,21),'#deb196')
        r((25,14,31,17),'#171e2d');r((26,14,31,14),'#9bb0ad')
        r((16,12,24,20),INK);r((16,12,22,19),'#e6d3ba' if kind==0 else '#3b2c33')
        if kind==0:
            r((22,13,25,18),'#eee3cb');r((21,13,23,14),'#e8708f');r((22,17,24,18),'#353146');r((14,14,16,17),'#9a85a4')
        else:r((21,14,24,18),'#ce9d85');r((23,15,24,16),'#37283b')
        sheet.paste(im,(frame*32,0))
    sheet.save(OUT/f'actor{kind}.png')
for i in range(4):actor(i)

# Smooth falloff light sprite; the scene itself stays crisp at native pixel resolution.
glow=Image.new('RGBA',(128,128));pix=glow.load()
for y in range(128):
    for x in range(128):
        r=math.hypot(x-63.5,y-63.5)/64
        pix[x,y]=(255,255,255,int(max(0,1-r)**2*160))
glow.save(OUT/'glow.png')
vignette=Image.new('RGBA',(320,180));vp=vignette.load()
for y in range(180):
    for x in range(320):
        rad=math.sqrt(((x-160)/190)**2+((y-90)/120)**2)
        vp[x,y]=(6,9,21,int(min(100,max(0,rad-.45)*105)))
vignette.save(OUT/'vignette.png')

# Bespoke title card: vertical motel architecture, telephone cable and sunset disc.
im=Image.new('RGB',(960,540),'#111523');d=ImageDraw.Draw(im)
for y in range(540):d.line((0,y,960,y),fill=(17+int(y*.018),20+int(y*.006),34+int(y*.016)))
d.ellipse((588,46,862,320),fill='#a95773')
for y in range(179,326,12):d.rectangle((560,y,880,y+5),fill='#252238')
for x,y,w,h in [(510,252,90,288),(596,289,133,251),(745,205,180,335),(895,276,65,264)]:
    d.rectangle((x,y,x+w,y+h),fill='#172531');d.rectangle((x,y,x+w,y+6),fill='#385762')
    for u in range(x+10,x+w-10,23):
        for v in range(y+21,520,34):d.rectangle((u,v,u+10,v+15),fill=random.choice(['#2f4754','#a76c78','#557f86']))
d.rectangle((652,86,719,273),fill='#17202c');d.rectangle((655,89,716,270),outline='#f180a0',width=3)
for i,ch in enumerate('MOTEL'):d.text((669,98+i*32),ch,font=big,fill='#f3b0b9')
for x in [483,903]:
    d.polygon([(x,540),(x+5,160),(x+13,161),(x+7,540)],fill='#0a1621')
    for dx,dy in [(-70,-8),(-67,-32),(-36,-51),(15,-55),(56,-35),(72,-4)]:
        d.polygon([(x+8,162),(x+dx,165+dy),(x+dx+10,193+dy),(x+9,170)],fill='#0c1924')
for y in range(476,540,5):d.line((420,y,960,y),fill='#383044')
im.save(OUT/'title.png')

SR=22050
rng=np.random.default_rng(12)
def wav(name,data):
    data=np.clip(data,-.95,.95)
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(SR);f.writeframes((data*32767).astype('<i2').tobytes())
def sfx(name,duration,fn):
    t=np.arange(int(SR*duration))/SR;wav(name,fn(t))
sfx('shot',.20,lambda t:(rng.uniform(-1,1,len(t))*.65+np.sin(2*np.pi*(170*t-250*t*t))*.3)*np.exp(-t*35))
sfx('shotgun',.36,lambda t:(rng.uniform(-1,1,len(t))*.7+np.sin(2*np.pi*65*t)*.3)*np.exp(-t*16))
sfx('hit',.20,lambda t:(rng.uniform(-1,1,len(t))*.38+np.sin(2*np.pi*(90*t-120*t*t))*.5)*np.exp(-t*22))
sfx('dash',.22,lambda t:rng.uniform(-1,1,len(t))*.2*np.sin(np.pi*t/.22)**2)
sfx('reload',.32,lambda t:rng.uniform(-1,1,len(t))*.3*(np.exp(-t*130)+np.exp(-abs(t-.22)*140)))
sfx('pickup',.22,lambda t:np.sin(2*np.pi*np.where(t<.11,660,880)*t)*.2*np.exp(-t*9))
sfx('death',.75,lambda t:(np.sin(2*np.pi*(145*t-70*t*t))*.35+rng.uniform(-1,1,len(t))*.18)*np.exp(-t*5))
sfx('clear',1.1,lambda t:sum(np.sin(2*np.pi*f*t) for f in [220,330,440,554])*.09*np.minimum(1,t*50)*np.exp(-t*3))

# 16-bar 160 BPM loop: sidechained bass, detuned pads, drums and delayed arpeggio.
beat=60/160;length=64*beat;n=int(length*SR);mix=np.zeros(n)
def add(time,signal,gain=1):
    start=int(time*SR); end=min(n,start+len(signal))
    if end>start:mix[start:end]+=signal[:end-start]*gain
def tone(freq,dur,amp=.2,typ='saw'):
    t=np.arange(int(dur*SR))/SR
    sig=(2*((t*freq)%1)-1) if typ=='saw' else np.sin(2*np.pi*freq*t)
    return sig*np.minimum(1,t/.008)*np.minimum(1,(dur-t)/.06)*amp
for b in range(64):
    t=np.arange(int(.25*SR))/SR
    kick=np.sin(2*np.pi*(48*t+8*(1-np.exp(-t*32))))*np.exp(-t*16)*.62
    add(b*beat,kick)
    if b%2==1:add(b*beat,(rng.uniform(-1,1,len(t))*.36+np.sin(2*np.pi*180*t)*.12)*np.exp(-t*22))
    for h in range(2):
        ht=np.arange(int(.08*SR))/SR;add((b+h*.5)*beat,rng.uniform(-1,1,len(ht))*np.exp(-ht*65),.12 if h==1 else .065)
    root=[41,37,44,39][b//16];freq=440*2**((root-69)/12)
    for sub in range(2):add((b+sub*.5)*beat,tone(freq*(2 if sub==1 and b%4==3 else 1),beat*.42,.17))
    note=[0,7,12,15,12,7,10,7][b%8];lead=440*2**((root+24+note-69)/12)
    for delay,gain in [(0,1),(beat*.75,.32),(beat*1.5,.14)]:add(b*beat+delay,tone(lead,beat*.34,.11,'sine'),gain)
    if b%4==0:
        for iv in [0,7,15]:
            f=440*2**((root+12+iv-69)/12);add(b*beat,tone(f,beat*3.9,.024)+tone(f*1.004,beat*3.9,.024))
mix=np.tanh(mix*1.1)*.76
wav('night_drive',mix)
print('Generated 3 environments, 4 animated actors, title artwork, 9 sounds and original music.')

sfx('smg',.12,lambda t:(rng.uniform(-1,1,len(t))*.55+np.sin(2*np.pi*240*t)*.3)*np.exp(-t*55))
import runpy
runpy.run_path(str(ROOT/'tools/make_expansion.py'),run_name='__main__')

runpy.run_path(str(ROOT/'tools/make_campaign.py'),run_name='__main__')
runpy.run_path(str(ROOT/'tools/make_v4.py'),run_name='__main__')
