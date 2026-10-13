"""Authored upper floors, radio portraits and Russian campaign script (v3)."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,math,wave
import numpy as np
OUT=Path(__file__).resolve().parents[1]/'datafiles'
font=ImageFont.truetype('C:/Windows/Fonts/consolab.ttf',10)

def upper(ch):
    im=Image.new('RGB',(960,640),'#121b29');d=ImageDraw.Draw(im);walls=[]
    palettes=[('#3c3944','#47414b','#845971'),('#343046','#41374e','#ad667a'),('#263d45','#304954','#689990'),('#3f3c3e','#4b4745','#ad8970'),('#36434a','#425057','#7caaa3'),('#453940','#514349','#c2938b')]
    c0,c1,trim=palettes[ch]
    for yy in range(70,560,16):
        for xx in range(80,880,16):
            d.rectangle((xx,yy,xx+14,yy+14),fill=c0 if (xx//16+yy//16)%2 else c1)
    def wall(x,y,w,h):
        walls.append([x,y,w,h]);d.rectangle((x+3,y+5,x+w+3,y+h+5),fill='#0b121f')
        d.rectangle((x,y,x+w,y+h),fill='#2e4351');d.rectangle((x,y,x+w,y+2),fill='#819991')
        d.line((x,y,x,y+h),fill='#597c7c',width=2)
    def prop(x,y,w,h,kind):
        walls.append([x,y,w,h]);d.rectangle((x+4,y+5,x+w+4,y+h+5),fill='#141a28')
        if kind=='bed':
            d.rectangle((x,y,x+w,y+h),fill='#776b77');d.rectangle((x+3,y+3,x+w-3,y+15),fill='#ded3b7')
            d.rectangle((x+3,y+19,x+w-3,y+h-3),fill=trim)
            for xx in range(x+7,x+w-4,7):d.line((xx,y+21,xx,y+h-4),fill='#b48492')
        elif kind=='rack':
            d.rectangle((x,y,x+w,y+h),fill='#516570');d.rectangle((x+2,y+2,x+w-2,y+h-2),fill='#253442')
            for yy in range(y+5,y+h-3,8):
                d.rectangle((x+5,yy,x+w-5,yy+4),fill='#45616b');d.point((x+7,yy+1),fill='#9af1d1');d.point((x+w-8,yy+1),fill='#e7949f')
        elif kind=='sofa':
            d.rectangle((x,y,x+w,y+h),fill='#55334b');d.rectangle((x+3,y+3,x+w-3,y+h-4),fill=trim)
            d.line((x+3,y+2,x+w-3,y+2),fill='#dfa0a2')
            for xx in range(x+9,x+w-4,20):d.line((xx,y+6,xx,y+h-5),fill='#684059')
        else:
            d.rectangle((x,y,x+w,y+h),fill='#795955');d.line((x+2,y+2,x+w-2,y+2),fill='#c0947a',width=2)
            d.rectangle((x+8,y+5,x+25,y+18),fill='#152938');d.rectangle((x+10,y+7,x+23,y+15),fill='#5caa9b')
            d.rectangle((x+w-17,y+7,x+w-7,y+15),fill='#d5c9ae');d.line((x+w-15,y+10,x+w-9,y+10),fill='#73616b')
    for a in [(70,60,820,10),(70,60,10,510),(880,60,10,510),(70,560,820,10)]:wall(*a)
    # A lower gallery connects the stairwell and emergency exit. Doorways are
    # wide enough for full actor footprints; different chapters shift partitions.
    split=350 if ch%2==0 else 390
    for a in [(80,420,135,10),(263,420,190,10),(501,420,219,10),(768,420,112,10),
              (split,70,10,145),(split,263,10,157),(620,70,10,145),(620,263,10,157),
              (80,240,110,10),(238,240,split-238,10)]:wall(*a)
    doors=[[215,420,48,10],[453,420,48,10],[720,420,48,10],[split,215,10,48],[620,215,10,48],[190,240,48,10]]
    kind=['bed','sofa','rack','rack','bed','sofa'][ch]
    for xx in [105,250]:prop(xx,96,52,78,kind)
    prop(104,310,98,30,'desk');prop(split+32,102,108,33,'desk')
    prop(split+30,323,112,31,'sofa');prop(650,96,58,80,'rack' if ch in [2,3] else kind)
    prop(781,98,64,77,kind);prop(687,326,123,32,'desk')
    prop(334,474,80,28,'sofa');prop(602,473,96,29,'sofa')
    for xx,yy in [(100,266),(565,375),(848,380)]:
        d.rectangle((xx+5,yy+6,xx+14,yy+16),fill='#9d756d')
        for dx,dy in [(-1,0),(8,-5),(17,1),(3,9),(14,10)]:d.polygon([(xx+9,yy+9),(xx+dx,yy+dy),(xx+dx+3,yy+dy+6)],fill='#658d77')
    for xx in [116,425,688]:
        d.rectangle((xx,73,xx+25,90),fill='#1a1b2a');d.rectangle((xx+2,75,xx+23,88),fill=trim)
        d.ellipse((xx+12,77,xx+20,85),fill='#d3aa95')
    for xx in range(185,842,17):d.line((xx,456,xx+9,456),fill='#7c747b')
    d.text((100,581),'02 / '+['PRIVATE ROOMS','THE BOOTH','MASTER TAPE','MANIFEST','LOST PROPERTY','TRANSMITTER'][ch],font=font,fill='#d6adad')
    d.text((758,537),'FIRE EXIT',font=font,fill='#9cd8bf')
    for xx in [80,310,580,790]:d.rectangle((xx,62,xx+35,64),fill='#dc8cab')
    im.save(OUT/f'upper{ch}.png')
    placements=[[210,480,0],[483,499,1],[742,484,2],[822,281,1],[713,206,0],[527,204,2],[438,375,1],[282,367,0],[121,210,1],[290,204,2],[570,379,0],[838,389,1],[554,126,1]]
    placements=placements[:8+ch]
    return {'walls':walls,'doors':doors,'spawn':[129,518],'exit':[842,524],'stairs':[129,518],
            'enemies':placements,'drops':[[177,520,0],[570,508,1]]}

def portrait(kind):
    sheet=Image.new('RGBA',(72*2,88))
    for frame in range(2):
        im=Image.new('RGBA',(72,88),'#1a2936');d=ImageDraw.Draw(im)
        for yy in range(0,88,8):d.line((0,yy,72,yy),fill='#203443')
        d.ellipse((2,9,67,77),fill=['#6c4c67','#3f6970','#564152'][kind])
        d.polygon([(4,88),(8,67),(23,57),(49,57),(65,71),(70,88)],fill='#0f1827')
        d.polygon([(10,88),(14,69),(28,60),(43,60),(60,72),(65,88)],fill=['#c5b39e','#536f7c','#3b485d'][kind])
        d.rectangle((29,49,43,65),fill='#aa776a')
        if kind==0:
            d.polygon([(18,19),(29,10),(48,13),(56,27),(54,49),(44,59),(27,56),(17,42)],fill='#2b2230')
            d.polygon([(20,23),(31,15),(47,18),(52,28),(49,47),(42,54),(28,50),(21,38)],fill='#eadfc3')
            d.polygon([(22,29),(33,31),(30,36),(23,35)],fill='#392e40');d.polygon([(40,30),(49,27),(48,34),(41,35)],fill='#392e40')
            d.rectangle((34,36,38,41),fill='#aa969b');d.line((28,44,44,45+frame),fill='#513e4c',width=2)
            d.line((24,20,28,17),fill='#fff1d2',width=2);d.line((21,27,20,41),fill='#bba2a6')
            d.line((18,73,28,81),fill='#f08da7',width=3)
        elif kind==1:
            d.polygon([(17,20),(27,10),(46,11),(56,25),(55,61),(43,65),(20,56)],fill='#20212f')
            d.polygon([(25,24),(44,20),(51,29),(47,46),(39,56),(29,52),(23,39)],fill='#d2a38b')
            d.polygon([(20,31),(26,14),(46,14),(53,25),(35,21)],fill='#413443')
            d.line((27,33,32,33),fill='#2d3444',width=2);d.line((41,32,46,32),fill='#2d3444',width=2)
            d.line((33,46,41,46+frame*2),fill='#864b60',width=2)
            d.arc((14,12,58,61),180,350,fill='#8bc8c0',width=3);d.rectangle((15,34,20,48),fill='#658997')
            d.line((19,47,26,53),fill='#a7d3c1',width=2);d.rectangle((25,51,31,54),fill='#182433')
        else:
            d.polygon([(18,27),(23,11),(46,9),(57,28),(53,59),(39,67),(21,53)],fill='#101825')
            d.rectangle((24,30,49,34),fill='#a8778b');d.line((26,31,45,31),fill='#f1a4b7')
            d.line((28,47,44,47+frame),fill='#4d596b',width=2)
            for xx in range(26,48,5):d.line((xx,19,xx+2,21),fill='#343749')
        d.rectangle((1,1,70,86),outline='#7e818f');sheet.paste(im,(72*frame,0))
    sheet.save(OUT/f'portrait{kind}.png')

def line(who,text):return {'who':who,'text':text}
L=line
intros=[
 [L(2,'Не вешай трубку. В мотеле лежит кассета. Второй этаж, комната без номера. Забери её до полуночи.'),L(0,'Кто ты? И почему у тебя мой номер?'),L(2,'Потому что ты уже соглашался. Просто не помнишь.')],
 [L(1,'Я Ника. Ты принёс кассету в мою мастерскую. На ней твой голос, но запись сделана завтра.'),L(0,'Где её записали?'),L(1,'В клубе LOWLIFE. Аппаратная наверху. Найди исходную дорожку.')],
 [L(1,'В клубе монтировали звонки. Голоса, адреса, паузы — всё по сценарию. На коробке штамп CHANNEL 09.'),L(0,'Значит, на радиостанции знают, кто нами управляет.'),L(1,'Поднимись к архиву. И больше не отвечай на телефон.')],
 [L(0,'В архиве десятки кассет. На каждой чей-то последний вечер.'),L(1,'Они перевозят записи через портовый склад. Наверху должна быть накладная с адресом передатчика.'),L(2,'Ты вышел из расписания. Верни кассету.')],
 [L(1,'В накладной прачечная. Подставной адрес, но наверху есть комната хранения. Там я оставила ключ.'),L(0,'Ты была одной из них?'),L(1,'Я соединяла звонки. Пока не услышала в записи собственное имя.')],
 [L(1,'Ключ подходит к пентхаусу. На втором этаже передатчик. Вставь кассету и включи прямой эфир.'),L(2,'Если запись услышит город, ты услышишь её тоже. До конца.'),L(0,'Вот теперь я согласен.')]
]
bridges=[
 [L(0,'На лестнице свежие следы. Кто-то ждал меня здесь.'),L(2,'Кассета наверху. Не задерживайся.')],
 [L(1,'Аппаратная за закрытой дверью. На записи ищи голос без музыки.')],
 [L(0,'Архив на втором этаже. Все плёнки подписаны временем.'),L(1,'Найди ту, где вместо времени стоит адрес.')],
 [L(0,'Грузовая площадка чиста. Поднимаюсь в контору.'),L(1,'Забери накладную. Не открывай ни одной коробки.')],
 [L(1,'Мой шкаф наверху. Ключ в кармане серого пальто.'),L(0,'После этого мы заканчиваем.')],
 [L(2,'Последняя дверь. После неё нельзя будет начать заново.'),L(0,'Тогда хотя бы дослушай.')]
]
ending=[L(0,'В эфир ушёл не приказ. Признание. Мой голос называл имена тех, кто заказывал звонки.'),L(1,'Я слышу. Весь город слышит. Они больше не смогут стереть эту запись.'),L(2,'Абонент недоступен.'),L(0,'Впервые за эту ночь телефон замолчал.')]

if __name__=='__main__':
    levels=json.loads((OUT/'levels.json').read_text(encoding='utf8'))
    doors=[[[220,282,40,10],[450,282,40,10],[710,282,40,10],[220,350,40,10],[450,350,40,10],[710,350,40,10],[375,434,10,44],[650,434,10,44]]] * 3
    doors += [[[310,180,10,50],[310,410,10,50],[590,270,10,50],[415,390,55,10]],
              [[235,360,55,10],[620,360,55,10],[385,255,10,55],[620,445,10,52],[180,205,55,10]],
              [[225,340,50,10],[700,340,55,10],[375,440,10,52],[590,440,10,52],[300,230,10,52],[680,230,10,52],[435,225,55,10]]]
    for ch,lv in enumerate(levels):
        lv['doors']=doors[ch];lv['stairs']=[260,532];lv['upper']=upper(ch)
        for room in [lv,lv['upper']]:
            # Keep authored enemy placements off walls and closed door panels.
            rects=room['walls']+room['doors']
            def blocked(x,y):return any(x+9>w[0] and x-9<w[0]+w[2] and y+9>w[1] and y-9<w[1]+w[3] for w in rects)
            for a in room['enemies']:
                if blocked(a[0],a[1]):
                    offsets=sorted(((dx,dy) for dx in range(-32,33) for dy in range(-32,33)),key=lambda v:v[0]**2+v[1]**2)
                    dx,dy=next(v for v in offsets if not blocked(a[0]+v[0],a[1]+v[1]));a[0]+=dx;a[1]+=dy
    for i in range(3):portrait(i)
    (OUT/'levels.json').write_text(json.dumps(levels),encoding='utf8')
    (OUT/'story.json').write_text(json.dumps({'names':['ЧЕЛОВЕК В МАСКЕ','НИКА / РАДИОТЕХНИК','ГОЛОС НА ЛИНИИ'],'intro':intros,'stairs':bridges,'ending':ending},ensure_ascii=False),encoding='utf8')
    sr=22050;t=np.arange(int(sr*.32))/sr;rng=np.random.default_rng(33)
    signal=(rng.uniform(-1,1,len(t))*.18+np.sin(2*np.pi*80*t)*.3)*np.exp(-t*16)
    signal+=rng.uniform(-1,1,len(t))*.15*np.exp(-abs(t-.23)*110)
    with wave.open(str(OUT/'door.wav'),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(sr);f.writeframes((signal*32767).astype('<i2').tobytes())
    print('Campaign: 6 chapters / 12 floors /',sum(len(l['enemies'])+len(l['upper']['enemies']) for l in levels),'enemies; 3 animated portraits.')
