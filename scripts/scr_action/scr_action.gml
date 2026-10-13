/// Physical doors, patrols, glass and the stairwell enforcer.
function door_local(_d,_x,_y) {
    door_cache_pose(_d);var dx=_x-_d.pivot_x,dy=_y-_d.pivot_y;
    return [dx*_d.pose_cos-dy*_d.pose_sin,dx*_d.pose_sin+dy*_d.pose_cos];
}
function door_cache_pose(_d) {
    if(_d.pose_open==_d.open&&_d.pose_swing==_d.swing)return;
    var ang=(_d.w>_d.h?0:270)+_d.swing*90*_d.open;
    _d.pose_cos=dcos(ang);_d.pose_sin=dsin(ang);_d.pose_open=_d.open;_d.pose_swing=_d.swing;
    var ex=_d.pivot_x+_d.leaf_length*_d.pose_cos,ey=_d.pivot_y-_d.leaf_length*_d.pose_sin;
    _d.min_x=min(_d.pivot_x,ex)-3;_d.max_x=max(_d.pivot_x,ex)+3;
    _d.min_y=min(_d.pivot_y,ey)-3;_d.max_y=max(_d.pivot_y,ey)+3;
}
function door_blocks(_d,_x,_y,_r) {
    door_cache_pose(_d);var pad=_r*1.415;
    if(_x<_d.min_x-pad||_x>_d.max_x+pad||_y<_d.min_y-pad||_y>_d.max_y+pad)return false;
    var dx=_x-_d.pivot_x,dy=_y-_d.pivot_y,lx=dx*_d.pose_cos-dy*_d.pose_sin;
    return lx>-_r+.0001&&lx<_d.leaf_length+_r-.0001&&abs(dx*_d.pose_sin+dy*_d.pose_cos)<3+_r-.0001;
}
function door_ray(_d,_x,_y,_tx,_ty,_r) {
    door_cache_pose(_d);var pad=_r*1.415;
    if(max(_x,_tx)<_d.min_x-pad||min(_x,_tx)>_d.max_x+pad||max(_y,_ty)<_d.min_y-pad||min(_y,_ty)>_d.max_y+pad)return false;
    var a=door_local(_d,_x,_y),b=door_local(_d,_tx,_ty),dx=b[0]-a[0],dy=b[1]-a[1],lo=0,hi=1;
    var left=-_r,right=max(_d.w,_d.h)+_r,top=-3-_r,bottom=3+_r;
    if(abs(dx)<.0001){if(a[0]<=left+.0001||a[0]>=right-.0001)return false;}
    else{var u=(left-a[0])/dx,v=(right-a[0])/dx;lo=max(lo,min(u,v));hi=min(hi,max(u,v));}
    if(abs(dy)<.0001){if(a[1]<=top+.0001||a[1]>=bottom-.0001)return false;}
    else{var u=(top-a[1])/dy,v=(bottom-a[1])/dy;lo=max(lo,min(u,v));hi=min(hi,max(u,v));}
    return lo<hi-.000001&&hi>0&&lo<1;
}
function kick_door(_x,_y) {
    var di=nearest_door(_x,_y,38);if(di<0)return;
    set_door(di,1,_x,_y);doors[di].kick=true;sound_fx(snd_slam,.7);noise_x=_x;noise_y=_y;noise_timer=18;
}
function turn_to(_a,_target,_amount) {return _a+clamp(((_target-_a+540) mod 360)-180,-_amount,_amount);}
function init_patrol(_e) {
    _e.route=[[_e.x,_e.y]];_e.route_index=0;_e.wait=irandom_range(15,65);_e.stuck=0;
    for(var i=0;i<8;i++) {var ang=i*45,tx=_e.ox+lengthdir_x(65,ang),ty=_e.oy+lengthdir_y(65,ang);
        if(ty<546&&clear_path(_e.ox,_e.oy,tx,ty,10))array_push(_e.route,[tx,ty]);
        if(array_length(_e.route)>=3)break;
    }
}
function patrol_enemy(_e,_dt) {
    if(_e.wait>0){_e.wait-=_dt;_e.frame=0;return;}
    var target=_e.route[_e.route_index],dist=point_distance(_e.x,_e.y,target[0],target[1]);
    if(dist<3||_e.stuck>25){_e.route_index=(_e.route_index+1) mod array_length(_e.route);_e.wait=irandom_range(30,80);_e.stuck=0;return;}
    var ang=point_direction(_e.x,_e.y,target[0],target[1]),before_x=_e.x,before_y=_e.y;
    _e.angle=turn_to(_e.angle,ang,5*_dt);move_actor(_e,lengthdir_x(min(dist,1.05*_dt),ang),lengthdir_y(min(dist,1.05*_dt),ang));
    var walked=point_distance(before_x,before_y,_e.x,_e.y);_e.frame+=walked*.5;_e.stuck=walked<.1?_e.stuck+_dt:0;
}
function damage_enemy(_e,_amount,_angle) {
    if(!_e.alive||_e.hitcool>0||_amount<=0)return;
    if(_e.kind==3){_e.hp-=_amount*(_e.stun>0?1.5:1);_e.hitcool=4;_e.alert=300;
        burst(_e.x,_e.y,_angle,12,blood_on);blood_mark(_e.x,_e.y,5);shake=max(shake,3);sound_fx(snd_hit,.6);
        if(_e.hp>0)return;
    }
    kill_enemy(_e,_angle);
}
function break_glass_near(_x,_y,_r,_angle) {
    for(var i=0;i<array_length(panes);i++){var g=panes[i];if(g.broken||!rect_contains_body(g.r,_x,_y,_r))continue;
        g.broken=true;sound_fx(snd_glass,.8);noise_timer=22;noise_x=_x;noise_y=_y;shake=max(shake,2);
        for(var n=0;n<28;n++)array_push(shards,{x:g.r[0]+random(g.r[2])+random_range(-22,22),y:g.r[1]+random(g.r[3])+random_range(-22,22),a:random(360),size:random_range(2,5)});
        burst(_x,_y,_angle,18,false);
    }
}
function draw_glass() {
    for(var i=0;i<array_length(panes);i++){var g=panes[i],r=g.r;
        if(!g.broken){box(r[0],r[1],r[2],r[3],col(0x6faeaf),.4);box(r[0],r[1]+2,r[2],1,col(0xbce6d7));
            for(var xx=r[0]+5;xx<r[0]+r[2]-4;xx+=12){draw_set_colour(col(0x9cd2d1));draw_line(xx,r[1]+7,xx+5,r[1]+3);}}
    }
    draw_set_colour(col(0x92c4c1));for(var i=0;i<array_length(shards);i++){var q=shards[i];draw_triangle(q.x,q.y,q.x+lengthdir_x(q.size,q.a),q.y+lengthdir_y(q.size,q.a),q.x+lengthdir_x(q.size*.65,q.a+70),q.y+lengthdir_y(q.size*.65,q.a+70),false);}
}
function start_grab(_e) {
    if(p.inv>0||dash_timer>0||!is_undefined(grabber))return false;
    grabber=_e;grab_timer=assist?200:165;grab_progress=0;grab_key=ord("A");_e.boss_mode="recover";_e.boss_timer=80;return true;
}
function grapple_input(_key) {
    if(is_undefined(grabber)||_key!=grab_key)return;
    grab_progress++;grab_key=grab_key==ord("A")?ord("D"):ord("A");sound_fx(snd_hit,.22);
    if(grab_progress>=(assist?4:6)){var e=grabber;grabber=undefined;e.stun=100;e.boss_mode="recover";e.boss_timer=70;p.inv=60;
        damage_enemy(e,2,p.angle);move_actor(p,lengthdir_x(22,point_direction(e.x,e.y,p.x,p.y)),lengthdir_y(22,point_direction(e.x,e.y,p.x,p.y)));shake=6;}
}
function step_grapple(_dt) {
    if(is_undefined(grabber))return false;
    if(!grabber.alive){grabber=undefined;return false;}
    grab_timer-=_dt;p.frame=0;shake=max(shake,1.5);
    if(keyboard_check_pressed(ord("A")))grapple_input(ord("A"));
    else if(keyboard_check_pressed(ord("D")))grapple_input(ord("D"));
    if(grab_timer<=0&&!is_undefined(grabber)){grabber.stun=55;grabber=undefined;p.inv=0;hurt_player(0);}
    return true;
}
function step_boss(_e,_dt,_see,_distance) {
    if(_e.alert<=0){patrol_enemy(_e,_dt);return;}
    _e.boss_timer-=_dt;
    if(_e.boss_mode=="windup") {
        if(_e.boss_timer<=0){_e.boss_mode="charge";_e.boss_timer=26;sound_fx(snd_dash,.65);}
    } else if(_e.boss_mode=="charge") {
        var bx=_e.x,by=_e.y;open_enemy_door(_e);break_glass_near(_e.x,_e.y,20,_e.angle);
        move_actor(_e,lengthdir_x(6.6*_dt,_e.angle),lengthdir_y(6.6*_dt,_e.angle));_e.frame+=_dt;
        if(point_distance(_e.x,_e.y,p.x,p.y)<23)start_grab(_e);
        if(point_distance(bx,by,_e.x,_e.y)<2||_e.boss_timer<=0){_e.boss_mode="recover";_e.boss_timer=65;_e.stun=35;shake=max(shake,3);}
    } else if(_e.boss_mode=="recover") {
        if(_e.boss_timer<=0)_e.boss_mode="hunt";
    } else {
        if(_see&&_distance<185&&_distance>26){_e.boss_mode="windup";_e.boss_timer=30;_e.angle=point_direction(_e.x,_e.y,p.x,p.y);}
        else if(_distance<26){if(!start_grab(_e)){_e.boss_mode="recover";_e.boss_timer=45;}}
        else {_e.angle=turn_to(_e.angle,chase_enemy(_e,1.8*_dt),7*_dt);}
    }
}
function draw_enemy_status(_e) {
    if(_e.stun>0){text_at(_e.x,_e.y-30,"*  *  *",font_small,mint,fa_center);return;}
    if(_e.kind==3){box(_e.x-20,_e.y-29,40,3,ink);box(_e.x-20,_e.y-29,40*max(0,_e.hp)/_e.maxhp,3,pink);
        if(_e.boss_mode=="windup"){draw_set_colour(pink);draw_circle(_e.x,_e.y,23+sin(ticks*.4)*3,true);draw_line_width(_e.x,_e.y,_e.x+lengthdir_x(70,_e.angle),_e.y+lengthdir_y(70,_e.angle),2);}
    }
}
function draw_grapple() {
    if(is_undefined(grabber))return;
    box(264,177,432,153,ink,.95);text_at(480,190,"ЗАХВАТ — ВЫРЫВАЙСЯ!",font_ui,pink,fa_center);
    box(385,229,70,43,grab_key==ord("A")?mint:muted_col);box(505,229,70,43,grab_key==ord("D")?mint:muted_col);
    text_at(420,239,"A",font_ui,ink,fa_center);text_at(540,239,"D",font_ui,ink,fa_center);
    text_at(480,284,"ЧЕРЕДУЙ КЛАВИШИ   "+string(grab_progress)+" / "+string(assist?4:6),font_small,cream,fa_center);
    box(280,315,400*grab_timer/(assist?200:165),3,pink);
}
