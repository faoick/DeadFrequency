/// Persistent equipment purchases and a walkable workshop between contracts.
function buy_item(_item) {
    var prices=[0,350,550,200];
    if(_item<3&&(owned_weapons&(1<<_item))!=0){selected_weapon=_item;shop_message="ОРУЖИЕ ВЫБРАНО ДЛЯ СЛЕДУЮЩЕГО ЗАКАЗА";save_progress();return true;}
    if(_item==3&&armor_ready){shop_message="БРОНЕЖИЛЕТ УЖЕ ПОДГОТОВЛЕН";return false;}
    if(wallet<prices[_item]){shop_message="НЕ ХВАТАЕТ ДЕНЕГ";return false;}
    wallet-=prices[_item];if(_item==3)armor_ready=true;else{owned_weapons|=(1<<_item);selected_weapon=_item;}
    shop_message="ГОТОВО. СНАРЯЖЕНИЕ ЖДЁТ В МАШИНЕ";sound_fx(snd_pickup,.6);save_progress();return true;
}
function enter_hub(_next) {
    load_level(clamp(_next,0,5));hub_next=clamp(_next,0,5);walls=workshop_data.walls;build_wall_buckets();doors=[];panes=[];shards=[];enemies=[];drops=[];
    p.x=480;p.y=393;p.angle=90;camx=160;camy=250;weapon=selected_weapon;ammo=weapon_capacity(weapon);
    state="hub";shop_message="ОРУЖИЕ ОСТАЁТСЯ В АРСЕНАЛЕ. БРОНЯ — НА ОДИН ЗАКАЗ.";save_progress();set_music();
}
function step_hub(_dt) {
    var mx=keyboard_check(ord("D"))-keyboard_check(ord("A")),my=keyboard_check(ord("S"))-keyboard_check(ord("W"));
    if(mx!=0||my!=0){var ang=point_direction(0,0,mx,my);move_actor(p,lengthdir_x(3.6*_dt,ang),lengthdir_y(3.6*_dt,ang));p.angle=turn_to(p.angle,ang,12*_dt);p.frame+=.5*_dt;}else p.frame=0;
    if(keyboard_check_pressed(ord("F"))){
        if(point_distance(p.x,p.y,480,235)<90){state="shop";}
        else if(point_distance(p.x,p.y,480,566)<75)start_chapter(hub_next);
    }
}
function step_arrival(_dt) {
    arrival_timer-=_dt;var t=1-max(0,arrival_timer)/60;
    p.x=lerp(118,room_data.spawn[0],t);p.y=lerp(601,room_data.spawn[1],t);p.angle=90;p.frame+=.5*_dt;
    if(arrival_timer<=0){state="play";p.inv=60;set_music();}
}
function draw_arrival() {
    if(state!="arrival")return;
    var t=sin(pi*clamp(1-arrival_timer/60,0,1));draw_set_colour(col(0xc0b9aa));draw_line_width(120,591,120+18*t,591-8*t,3);
}
function draw_hub_world() {
    draw_sprite(workshop_sprite,0,0,0);
    for(var i=0;i<3;i++)draw_gun(346+i*120,195,0,i);
    draw_sprite_ext(actors[5],0,480,159,1,1,270,c_white,1);draw_actor(p.x,p.y,p.angle,0,p.frame);
    text_at(480,417,"ВЫХОД К МАШИНЕ ↓",font_small,mint,fa_center);
    draw_set_colour(mint);draw_circle(480,565,39+sin(ticks*.06)*2,true);
}
function draw_hub_ui() {
    box(0,0,960,72,ink,.95);text_at(30,16,"МАСТЕРСКАЯ НИКИ / МЕЖДУ ЗАКАЗАМИ",font_ui,cream);
    text_at(30,44,"СЛЕДУЮЩИЙ АДРЕС: "+level_names[hub_next],font_small,mint);text_at(930,23,"$ "+string(wallet),font_ui,pink,fa_right);
    box(0,480,960,60,ink,.95);text_at(30,500,"WASD — ИДТИ     F — ВЗАИМОДЕЙСТВОВАТЬ     ESC — МЕНЮ",font_small,cream);
    if(point_distance(p.x,p.y,480,235)<90)text_at(480,443,"[ F ] ОРУЖИЕ И БРОНЯ",font_ui,mint,fa_center);
    if(point_distance(p.x,p.y,480,566)<75)text_at(480,443,"[ F ] СЕСТЬ В МАШИНУ / НА ЗАКАЗ",font_ui,mint,fa_center);
    if(state!="shop")return;
    box(0,72,960,408,ink,.97);text_at(39,93,"НИКА: ВЫБИРАЙ. ДО РАССВЕТА НЕДОЛГО.",font_ui,cream);
    var names=["9MM","SMG","12G","БРОНЯ"],prices=[0,350,550,200],details=["12 патронов / точность","28 патронов / темп","6 патронов / разброс","+1 попадание / заказ"];
    for(var i=0;i<4;i++){var xx=39+i*230;box(xx,149,215,221,col(0x263644));text_at(xx+16,166,names[i],font_ui,mint);
        if(i<3)draw_sprite_ext(weapon_sprite,i,xx+51,220,3,3,0,c_white,1);else{box(xx+82,209,42,43,col(0x788c7d));box(xx+88,216,30,30,col(0x3d534d));}
        text_at(xx+12,268,details[i],font_small,cream);
        var owned=i<3?(owned_weapons&(1<<i))!=0:armor_ready;
        var label="[ "+string(i+1)+" ] "+(owned?(i==3?"ГОТОВО":(selected_weapon==i?"ВЫБРАНО":"ВЫБРАТЬ")):"$ "+string(prices[i]));
        if(ui_button(xx+10,310,195,label)||keyboard_check_pressed(ord("1")+i))buy_item(i);
    }
    text_at(480,395,shop_message,font_small,pink,fa_center);text_at(480,436,"ESC — ЗАКРЫТЬ ПРИЛАВОК И ВЕРНУТЬСЯ К МАШИНЕ",font_small,muted_col,fa_center);
}
