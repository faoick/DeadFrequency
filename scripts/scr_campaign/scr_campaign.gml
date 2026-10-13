/// Doors, floor checkpoints and radio conversations.
function rect_contains_body(_r,_x,_y,_radius) {
    return _r[2]>0&&_r[3]>0&&_x+_radius>_r[0]+.0001&&_x-_radius<_r[0]+_r[2]-.0001&&_y+_radius>_r[1]+.0001&&_y-_radius<_r[1]+_r[3]-.0001;
}
function door_occupied(_d) {
    var r=[_d.x,_d.y,_d.w,_d.h];
    if(rect_contains_body(r,p.x,p.y,11))return true;
    for(var i=0;i<array_length(enemies);i++)if(enemies[i].alive&&rect_contains_body(r,enemies[i].x,enemies[i].y,11))return true;
    for(var i=0;i<array_length(bodies);i++)if(rect_contains_body(r,bodies[i].x,bodies[i].y,9))return true;
    return false;
}
function door_distance(_d,_x,_y) {return point_distance(_x,_y,clamp(_x,_d.x,_d.x+_d.w),clamp(_y,_d.y,_d.y+_d.h));}
function nearest_door(_x,_y,_range) {
    var result=-1,near=_range;
    for(var i=0;i<array_length(doors);i++){var d=doors[i],dist=door_distance(d,_x,_y);
        if(dist<near&&clear_path(_x,_y,d.x+d.w/2,d.y+d.h/2,0,false)){near=dist;result=i;}
    }
    return result;
}
function set_door(_index,_target,_ox=undefined,_oy=undefined) {
    var d=doors[_index];if(_target==0&&door_occupied(d))return false;
    if(is_undefined(_ox)){_ox=p.x;_oy=p.y;}
    if(_target==1&&d.open==0){d.swing=d.w>d.h?(_oy>d.y?1:-1):(_ox>d.x?-1:1);d.serial++;}
    if(d.target!=_target){d.target=_target;sound_fx(snd_door,.55);}return true;
}
function step_doors(_dt,_immediate_nav=true) {
    for(var i=0;i<array_length(doors);i++){var d=doors[i],old=d.open;
        if(d.open==d.target)continue;
        if(d.target==0&&d.open>0&&door_occupied(d))d.target=1;
        var amount=(d.kick?.19:.075)*_dt;
        // Substep a rotating leaf so a kick cannot tunnel through an actor.
        var count=max(1,ceil(amount/.025));
        for(var n=0;n<count;n++){
            d.open=clamp(d.open+(d.target==1?amount:-amount)/count,0,1);
            if(door_blocks(d,p.x,p.y,9)){d.open=old;if(d.target==0)d.target=1;break;}
            for(var j=0;j<array_length(enemies);j++){var e=enemies[j];if(!e.alive||!door_blocks(d,e.x,e.y,10))continue;
                if(d.target==1&&d.kick&&e.door_serial!=i*10000+d.serial){e.door_serial=i*10000+d.serial;e.stun=e.kind==3?70:100;e.alert=300;e.windup=0;damage_enemy(e,e.kind==3?1:0,point_direction(p.x,p.y,e.x,e.y));}
                var next_open=d.open,ang=(d.w>d.h?0:270)+d.swing*90*d.open+d.swing*90;
                // Push from the previous safe pose before occupying the swept space.
                d.open=old;move_actor(e,lengthdir_x(3,ang),lengthdir_y(3,ang));d.open=next_open;
                if(door_blocks(d,e.x,e.y,9)){d.open=old;break;}
            }
            old=d.open;
        }
        if(d.open==1||d.open==0)d.kick=false;
    }
    if(sync_door_navigation()){if(_immediate_nav)update_flow();else flow_timer=0;}
}
function open_enemy_door(_e) {var di=nearest_door(_e.x,_e.y,30);if(di>=0)set_door(di,1,_e.x,_e.y);}
function draw_doors() {
    for(var i=0;i<array_length(doors);i++){var d=doors[i],horizontal=d.w>d.h;
        var px=d.x+(horizontal?0:d.w/2),py=d.y+(horizontal?d.h/2:0),ang=(horizontal?0:270)+d.swing*90*d.open;
        var ex=px+lengthdir_x(max(d.w,d.h),ang),ey=py+lengthdir_y(max(d.w,d.h),ang);
        draw_set_colour(col(0x0d1724));draw_line_width(px+2,py+3,ex+2,ey+3,9);
        draw_set_colour(col(0x986e65));draw_line_width(px,py,ex,ey,6);
        draw_set_colour(col(0xd8b28e));draw_line_width(px,py-1,ex,ey-1,2);draw_circle(px,py,3,false);
        draw_set_colour(col(0xe5d2a5));draw_circle(lerp(px,ex,.83),lerp(py,ey,.83),2,false);
    }
}
function carry_state() {return {weapon:weapon,ammo:ammo,health:p.health,maxhealth:p.maxhealth,points:run_score,time:elapsed,previous_kills:chapter_kills+kills};}
function restart_floor() {
    if(state=="clear"){start_chapter(level);return;}
    load_level(level,floor_index,floor_checkpoint);
}
function start_chapter(_chapter) {
    var hp=(assist?2:1)+(armor_ready?1:0);armor_ready=false;save_progress();
    load_level(_chapter,0,{weapon:selected_weapon,ammo:weapon_capacity(selected_weapon),health:hp,maxhealth:hp,points:0,time:0,previous_kills:0});
    arrival_timer=60;begin_dialogue(story_data.intro[_chapter],"arrival");
}
function advance_floor() {
    if(state!="play"||floor_index!=0||kills!=total_enemies||point_distance(p.x,p.y,room_data.stairs[0],room_data.stairs[1])>36)return false;
    var saved=carry_state();load_level(level,1,saved);begin_dialogue(story_data.stairs[level],"play");return true;
}
function interact_world() {
    var goal=floor_index==0?room_data.stairs:room_data.exit;
    if(point_distance(p.x,p.y,goal[0],goal[1])<36) {
        if(kills<total_enemies){array_push(floaters,{x:p.x,y:p.y-24,text:"СНАЧАЛА ЗАЧИСТИ ЭТАЖ",life:65});return;}
        if(floor_index==0)advance_floor();else finish_level();return;
    }
    var di=nearest_door(p.x,p.y,36);
    if(di>=0&&!set_door(di,1-doors[di].target))array_push(floaters,{x:p.x,y:p.y-20,text:"ПРОЁМ ЗАНЯТ",life:45});
}
function objective_text() {return kills<total_enemies?("ЭТАЖ "+string(floor_index+1)+" / 2 — ЗАЧИСТИ ЭТАЖ"):(floor_index==0?"ЭТАЖ ЧИСТ. К ЛЕСТНИЦЕ ↑":"ЭТАЖ ЧИСТ. К АВАРИЙНОМУ ВЫХОДУ ↓");}
function draw_floor_markers() {
    var sx=room_data.stairs[0],sy=room_data.stairs[1];
    box(sx-22,sy-21,44,39,col(0x172b38));
    for(var i=0;i<7;i++){var yy=sy+14-i*5;box(sx-19,yy,38,3,col(0x465e69));box(sx-19,yy,38,1,col(0x9aac9e));}
    box(sx-24,sy-23,3,43,col(0xccaa8b));box(sx+22,sy-23,3,43,col(0xccaa8b));
    var goal=floor_index==0?room_data.stairs:room_data.exit;
    if(floor_index==1){box(goal[0]-23,goal[1]-18,46,35,col(0x183b39));box(goal[0]-19,goal[1]-14,38,3,mint);}
    var active=kills==total_enemies;
    text_at(goal[0],goal[1]-38,floor_index==0?"02 ↑":"ВЫХОД ↓",font_small,active?mint:muted_col,fa_center);
    if(active){draw_set_colour(mint);draw_circle(goal[0],goal[1],29+sin(ticks*.06)*2,true);}
}
function begin_dialogue(_lines,_resume) {
    dialogue_lines=_lines;dialogue_index=0;dialogue_chars=0;dialogue_resume=_resume;dialogue_age=0;state="dialogue";set_music();
}
function end_dialogue() {
    state=dialogue_resume;p.inv=max(p.inv,65);fire_timer=max(fire_timer,10);set_music();
}
function next_dialogue() {
    var total=string_length(dialogue_lines[dialogue_index].text);
    if(dialogue_chars<total){dialogue_chars=total;return;}
    dialogue_index++;
    if(dialogue_index>=array_length(dialogue_lines)){end_dialogue();return;}
    dialogue_chars=0;dialogue_age=0;
}
function step_dialogue(_dt) {
    dialogue_age+=_dt;dialogue_chars=min(string_length(dialogue_lines[dialogue_index].text),dialogue_chars+1.15*_dt);
    if(dialogue_age>8&&(keyboard_check_pressed(vk_enter)||keyboard_check_pressed(vk_space)||mouse_check_button_pressed(mb_left)))next_dialogue();
    if(keyboard_check_pressed(vk_escape))end_dialogue();
}
function draw_dialogue() {
    box(0,0,960,540,ink,.58);
    text_at(35,24,"НОЧНАЯ ЛИНИЯ / 0"+string(level+1)+" / ЭТАЖ "+string(floor_index+1),font_small,mint);
    box(24,330,912,194,col(0x101c2a));box(24,330,912,2,pink);
    var row=dialogue_lines[dialogue_index],speaking=dialogue_chars<string_length(row.text);
    draw_sprite_ext(portraits[row.who],speaking?(floor(ticks/8) mod 2):0,40,351,1.6,1.6,0,c_white,1);
    text_at(179,349,story_data.names[row.who],font_ui,row.who==2?pink:mint);
    draw_set_font(font_dialogue);draw_set_colour(cream);draw_set_halign(fa_left);draw_set_valign(fa_top);
    draw_text_ext(179,385,string_copy(row.text,1,floor(dialogue_chars)),25,718);
    text_at(179,497,"ENTER / SPACE — ДАЛЕЕ     ESC — ПРОПУСТИТЬ",font_small,muted_col);
    text_at(914,497,string(dialogue_index+1)+" / "+string(array_length(dialogue_lines)),font_small,mint,fa_right);
}
