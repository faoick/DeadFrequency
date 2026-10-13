"""Version 2: authored pixel silhouettes and three distinct floor plans."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, math, random
from collections import deque

OUT=Path(__file__).resolve().parents[1]/'datafiles'
rng=random.Random(490)
font=ImageFont.truetype('C:/Windows/Fonts/consolab.ttf',10)
INK='#0c1320'

def characters():
    for kind in range(4):
        sheet=Image.new('RGBA',(320,40))
        main,light,dark=[('#cbbca9','#fff0d0','#88667d'),('#bf805d','#edb58b','#724247'),('#914b69','#d9838b','#503348'),('#467f85','#8cbbac','#2b475e')][kind]
        for frame in range(8):
            im=Image.new('RGBA',(40,40));d=ImageDraw.Draw(im)
            step=round(math.sin(frame*math.pi/4)*3)
            for yy,off in [(13,step),(25,-step)]:
                d.rectangle((11+off,yy-2,21+off,yy+2),fill=INK)
                d.rectangle((13+off,yy-1,19+off,yy+1),fill='#474659')
                d.line((12+off,yy+2,15+off,yy+2),fill='#879093')
            d.polygon([(15,10),(23,10),(27,14),(27,25),(23,29),(15,28),(13,24),(13,14)],fill=INK)
            d.polygon([(16,11),(22,11),(25,14),(25,25),(22,28),(16,27),(14,23),(14,15)],fill=dark)
            d.rectangle((18,12,23,27),fill=main)
            d.line((19,12,23,12),fill=light,width=2)
            d.line((16,13,16,24),fill=main)
            d.rectangle((16,26,23,27),fill='#353348')
            # Sleeves, seams, bare hands, watch; the weapon is a separate sprite.
            d.rectangle((21,10,28,14),fill=INK);d.rectangle((22,11,27,13),fill=main)
            d.rectangle((21,25,29,29),fill=INK);d.rectangle((22,26,28,28),fill=dark)
            d.rectangle((27,13,30,16),fill='#e1b698');d.rectangle((28,23,31,26),fill='#d19b83')
            d.point((28,25),fill='#c5d7ce')
            d.ellipse((18,14,28,25),fill=INK)
            if kind==0:
                d.polygon([(20,14),(26,15),(29,18),(29,22),(25,25),(20,23),(19,18)],fill='#eee4ca')
                d.line((20,15,23,14),fill='#fff7e5');d.rectangle((26,17,29,18),fill='#473748')
                d.rectangle((26,21,29,22),fill='#473748');d.point((29,20),fill='#ec7191')
                d.rectangle((18,17,20,22),fill='#a99aa5')
                d.line((14,15,14,23),fill='#e37b99')
            elif kind==1:
                d.ellipse((19,15,27,24),fill='#604239');d.rectangle((24,17,29,22),fill='#dba887')
                d.line((26,17,29,17),fill='#f3c399');d.rectangle((26,21,29,23),fill='#76504a')
            elif kind==2:
                d.ellipse((19,14,28,24),fill='#292433');d.rectangle((25,17,29,23),fill='#c78e77')
                d.rectangle((26,17,29,18),fill='#111e2b');d.point((29,18),fill='#86ddd0')
                d.line((20,15,25,15),fill='#655265')
            else:
                d.ellipse((18,14,28,25),fill='#2b3c4a');d.ellipse((19,14,27,22),fill='#647e83')
                d.rectangle((25,17,29,22),fill='#162e3b');d.line((26,17,29,17),fill='#a1d5c7')
                d.line((21,14,24,14),fill='#b7c4b1')
            sheet.paste(im,(frame*40,0))
        sheet.save(OUT/f'actor{kind}.png')

def weapons():
    sheet=Image.new('RGBA',(32*4,16))
    for k in range(4):
        im=Image.new('RGBA',(32,16));d=ImageDraw.Draw(im)
        if k==0:
            d.rectangle((7,5,21,9),fill=INK);d.rectangle((10,8,14,13),fill=INK)
            d.rectangle((9,5,21,7),fill='#d1d7c3');d.line((10,5,19,5),fill='#fff0d6')
            d.rectangle((11,9,13,12),fill='#927261');d.point((19,4),fill='#ed8ba6')
        elif k==1:
            d.rectangle((3,5,28,10),fill=INK);d.rectangle((11,9,16,15),fill=INK)
            d.rectangle((7,5,22,8),fill='#748c92');d.rectangle((22,6,29,7),fill='#c9d7c4')
            d.line((8,5,22,5),fill='#b6d2c6');d.rectangle((12,10,15,14),fill='#596276')
            d.rectangle((3,7,7,9),fill='#897989');d.rectangle((16,6,18,7),fill='#82dfcc')
        elif k==2:
            d.polygon([(1,7),(8,5),(12,5),(12,10),(5,12),(1,12)],fill=INK)
            d.polygon([(2,8),(8,6),(11,6),(11,9),(4,11),(2,11)],fill='#bb8668')
            d.rectangle((10,5,30,9),fill=INK);d.rectangle((11,5,29,6),fill='#e0b980')
            d.rectangle((11,8,29,9),fill='#84999a');d.rectangle((15,7,21,10),fill='#886048')
            for xx in range(15,22,2):d.line((xx,7,xx,9),fill='#d6a575')
        else:
            d.rectangle((6,7,13,10),fill='#995d64');d.line((13,5,13,12),fill='#adbbb2')
            d.polygon([(14,6),(28,7),(23,10),(14,10)],fill='#d3ece0');d.line((15,10,23,10),fill='#7ba4ac')
        sheet.paste(im,(k*32,0))
    sheet.save(OUT/'weapons.png')
    sheet=Image.new('RGBA',(32*8,32))
    for f in range(8):
        im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
        for j in range(20):
            a=rng.random()*math.tau;dist=rng.random()*12;xx=16+math.cos(a)*dist;yy=16+math.sin(a)*dist
            rad=rng.choice([1,1,2,3,5]);d.ellipse((xx-rad,yy-rad*.7,xx+rad,yy+rad*.7),fill='white')
        sheet.paste(im,(32*f,0))
    sheet.save(OUT/'blood.png')

def new_level(idx):
    im=Image.new('RGB',(960,640),'#121a26');d=ImageDraw.Draw(im);walls=[]
    colors=[('#343d46','#39424a','#71918d'),('#39404b','#424857','#9b9a9a'),('#433944','#4b4148','#c2968b')][idx-3]
    for yy in range(70,560,16):
        for xx in range(80,880,16):
            d.rectangle((xx,yy,xx+14,yy+14),fill=colors[(xx//16+yy//16)%2])
            if idx==5:d.line((xx,yy+7,xx+14,yy+7),fill='#342e3b')
    def wall(x,y,w,h):
        walls.append([x,y,w,h]);d.rectangle((x+3,y+5,x+w+3,y+h+5),fill='#09121e')
        d.rectangle((x,y,x+w,y+h),fill='#263b49');d.rectangle((x,y,x+w,y+2),fill=colors[2]);d.line((x,y,x,y+h),fill='#527980',width=2)
    def crate(x,y,w=48,h=40):
        walls.append([x,y,w,h]);d.rectangle((x+4,y+5,x+w+4,y+h+5),fill=INK)
        d.rectangle((x,y,x+w,y+h),fill='#735755');d.rectangle((x+2,y+2,x+w-2,y+h-2),outline='#bc9171',width=2)
        d.line((x+5,y+5,x+w-5,y+h-5),fill='#a07c66',width=3);d.line((x+w-5,y+5,x+5,y+h-5),fill='#4b4147',width=3)
        d.rectangle((x+10,y+8,x+22,y+16),fill='#c9bd9e');d.line((x+12,y+11,x+20,y+11),fill='#58535a')
    def machine(x,y,w=45,h=45):
        walls.append([x,y,w,h]);d.rectangle((x+3,y+4,x+w+3,y+h+4),fill=INK)
        d.rectangle((x,y,x+w,y+h),fill='#52717f');d.rectangle((x+2,y+2,x+w-3,y+h-3),fill='#7b9aa0')
        d.line((x+2,y+1,x+w-2,y+1),fill='#b1c4bb');d.line((x+2,y+2,x+2,y+h-4),fill='#95b4af')
        d.rectangle((x+2,y+2,x+w-2,y+9),fill='#3c5367')
        d.ellipse((x+9,y+15,x+w-9,y+h-5),fill='#18313f');d.ellipse((x+13,y+18,x+w-12,y+h-8),fill='#446979')
        d.arc((x+10,y+16,x+w-10,y+h-6),200,340,fill='#d4d6c1',width=2)
        d.line((x+15,y+19,x+w-14,y+23),fill='#9abaad');d.rectangle((x+w-9,y+4,x+w-5,y+6),fill='#9bdfc6')
        d.rectangle((x+5,y+4,x+11,y+7),fill='#b7b7a8');d.point((x+17,y+6),fill='#e4ac98')
        d.rectangle((x+w-12,y+26,x+w-8,y+30),fill='#c8d3c1')
        for xx in range(x+7,x+w-7,4):d.line((xx,y+h-4,xx+1,y+h-4),fill='#334f62')
    def sofa(x,y,w=90,h=28):
        walls.append([x,y,w,h]);d.rectangle((x+3,y+5,x+w+3,y+h+5),fill=INK)
        d.rectangle((x,y,x+w,y+h),fill='#57364b');d.rectangle((x+3,y+3,x+w-3,y+h-3),fill='#a76378')
        for xx in range(x+8,x+w-5,20):d.line((xx,y+6,xx,y+h-5),fill='#703e5b')
        d.line((x+3,y+2,x+w-3,y+2),fill='#d39499')
    for a in [(70,60,820,10),(70,60,10,510),(880,60,10,510),(70,560,40,10),(150,560,740,10)]:wall(*a)
    if idx==3:
        # Warehouse: wide loading aisle with staggered cover, office and cage.
        for a in [(310,70,10,110),(310,230,10,180),(310,460,10,100),(590,70,10,200),(590,320,10,240),(320,390,95,10),(470,390,120,10)]:wall(*a)
        for x,y in [(105,101),(215,104),(112,270),(220,357),(351,114),(470,213),(364,290),(482,457),(650,110),(779,110),(676,360),(797,458)]:crate(x,y)
        for yy in [195,444]:
            for xx in range(88,874,22):d.line((xx,yy,xx+9,yy),fill='#af926a',width=2)
        places=[[181,486,0],[263,491,1],[179,323,1],[245,208,2],[128,207,0],[397,190,1],[542,128,2],[530,336,1],[378,478,0],[552,521,1],[635,490,2],[813,393,1],[755,283,0],[660,247,1],[837,211,2],[754,507,0]]
        name='HARBOR / STORAGE 04'
    elif idx==4:
        # Laundromat: U-shaped public floor plus service rooms and narrow back door.
        for a in [(80,360,155,10),(290,360,330,10),(675,360,205,10),(385,70,10,185),(385,310,10,50),(620,370,10,75),(620,497,10,63),(80,205,100,10),(235,205,150,10)]:wall(*a)
        for xx in [105,165,225,285]:machine(xx,90)
        for xx in [430,490,550,610,670,730,790]:machine(xx,95)
        for xx in [440,530,620,710]:machine(xx,245,44,54)
        for xx in [106,196,286,396]:sofa(xx,404,62)
        machine(718,414,62,52);machine(799,484,48,45)
        places=[[207,501,0],[350,504,1],[525,489,2],[564,400,0],[706,518,1],[835,397,2],[840,329,1],[661,319,0],[501,324,1],[438,184,2],[581,195,1],[716,190,0],[839,190,1],[331,281,2],[200,311,0],[121,268,1],[321,171,1],[130,167,0]]
        name='AFTER HOURS / LAUNDRY'
    else:
        # Penthouse: central atrium, four suites and a long balcony loop.
        for a in [(80,340,145,10),(275,340,100,10),(375,340,10,100),(375,492,10,68),(590,340,110,10),(755,340,125,10),(590,340,10,100),(590,492,10,68),(300,70,10,160),(300,282,10,58),(680,70,10,160),(680,282,10,58),(310,225,125,10),(490,225,190,10)]:wall(*a)
        for a in [(109,95,120,29),(113,268,100,28),(340,102,105,30),(534,104,105,30),(720,102,111,29),(754,272,85,28),(120,396,130,28),(449,397,85,28),(684,406,144,28)]:sofa(*a)
        for a in [(330,162,38,32),(608,167,38,32),(441,491,85,36),(777,477,44,39)]:crate(*a)
        d.rectangle((420,259,561,323),fill='#493448');d.rectangle((423,262,558,320),outline='#bc807f',width=2)
        for xx in range(435,550,18):d.polygon([(xx,276),(xx+8,287),(xx,300),(xx-8,287)],fill='#75475e')
        places=[[194,496,0],[320,496,1],[307,393,2],[449,458,1],[558,528,0],[695,494,2],[840,529,1],[831,371,0],[713,371,1],[791,199,2],[728,252,0],[635,283,1],[532,291,2],[380,293,0],[252,292,1],[131,208,2],[251,168,0],[389,182,1],[496,153,2],[632,201,1]]
        name='LAST CALL / PENTHOUSE'
    d.text((96,74),name,font=font,fill='#efc4b2')
    d.text((96,540),'EXIT',font=font,fill='#a2e5c7')
    # Small authored wear and fixtures keep the rooms specific without adding noise.
    for xx,yy in [(95,225),(340,79),(600,540),(839,250)]:
        if not any(xx+14>w[0] and xx<w[0]+w[2] and yy+13>w[1] and yy<w[1]+w[3] for w in walls):
            d.rectangle((xx+2,yy+2,xx+13,yy+11),fill='#202632');d.rectangle((xx,yy,xx+10,yy+8),fill='#bbb4a5')
            for oy in [2,4,6]:d.line((xx+2,yy+oy,xx+7,yy+oy),fill='#636574')
    for xx in [160,490,830]:
        d.rectangle((xx,63,xx+30,65),fill='#bdd1c3');d.rectangle((xx,67,xx+30,68),fill='#172f3c')
    if idx==4:
        for xx in [113,242,511,739]:
            d.rectangle((xx,86,xx+6,92),fill='#c1a286');d.rectangle((xx+1,84,xx+5,87),fill='#e9c8a0')
        for xx,yy in [(185,260),(401,451),(742,323)]:
            d.rectangle((xx,yy,xx+11,yy+5),fill='#566c7b');d.line((xx+1,yy+1,xx+9,yy+1),fill='#809795')
    if idx==5:
        for xx,yy in [(90,302),(856,308),(348,521),(606,390)]:
            d.rectangle((xx+3,yy+5,xx+12,yy+14),fill='#a07870')
            for dx,dy in [(-3,-2),(6,-5),(13,-1),(1,5),(12,6)]:
                d.polygon([(xx+7,yy+7),(xx+dx,yy+dy),(xx+dx+3,yy+dy+6)],fill='#638b76')
    for xx,yy in [(84,331),(600,78),(854,537)]:d.rectangle((xx,yy,xx+18,yy+2),fill='#eb86ab')
    for xx in range(180,850,120):
        d.rectangle((xx,575,xx+49,576),fill='#476477');d.rectangle((xx+6,582,xx+33,583),fill='#293e52')
    d.rectangle((83,594,150,620),fill='#5f8c91');d.rectangle((99,597,130,617),fill='#233144');d.rectangle((86,599,91,615),fill='#e69aab');d.rectangle((146,598,150,602),fill='#ffe2aa')
    d.text((550,597),name,font=font,fill='#bd879e')
    im.save(OUT/f'level{idx}.png')
    return {'walls':walls,'spawn':[129,536],'exit':[129,584],'enemies':places}

def blocked(lv,x,y,r=9):
    return any(x+r>w[0] and x-r<w[0]+w[2] and y+r>w[1] and y-r<w[1]+w[3] for w in lv['walls'])

if __name__=='__main__':
    characters();weapons()
    levels=json.loads((OUT/'levels.json').read_text())[:3]
    # Idempotent: migrate the old hardcoded reinforcements to level data.
    for i in [1,2]:
        if len(levels[i]['enemies'])==12:levels[i]['enemies'] += [[542,319,1],[862,485,2]]
    if len(levels[2]['enemies'])==14:levels[2]['enemies'].append([567,146,1])
    levels.extend(new_level(i) for i in range(3,6))
    for lv in levels:
        for a in lv['enemies']:
            if blocked(lv,a[0],a[1]):
                candidates=[(dx,dy) for dx in range(-24,25) for dy in range(-24,25)]
                candidates.sort(key=lambda v:v[0]**2+v[1]**2)
                dx,dy=next(v for v in candidates if not blocked(lv,a[0]+v[0],a[1]+v[1]))
                a[0]+=dx;a[1]+=dy
        lv['drops']=[[174,529,1],[697,521,2]]
        for a in lv['drops']:
            if blocked(lv,a[0],a[1],4):a[0],a[1]=lv['enemies'][-1][:2]
    (OUT/'levels.json').write_text(json.dumps(levels),encoding='utf8')
    print('6 levels /',sum(len(l['enemies']) for l in levels),'enemies; 8-frame actors, 4 weapons, 8 blood brushes.')
