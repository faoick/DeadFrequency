/// DEAD FREQUENCY — original native GameMaker combat and presentation.
function col(_hex) { return make_colour_rgb((_hex >> 16) & 255, (_hex >> 8) & 255, _hex & 255); }
function box(_x,_y,_w,_h,_c,_a=1) {
    draw_set_alpha(_a); draw_set_colour(_c); draw_rectangle(_x,_y,_x+_w,_y+_h,false); draw_set_alpha(1);
}
function text_at(_x,_y,_text,_font,_c,_align=fa_left) {
    draw_set_font(_font); draw_set_halign(_align); draw_set_valign(fa_top);
    draw_set_colour(_c);draw_set_alpha(1);draw_text(_x,_y,_text);draw_set_halign(fa_left);
}
function sound_fx(_snd,_gain=1) {
    if (!muted) { var ch=audio_play_sound(_snd,2,false);audio_sound_gain(ch,_gain*.65,0);audio_sound_pitch(ch,random_range(.98,1.02)); }
}
// Broad phase only: bucket candidates still receive the unchanged exact tests.
function build_wall_buckets() {
    wall_bins=array_create(600);wall_ray_bins=array_create(600);wall_indices=[];
    for(var i=0;i<600;i++){wall_bins[i]=[];wall_ray_bins[i]=[];}
    for(var i=0;i<array_length(walls);i++){array_push(wall_indices,i);var w=walls[i];
        for(var pass=0;pass<2;pass++){var pad=pass==0?16:48;
            var left=clamp(floor((w[0]-pad)/32),0,29),right=clamp(floor((w[0]+w[2]+pad)/32),0,29);
            var top=clamp(floor((w[1]-pad)/32),0,19),bottom=clamp(floor((w[1]+w[3]+pad)/32),0,19);
            for(var yy=top;yy<=bottom;yy++)for(var xx=left;xx<=right;xx++){var cell=yy*30+xx;
                if(pass==0){var list=wall_bins[cell];array_push(list,i);wall_bins[cell]=list;}
                else{var list=wall_ray_bins[cell];array_push(list,i);wall_ray_bins[cell]=list;}
            }
        }
    }
}
function solid_at(_x,_y,_r=6,_include_doors=true) {
    if (_x<_r || _y<_r || _x>960-_r || _y>640-_r) return true;
    var candidates=_r<=16?wall_bins[clamp(floor(_y/32),0,19)*30+clamp(floor(_x/32),0,29)]:wall_indices;
    for(var i=0;i<array_length(candidates);i++) {
        var w=walls[candidates[i]];
        if(_x+_r>w[0]+.0001 && _x-_r<w[0]+w[2]-.0001 && _y+_r>w[1]+.0001 && _y-_r<w[1]+w[3]-.0001) return true;
    }
    if(_include_doors){
        for(var i=0;i<array_length(doors);i++)if(door_blocks(doors[i],_x,_y,_r))return true;
        if(_r>=6)for(var i=0;i<array_length(panes);i++)if(!panes[i].broken&&rect_contains_body(panes[i].r,_x,_y,_r))return true;
    }
    return false;
}
// Exact segment vs expanded rectangles. Sight and navigation share wall geometry.
function clear_path(_x,_y,_tx,_ty,_radius,_include_doors=true) {
    if(solid_at(_x,_y,_radius,_include_doors)||solid_at(_tx,_ty,_radius,_include_doors))return false;
    var dx=_tx-_x,dy=_ty-_y;
    if(_include_doors)for(var i=0;i<array_length(doors);i++)if(door_ray(doors[i],_x,_y,_tx,_ty,_radius))return false;
    var candidates=abs(dx)<=32&&abs(dy)<=32&&_radius<=16?wall_ray_bins[clamp(floor(_y/32),0,19)*30+clamp(floor(_x/32),0,29)]:wall_indices;
    var wall_count=array_length(candidates),count=wall_count+(_include_doors&&_radius>=6?array_length(panes):0);
    for(var i=0;i<count;i++) {
        if(i>=wall_count&&panes[i-wall_count].broken)continue;
        var w=i<wall_count?walls[candidates[i]]:panes[i-wall_count].r;if(w[2]<=0||w[3]<=0)continue;
        var lo=0,hi=1;
        var left=w[0]-_radius,right=w[0]+w[2]+_radius,top=w[1]-_radius,bottom=w[1]+w[3]+_radius;
        if(abs(dx)<.0001){if(_x<=left+.0001||_x>=right-.0001)continue;}
        else {var a=(left-_x)/dx,b=(right-_x)/dx;lo=max(lo,min(a,b));hi=min(hi,max(a,b));}
        if(abs(dy)<.0001){if(_y<=top+.0001||_y>=bottom-.0001)continue;}
        else {var a=(top-_y)/dy,b=(bottom-_y)/dy;lo=max(lo,min(a,b));hi=min(hi,max(a,b));}
        if(lo<hi-.000001&&hi>0&&lo<1)return false;
    }
    return true;
}
function clear_line(_x,_y,_tx,_ty) {return clear_path(_x,_y,_tx,_ty,1);}
function move_actor(_a,_dx,_dy) {
    var steps=max(1,ceil(max(abs(_dx),abs(_dy))/2));
    for(var i=0;i<steps;i++) {
        if(!solid_at(_a.x+_dx/steps,_a.y,9))_a.x+=_dx/steps;
        if(!solid_at(_a.x,_a.y+_dy/steps,9))_a.y+=_dy/steps;
    }
}
function burst(_x,_y,_angle,_count,_blood) {
    for(var i=0;i<_count;i++) {
        var a=_angle+random_range(-55,55),sp=random_range(1.5,_blood?9:6);
        array_push(particles,{x:_x,y:_y,vx:lengthdir_x(sp,a),vy:lengthdir_y(sp,a),life:random_range(15,38),maxlife:38,
            colour:_blood?choose(col(0x982449),col(0xdb3659),col(0x651e39)):choose(col(0xffdfa0),col(0xfff0d2)),sz:_blood?irandom_range(1,3):1,blood:_blood});
    }
    if(array_length(particles)>1200) array_delete(particles,0,array_length(particles)-1200);
}
function blood_mark(_x,_y,_rad) {
    if(!blood_on||solid_at(_x,_y,0))return;
    array_push(decals,{x:_x,y:_y,r:_rad,c:choose(col(0x991d3c),col(0x75192f),col(0x54182c)),frame:irandom(7),angle:random(360)});
    // Enough for the largest level; blood, bodies and brass survive the whole attempt.
    if(array_length(decals)>6000)array_delete(decals,0,1);
}
function weapon_name(_kind) { var names=["ПИСТОЛЕТ / 9MM","АВТОМАТ / SMG","ДРОБОВИК / 12G"];return names[_kind]; }
function weapon_capacity(_kind) {var capacities=[12,28,6];return capacities[_kind];}
function save_progress() {
    if(variable_instance_exists(id,"test_mode")&&test_mode)return;
    ini_open("dead_frequency.ini");ini_write_real("game","unlocked",unlocked);ini_write_real("game","best",best);
    ini_write_real("settings","assist",assist);ini_write_real("settings","muted",muted);
    ini_write_real("settings","shake",shake_on);ini_write_real("settings","blood",blood_on);
    ini_write_real("economy","cash",wallet);ini_write_real("economy","owned",owned_weapons);ini_write_real("economy","selected",selected_weapon);ini_write_real("economy","armor",armor_ready);ini_write_real("economy","next",hub_next);ini_close();
}
function set_music() {audio_sound_gain(music_channel,muted?0:(state=="play"?.36:.23),250);}
function load_level(_level,_floor=0,_carry=undefined) {
    level=_level;floor_index=_floor;room_data=floor_index==0?level_data[level]:level_data[level].upper;
    walls=room_data.walls;build_wall_buckets();doors=[];panes=[];shards=[];grabber=undefined;grab_timer=0;grab_progress=0;grab_key=ord("A");
    for(var i=0;i<array_length(room_data.glass);i++)array_push(panes,{r:room_data.glass[i],broken:false});
    for(var i=0;i<array_length(room_data.doors);i++){var r=room_data.doors[i];array_push(doors,{x:r[0],y:r[1],w:r[2],h:r[3],open:0,target:0,swing:1,kick:false,serial:0,pivot_x:r[0]+(r[2]>r[3]?0:r[2]/2),pivot_y:r[1]+(r[2]>r[3]?r[3]/2:0),leaf_length:max(r[2],r[3]),pose_open:-1,pose_swing:0,nav_open:false,nav_swing:0,nav_cells:[]});}
    enemies=[];bullets=[];particles=[];decals=[];bodies=[];drops=[];floaters=[];shells=[];muzzles=[];ghosts=[];
    p={x:room_data.spawn[0],y:room_data.spawn[1],angle:90,frame:0,health:assist?2:1,maxhealth:assist?2:1,inv:0};
    recoil=0;foot_timer=0;bloody_steps=0;
    weapon=0;ammo=12;reload_timer=0;fire_timer=0;dash_timer=0;dash_cool=0;melee_timer=0;dash_angle=0;
    run_score=0;combo=0;combo_timer=0;kills=0;elapsed=0;shake=0;flash=0;hitstop=0;intro=150;noise_timer=0;flow_timer=0;
    floor_checkpoint=is_undefined(_carry)?{weapon:0,ammo:12,health:assist?2:1,maxhealth:assist?2:1,points:0,time:0,previous_kills:0}:_carry;
    weapon=floor_checkpoint.weapon;ammo=floor_checkpoint.ammo;p.health=floor_checkpoint.health;p.maxhealth=floor_checkpoint.maxhealth;
    run_score=floor_checkpoint.points;elapsed=floor_checkpoint.time;chapter_kills=floor_checkpoint.previous_kills;pickup_near=-1;
    var placements=room_data.enemies;
    for(var i=0;i<array_length(placements);i++) {
        var a=placements[i];
        array_push(enemies,{x:a[0],y:a[1],ox:a[0],oy:a[1],angle:choose(0,90,180,270),kind:a[2],alive:true,
            alert:0,windup:0,cool:random_range(25,75),frame:0,phase:random(6.28),tx:0,ty:0,hp:a[2]==3?8+level:1,maxhp:a[2]==3?8+level:1,hitcool:0,stun:0,door_serial:-1,boss_mode:"hunt",boss_timer:0});
        init_patrol(enemies[i]);
    }
    var loot=room_data.drops;
    for(var i=0;i<array_length(loot);i++)array_push(drops,{x:loot[i][0],y:loot[i][1],kind:loot[i][2],ammo:weapon_capacity(loot[i][2])});
    total_enemies=array_length(enemies);camx=clamp(p.x-320,0,320);camy=clamp(p.y-180,0,320);
    var nav_key=level*2+floor_index;
    if(is_undefined(nav_cache[nav_key])) {
        nav_block=array_create(9600,false);nav_edges=array_create(9600,0);
        for(var yy=0;yy<80;yy++)for(var xx=0;xx<120;xx++)nav_block[yy*120+xx]=solid_at(xx*8+4,yy*8+4,9,false);
        var dxs=[1,-1,0,0],dys=[0,0,1,-1];
        for(var yy=0;yy<80;yy++)for(var xx=0;xx<120;xx++) {
            var cell=yy*120+xx;if(nav_block[cell])continue;
            for(var di=0;di<4;di++){var nx=xx+dxs[di],ny=yy+dys[di];
                // Cardinal 8px edges cannot cross a radius-9 inflated rectangle
                // with both endpoints clear (each inflated obstacle is >=18px).
                if(nx>=0&&nx<120&&ny>=0&&ny<80&&!nav_block[ny*120+nx])nav_edges[cell]|=(1<<di);
            }
        }
        nav_cache[nav_key]={blocks:nav_block,edges:nav_edges};
    } else {nav_block=nav_cache[nav_key].blocks;nav_edges=nav_cache[nav_key].edges;}
    nav_dist=array_create(9600,9999);nav_seed=-1;nav_door_mask=array_create(9600,0);nav_queue=array_create(9600,0);nav_pending=false;nav_revision=0;nav_job=undefined;
    state="play";set_music();
}
// Rebuild only the small footprint of a leaf when its settled state changes.
// Counts preserve overlapping leaves; moving/closed doors remain operable routes.
function sync_door_navigation() {
    var changed=false;
    for(var i=0;i<array_length(doors);i++){var d=doors[i],opened=d.open>=.999;
        if(d.nav_open==opened&&(!opened||d.nav_swing==d.swing))continue;
        changed=true;
        for(var j=0;j<array_length(d.nav_cells);j++)nav_door_mask[d.nav_cells[j]]--;
        d.nav_cells=[];d.nav_open=opened;d.nav_swing=d.swing;
        if(!opened)continue;
        door_cache_pose(d);
        var left=max(0,floor((d.min_x-13)/8)),right=min(119,ceil((d.max_x+13)/8));
        var top=max(0,floor((d.min_y-13)/8)),bottom=min(79,ceil((d.max_y+13)/8));
        for(var yy=top;yy<=bottom;yy++)for(var xx=left;xx<=right;xx++)if(door_blocks(d,xx*8+4,yy*8+4,9)){
            var cell=yy*120+xx;nav_door_mask[cell]++;array_push(d.nav_cells,cell);
        }
    }
    if(changed){nav_seed=-1;nav_revision++;}
    return changed;
}
function update_flow(_immediate=true) {
    sync_door_navigation();
    if(nav_pending&&!_immediate)return;
    var sx=clamp(floor(p.x/8),0,119),sy=clamp(floor(p.y/8),0,79),seed=-1,near=100000;
    for(var yy=max(0,sy-2);yy<=min(79,sy+2);yy++)for(var xx=max(0,sx-2);xx<=min(119,sx+2);xx++) {
        var cell=yy*120+xx,dist=point_distance(p.x,p.y,xx*8+4,yy*8+4);
        if(!nav_block[cell]&&dist<near&&clear_path(p.x,p.y,xx*8+4,yy*8+4,9,false)){near=dist;seed=cell;}
    }
    if(seed<0)return;
    if(seed==nav_seed)return;
    nav_job={seed:seed,revision:nav_revision,dist:array_create(9600,9999),mask:nav_door_mask,head:0,tail:1};
    nav_queue[0]=seed;nav_job.dist[seed]=0;nav_pending=true;
    if(_immediate)advance_flow(9600);
}
function advance_flow(_budget) {
    if(!nav_pending)return;
    var nav_started=get_timer(),job=nav_job;
    var distances=job.dist,edges=nav_edges,blocked=job.mask,queue=nav_queue;
    var head=job.head,tail=job.tail,limit=head+_budget;
    while(head<tail&&head<limit){var cell=queue[head++],bits=edges[cell],next_distance=distances[cell]+1,ni;
        if((bits&1)!=0){ni=cell+1;if(distances[ni]==9999&&blocked[ni]==0){distances[ni]=next_distance;queue[tail++]=ni;}}
        if((bits&2)!=0){ni=cell-1;if(distances[ni]==9999&&blocked[ni]==0){distances[ni]=next_distance;queue[tail++]=ni;}}
        if((bits&4)!=0){ni=cell+120;if(distances[ni]==9999&&blocked[ni]==0){distances[ni]=next_distance;queue[tail++]=ni;}}
        if((bits&8)!=0){ni=cell-120;if(distances[ni]==9999&&blocked[ni]==0){distances[ni]=next_distance;queue[tail++]=ni;}}
    }
    job.dist=distances;job.head=head;job.tail=tail;nav_queue=queue;
    if(head>=tail){
        // Never expose a half-built field or one invalidated by a changing door.
        if(job.revision==nav_revision){nav_dist=distances;nav_seed=job.seed;}
        else flow_timer=0;
        nav_pending=false;
    }
    if(variable_instance_exists(id,"perf_mode")&&perf_mode&&perf_frame>60)array_push(perf_nav,(get_timer()-nav_started)/1000);
}

function chase_enemy(_e,_amount) {
    open_enemy_door(_e);break_glass_near(_e.x,_e.y,22,_e.angle);
    var tx=p.x,ty=p.y;
    if(!clear_path(_e.x,_e.y,tx,ty,9)) {
        var gx=clamp(floor(_e.x/8),0,119),gy=clamp(floor(_e.y/8),0,79),cost_best=100000000;
        tx=_e.x;ty=_e.y;
        // Every connector from the actor to the grid is swept at its full body size.
        for(var yy=max(0,gy-2);yy<=min(79,gy+2);yy++)for(var xx=max(0,gx-2);xx<=min(119,gx+2);xx++) {
            var cell=yy*120+xx,cx=xx*8+4,cy=yy*8+4;
            var cost=nav_dist[cell]*1000+point_distance(_e.x,_e.y,cx,cy);
            if(nav_dist[cell]<9999&&cost<cost_best&&clear_path(_e.x,_e.y,cx,cy,9)){cost_best=cost;tx=cx;ty=cy;}
        }
    }
    var dist=point_distance(_e.x,_e.y,tx,ty),ang=point_direction(_e.x,_e.y,tx,ty);
    move_actor(_e,lengthdir_x(min(dist,_amount),ang),lengthdir_y(min(dist,_amount),ang));
    _e.frame+=_amount*.45;return ang;
}
function update_enemy_attack(_e,_dt,_can_see,_distance) {
    // Losing the player cancels both tracking and the pending shot immediately.
    if(!_can_see){_e.windup=0;_e.cool=max(_e.cool,12);return;}
    if(_e.windup<=0&&_e.cool<=0&&(_e.kind>0||_distance<25)) {
        _e.windup=_e.kind==0?17:(assist?37:26);_e.tx=p.x;_e.ty=p.y;
    }
    if(_e.windup<=0)return;
    _e.windup-=_dt;if(_e.windup>9){_e.tx=p.x;_e.ty=p.y;}
    if(_e.windup<=0) {
        if(_e.kind==0){if(_distance<31)hurt_player(_e.angle);_e.cool=33;}
        else {
            var ang=point_direction(_e.x,_e.y,_e.tx,_e.ty),sx=_e.x+lengthdir_x(26,ang),sy=_e.y+lengthdir_y(26,ang);
            if(clear_line(_e.x,_e.y,p.x,p.y)&&clear_line(_e.x,_e.y,_e.tx,_e.ty)&&clear_line(_e.x,_e.y,sx,sy))fire_bullet(sx,sy,ang,true,_e.kind==2?2:0);
            _e.cool=_e.kind==2?88:64;
        }
    }
}
function kill_enemy(_e,_angle) {
    if(!_e.alive)return;
    _e.alive=false;kills++;combo=min(combo+1,20);combo_timer=180;
    var pts=100*min(combo,8);run_score+=pts;
    array_push(floaters,{x:_e.x,y:_e.y-14,text:"+"+string(pts),life:45});
    array_push(bodies,{x:_e.x,y:_e.y,angle:_angle+90,kind:_e.kind,variant:irandom(7),vx:lengthdir_x(5.5,_angle),vy:lengthdir_y(5.5,_angle),age:0});
    array_push(drops,{x:_e.x+random_range(-10,10),y:_e.y+random_range(-10,10),kind:_e.kind==2?2:choose(0,1),ammo:_e.kind==2?5:irandom_range(8,20)});
    burst(_e.x,_e.y,_angle,52,blood_on);blood_mark(_e.x,_e.y,14);
    if(blood_on)for(var i=0;i<22;i++){var a=_angle+random_range(-70,70),r=random(42);blood_mark(_e.x+lengthdir_x(r,a),_e.y+lengthdir_y(r,a),random_range(2,7));}
    shake=max(shake,5);hitstop=1.7;flash=.065;sound_fx(snd_hit,.8);
    if(kills==total_enemies){sound_fx(snd_clear);intro=150;}
}
function hurt_player(_angle) {
    if(p.inv>0||dash_timer>0||state!="play"||!is_undefined(grabber))return;
    p.health--;p.inv=70;shake=8;flash=.35;burst(p.x,p.y,_angle,18,blood_on);
    if(p.health<=0) {state="dead";deaths++;sound_fx(snd_death);set_music();death_timer=0;}
    else sound_fx(snd_hit);
}
function fire_bullet(_x,_y,_a,_enemy,_kind) {
    var count=_kind==2?8:1;
    for(var i=0;i<count;i++) {
        var a=_a+random_range(_kind==2?-12:(_kind==1?-3:-.7),_kind==2?12:(_kind==1?3:.7));
        array_push(bullets,{x:_x,y:_y,px:_x,py:_y,vx:lengthdir_x(_enemy?8.4:22,a),vy:lengthdir_y(_enemy?8.4:22,a),life:_kind==2?19:40,enemy:_enemy,damage:_kind==2?2.5:1});
    }
    burst(_x,_y,_a,_kind==2?15:8,false);
    array_push(muzzles,{x:_x,y:_y,angle:_a,kind:_kind,life:4});
    if(!_enemy)recoil=_kind==2?6:(_kind==1?2:3);
    array_push(shells,{x:_x,y:_y,vx:lengthdir_x(2,_a+90),vy:lengthdir_y(2,_a+90),life:25});
    if(array_length(shells)>350)array_delete(shells,0,1);
    sound_fx(_kind==2?snd_shotgun:(_kind==1?snd_smg:snd_shot),_enemy?.48:.9);
}
function step_game(_dt) {
    step_doors(_dt,false);
    if(step_grapple(_dt)){elapsed+=_dt/60;return;}
    if(keyboard_check_pressed(ord("F"))){interact_world();if(state!="play")return;}
    if(hitstop>0){hitstop-=_dt;return;}
    elapsed+=_dt/60;intro=max(0,intro-_dt);combo_timer=max(0,combo_timer-_dt);if(combo_timer<=0)combo=0;
    fire_timer=max(0,fire_timer-_dt);dash_cool=max(0,dash_cool-_dt);melee_timer=max(0,melee_timer-_dt);p.inv=max(0,p.inv-_dt);
    flow_timer-=_dt;if(flow_timer<=0){flow_timer=18;update_flow(false);}
    advance_flow(768);
    var mx=keyboard_check(ord("D"))-keyboard_check(ord("A")),my=keyboard_check(ord("S"))-keyboard_check(ord("W"));
    mx+=keyboard_check(vk_right)-keyboard_check(vk_left);my+=keyboard_check(vk_down)-keyboard_check(vk_up);
    var moving=mx!=0||my!=0,dir=point_direction(0,0,mx,my);
    p.angle=point_direction(p.x,p.y,mouse_x,mouse_y);
    if(keyboard_check_pressed(vk_space)&&dash_cool<=0) {kick_door(p.x,p.y);dash_timer=9;dash_cool=36;dash_angle=moving?dir:p.angle;sound_fx(snd_dash);}
    if(dash_timer>0){break_glass_near(p.x+lengthdir_x(14,dash_angle),p.y+lengthdir_y(14,dash_angle),18,dash_angle);move_actor(p,lengthdir_x(9.2*_dt,dash_angle),lengthdir_y(9.2*_dt,dash_angle));dash_timer-=_dt;
        array_push(ghosts,{x:p.x,y:p.y,angle:p.angle,frame:p.frame,life:10});}
    else if(moving){move_actor(p,lengthdir_x(4.05*_dt,dir),lengthdir_y(4.05*_dt,dir));p.frame+=.65*_dt;}else p.frame=0;
    if(reload_timer>0) {reload_timer-=_dt;if(reload_timer<=0){ammo=weapon_capacity(weapon);sound_fx(snd_reload,.6);}}
    if(keyboard_check_pressed(ord("R")) && reload_timer<=0 && ammo<weapon_capacity(weapon)){reload_timer=weapon==2?58:36;sound_fx(snd_reload);}
    if(mouse_check_button(mb_left)&&fire_timer<=0&&reload_timer<=0) {
        if(ammo>0) {
            var lengths=[20,27,29];var sx=p.x+lengthdir_x(lengths[weapon],p.angle),sy=p.y+lengthdir_y(lengths[weapon],p.angle);
            if(clear_line(p.x,p.y,sx,sy)){fire_bullet(sx,sy,p.angle,false,weapon);ammo--;var delays=[9,3.5,25];fire_timer=delays[weapon];shake=max(shake,weapon==2?6:2.2);noise_timer=25;noise_x=p.x;noise_y=p.y;}
        } else {reload_timer=weapon==2?58:36;sound_fx(snd_reload);}
    }
    if(mouse_check_button_pressed(mb_right)&&melee_timer<=0) {
        melee_timer=13;sound_fx(snd_dash,.65);kick_door(p.x,p.y);break_glass_near(p.x+lengthdir_x(23,p.angle),p.y+lengthdir_y(23,p.angle),20,p.angle);
        for(var i=0;i<array_length(enemies);i++){var e=enemies[i];if(e.alive&&point_distance(p.x,p.y,e.x,e.y)<44&&abs(angle_difference(p.angle,point_direction(p.x,p.y,e.x,e.y)))<65&&clear_line(p.x,p.y,e.x,e.y))damage_enemy(e,e.stun>0?3:1,p.angle);}
    }
    pickup_near=-1;var nearest=26;
    for(var i=0;i<array_length(drops);i++){var dist=point_distance(p.x,p.y,drops[i].x,drops[i].y);if(dist<nearest&&clear_line(p.x,p.y,drops[i].x,drops[i].y)){nearest=dist;pickup_near=i;}}
    if(keyboard_check_pressed(ord("E"))&&pickup_near>=0) {
        var gun=drops[pickup_near];array_push(drops,{x:p.x+7,y:p.y+7,kind:weapon,ammo:ammo});weapon=gun.kind;ammo=min(weapon_capacity(weapon),gun.ammo);
        array_delete(drops,pickup_near,1);reload_timer=0;fire_timer=10;sound_fx(snd_pickup);pickup_near=-1;
    }
    noise_timer=max(0,noise_timer-_dt);
    for(var i=0;i<array_length(enemies);i++) {
        var e=enemies[i];if(!e.alive)continue;e.hitcool=max(0,e.hitcool-_dt);
        if(e.stun>0){e.stun-=_dt;e.windup=0;e.frame=0;continue;}
        var distance=point_distance(e.x,e.y,p.x,p.y),aim=point_direction(e.x,e.y,p.x,p.y);
        var can_see=distance<320&&clear_line(e.x,e.y,p.x,p.y);
        if((can_see&&(abs(angle_difference(e.angle,aim))<80||distance<92))||(noise_timer>0&&point_distance(e.x,e.y,noise_x,noise_y)<260))e.alert=300;
        if(e.kind==3){step_boss(e,_dt,can_see,distance);continue;}
        if(e.alert>0) {
            e.alert-=_dt;e.cool-=_dt;
            if(can_see) {e.angle=turn_to(e.angle,aim,12*_dt);e.alert=300;}
            if(e.kind==0 || !can_see || distance>230) {
                var walk_speed=(e.kind==0?2.15:1.45)*(1+level*.045);
                if(distance>16&&e.windup<=0){var ang=chase_enemy(e,walk_speed*_dt);if(!can_see)e.angle=ang;}
            }
            can_see=point_distance(e.x,e.y,p.x,p.y)<340&&clear_line(e.x,e.y,p.x,p.y);
            update_enemy_attack(e,_dt,can_see,point_distance(e.x,e.y,p.x,p.y));
        } else {
            patrol_enemy(e,_dt);
        }
    }
    for(var i=array_length(bullets)-1;i>=0;i--) {
        var b=bullets[i];b.life-=_dt;b.px=b.x;b.py=b.y;var steps=max(1,ceil(point_distance(0,0,b.vx,b.vy)*_dt/3));
        for(var sub=0;sub<steps;sub++) {
            b.x+=b.vx*_dt/steps;b.y+=b.vy*_dt/steps;
            break_glass_near(b.x,b.y,2,point_direction(0,0,b.vx,b.vy));
            if(solid_at(b.x,b.y,1)){b.life=0;burst(b.x,b.y,point_direction(0,0,-b.vx,-b.vy),4,false);break;}
            if(b.enemy) {if(point_distance(b.x,b.y,p.x,p.y)<8){hurt_player(point_direction(0,0,b.vx,b.vy));b.life=0;break;}}
            else {var hit=false;for(var j=0;j<array_length(enemies);j++){var e=enemies[j];if(e.alive&&point_distance(b.x,b.y,e.x,e.y)<10){damage_enemy(e,b.damage,point_direction(0,0,b.vx,b.vy));b.life=0;hit=true;break;}}if(hit)break;}
        }
        if(b.life<=0)array_delete(bullets,i,1);
    }
    // F is required at stairs / exit: walking through a cleared room never skips a floor.
}
function finish_level() {
    if(state!="play"||floor_index!=1||kills!=total_enemies)return;
    payout=300+level*75+min(400,floor(run_score/40));wallet+=payout;hub_next=min(5,level+1);
    state="clear";run_score+=max(0,3000-floor(elapsed)*20);best=max(best,run_score);unlocked=max(unlocked,min(level+1,array_length(level_data)-1));save_progress();sound_fx(snd_clear);set_music();
    if(level==array_length(level_data)-1)begin_dialogue(story_data.ending,"clear");
}
function step_effects(_dt) {
    shake=max(0,shake-.6*_dt);flash=max(0,flash-.028*_dt);recoil=max(0,recoil-.85*_dt);
    for(var i=array_length(particles)-1;i>=0;i--){var q=particles[i];
        var nx=q.x+q.vx*_dt,ny=q.y+q.vy*_dt;
        if(!solid_at(nx,ny,0)){q.x=nx;q.y=ny;}else{q.vx*= -.15;q.vy*= -.15;q.life=min(q.life,5);}
        q.vx*=power(.91,_dt);q.vy*=power(.91,_dt);q.life-=_dt;
        if(q.life<=0){if(q.blood)blood_mark(q.x,q.y,q.sz);array_delete(particles,i,1);}}
    for(var i=array_length(floaters)-1;i>=0;i--){floaters[i].y-=.45*_dt;floaters[i].life-=_dt;if(floaters[i].life<=0)array_delete(floaters,i,1);}
    for(var i=0;i<array_length(shells);i++){var q=shells[i];if(q.life>0){q.life-=_dt;
        if(!solid_at(q.x+q.vx*_dt,q.y+q.vy*_dt,0)){q.x+=q.vx*_dt;q.y+=q.vy*_dt;}else{q.vx*= -.4;q.vy*= -.4;}
        q.vx*=power(.85,_dt);q.vy*=power(.85,_dt);}}
    for(var i=0;i<array_length(bodies);i++){var q=bodies[i];q.age+=_dt;
        if(abs(q.vx)+abs(q.vy)>.1){move_actor(q,q.vx*_dt,q.vy*_dt);q.vx*=power(.83,_dt);q.vy*=power(.83,_dt);if(blood_on&&floor(q.age) mod 3==0)blood_mark(q.x,q.y,5);}
        if(q.age<55&&floor(q.age) mod 6==0)blood_mark(q.x,q.y,8+q.age*.13);
    }
    for(var i=array_length(muzzles)-1;i>=0;i--){muzzles[i].life-=_dt;if(muzzles[i].life<=0)array_delete(muzzles,i,1);}
    for(var i=array_length(ghosts)-1;i>=0;i--){ghosts[i].life-=_dt;if(ghosts[i].life<=0)array_delete(ghosts,i,1);}
    foot_timer-=_dt;
    if(foot_timer<=0&&state=="play"&&p.frame>0){foot_timer=10;sound_fx(choose(snd_footstep1,snd_footstep2,snd_footstep3),.18);
        for(var i=0;i<array_length(bodies);i++)if(point_distance(p.x,p.y,bodies[i].x,bodies[i].y)<21)bloody_steps=12;
        if(bloody_steps>0){bloody_steps--;blood_mark(p.x,p.y,2.8);}
    }
}
function draw_gun(_x,_y,_angle,_kind,_kick=0,_alpha=1) {
    draw_sprite_ext(weapon_sprite,_kind,_x-lengthdir_x(_kick,_angle),_y-lengthdir_y(_kick,_angle),1,1,_angle,c_white,_alpha);
}
function draw_actor(_x,_y,_a,_kind,_frame,_alpha=1) {
    draw_set_alpha(_alpha*.5);draw_set_colour(col(0x060c16));draw_ellipse(_x-10,_y-5,_x+10,_y+10,false);draw_set_alpha(1);
    draw_sprite_ext(actors[_kind],floor(_frame) mod 8,round(_x),round(_y),1,1,_a,c_white,_alpha);
    if(_kind==4)return;
    var gun_kind=_kind==0?weapon:(_kind==1?3:(_kind==2?0:2));
    draw_gun(_x+lengthdir_x(3,_a)+lengthdir_x(2,_a-90),_y+lengthdir_y(3,_a)+lengthdir_y(2,_a-90),_a,gun_kind,_kind==0?recoil:0,_alpha);
}
function draw_world() {
    if(state=="hub"||state=="shop"){draw_hub_world();return;}
    draw_sprite(floor_index==0?backgrounds[level]:upper_backgrounds[level],0,0,0);
    draw_floor_markers();draw_glass();draw_arrival();
    for(var i=0;i<array_length(decals);i++){var q=decals[i];if(abs(q.x-camx-320)<350&&abs(q.y-camy-180)<210)draw_sprite_ext(blood_sprite,q.frame,q.x,q.y,q.r/12,q.r/12,q.angle,q.c,1);}
    for(var i=0;i<array_length(bodies);i++){var q=bodies[i];draw_sprite_ext(actors[q.kind+1],q.variant,q.x,q.y,1.15,.7,q.angle,col(0xa7889b),1);box(q.x-2,q.y-2,4,4,col(0x521a31));}
    for(var i=0;i<array_length(shells);i++){var q=shells[i];box(q.x,q.y,2,1,col(0xcaa56d));}
    for(var i=0;i<array_length(drops);i++) {
        var q=drops[i];draw_set_colour(col(0x1b1425));draw_circle(q.x,q.y,6,false);
        draw_gun(q.x-5,q.y,q.kind==2?15:(q.kind==1?-12:30),q.kind);
        if(point_distance(q.x,q.y,p.x,p.y)<26){draw_set_colour(col(0x88edda));draw_circle(q.x,q.y,12+sin(ticks*.08)*2,true);}
    }
    draw_doors();
    // Telegraphs are can_see and stop at walls: enemies never shoot through scenery.
    for(var i=0;i<array_length(enemies);i++) {
        var e=enemies[i];if(!e.alive)continue;
        if(e.windup>0&&e.kind>0&&e.kind<3&&clear_line(e.x,e.y,e.tx,e.ty)&&clear_line(e.x,e.y,p.x,p.y)){draw_set_alpha(.32+sin(ticks)*.15);draw_set_colour(col(0xffa878));draw_line(e.x,e.y,e.tx,e.ty);draw_set_alpha(1);}
        if(e.stun>0)draw_sprite_ext(actors[e.kind+1],0,e.x,e.y,1.15,.6,e.angle+80,col(0xc5b5ac),1);
        else draw_actor(e.x,e.y,e.angle,e.kind+1,e.frame);
        draw_enemy_status(e);
        if(e.alert>0){text_at(e.x,e.y-24,e.windup>0?"!":"·",font_small,e.windup>0?col(0xffda87):col(0xf7839d),fa_center);}
    }
    for(var i=0;i<array_length(ghosts);i++){var q=ghosts[i];draw_sprite_ext(actors[0],floor(q.frame) mod 8,q.x,q.y,1,1,q.angle,mint,q.life/25);}
    if(state!="dead") draw_actor(p.x,p.y,p.angle,0,p.frame,p.inv>0 && floor(ticks/4) mod 2==0?.4:1);
    else draw_sprite_ext(actors[0],0,p.x,p.y,1.2,.65,p.angle+80,col(0xaa7992),1);
    if(melee_timer>7){draw_set_colour(col(0xeaf7d9));draw_set_alpha(.85);for(var a=-45;a<46;a+=10)draw_line(p.x+lengthdir_x(20,p.angle+a),p.y+lengthdir_y(20,p.angle+a),p.x+lengthdir_x(33,p.angle+a+12),p.y+lengthdir_y(33,p.angle+a+12));draw_set_alpha(1);}
    for(var i=0;i<array_length(bullets);i++){var b=bullets[i];draw_set_colour(b.enemy?col(0xff858d):col(0xffe7a7));draw_line_width(b.px,b.py,b.x,b.y,2);}
    for(var i=0;i<array_length(particles);i++){var q=particles[i];box(q.x,q.y,q.sz,q.sz,q.colour,min(1,q.life/8));}
    for(var i=0;i<array_length(muzzles);i++){var q=muzzles[i],len=q.kind==2?27:17;
        draw_set_colour(col(0xffd18b));draw_set_alpha(q.life/4);
        draw_triangle(q.x+lengthdir_x(5,q.angle+90),q.y+lengthdir_y(5,q.angle+90),q.x+lengthdir_x(len,q.angle),q.y+lengthdir_y(len,q.angle),q.x+lengthdir_x(5,q.angle-90),q.y+lengthdir_y(5,q.angle-90),false);
        draw_set_colour(c_white);draw_circle(q.x,q.y,3,false);draw_set_alpha(1);
    }
    // Limited additive light accents preserve readable silhouettes and a consistent palette.
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(glow_sprite,0,p.x,p.y,1.2,1.2,0,col(0x80a8ac),.11);
    for(var i=0;i<4;i++)draw_sprite_ext(glow_sprite,0,175+i*219,310,1.8,.8,0,i mod 2==0?col(0xc54c8a):col(0x4bbfbf),.34+sin(ticks*.03+i)*.035);
    var goal=floor_index==0?room_data.stairs:room_data.exit;
    if(kills==total_enemies)draw_sprite_ext(glow_sprite,0,goal[0],goal[1],1.5,1.5,0,col(0x88ffc7),.5);
    for(var i=0;i<array_length(muzzles);i++){var q=muzzles[i];draw_sprite_ext(glow_sprite,0,q.x,q.y,1.1,1.1,0,col(0xffb563),q.life*.16);}
    gpu_set_blendmode(bm_normal);

    for(var i=0;i<array_length(floaters);i++){var q=floaters[i];text_at(q.x,q.y,q.text,font_small,col(0xffd897),fa_center);}
    if(state=="play") {
        draw_set_colour(col(0xffeece));draw_circle(mouse_x,mouse_y,5,true);
        draw_line(mouse_x-9,mouse_y,mouse_x-4,mouse_y);draw_line(mouse_x+4,mouse_y,mouse_x+9,mouse_y);
        draw_line(mouse_x,mouse_y-9,mouse_x,mouse_y-4);draw_line(mouse_x,mouse_y+4,mouse_x,mouse_y+9);
    }
}
function ui_button(_x,_y,_w,_text,_active=true) {
    var hover=point_in_rectangle(device_mouse_x_to_gui(0),device_mouse_y_to_gui(0),_x,_y,_x+_w,_y+43);
    box(_x,_y,_w,43,_active?(hover?col(0xffadc1):pink):col(0x323346));
    text_at(_x+17,_y+10,_text,font_ui,_active?ink:cream);
    return _active&&hover&&mouse_check_button_pressed(mb_left);
}
function draw_hud() {
    var accent=pink;
    box(0,0,960,67,ink,.90);box(26,22,3,30,pink);
    text_at(40,18,"0"+string(level+1)+" / "+level_names[level],font_ui,cream);
    text_at(40,42,objective_text(),font_small,kills==total_enemies?mint:muted_col);
    text_at(930,18,string(kills)+" / "+string(total_enemies),font_ui,cream,fa_right);
    text_at(930,42,"ЦЕЛИ   •   "+string_format(elapsed,0,1)+" s",font_small,muted_col,fa_right);
    box(0,480,960,60,ink,.92);
    draw_sprite_ext(weapon_sprite,weapon,38,503,1.7,1.7,0,c_white,1);
    text_at(88,492,weapon_name(weapon),font_small,weapon==0?cream:(weapon==1?mint:pink));
    text_at(88,512,"E ОРУЖИЕ  /  F ДВЕРЬ",font_small,cream);
    text_at(930,488,reload_timer>0?"ПЕРЕЗАРЯДКА":string(ammo)+" / "+string(weapon_capacity(weapon)),font_ui,ammo>0?cream:pink,fa_right);
    box(752,519,178,3,col(0x3e3b50));box(752,519,178*(reload_timer>0?1-reload_timer/(weapon==2?58:36):ammo/weapon_capacity(weapon)),3,reload_timer>0?pink:mint);
    for(var i=0;i<p.maxhealth;i++) {box(441+i*17,498,10,10,i<p.health?pink:col(0x444154));}
    box(425,523,110,3,col(0x444154));box(425,523,110*(1-dash_cool/36),3,mint);
    text_at(480,481,"SPACE / РЫВОК",font_small,muted_col,fa_center);
    if(combo>1){text_at(930,84,"×"+string(combo),font_big,pink,fa_right);text_at(928,195,"ЦЕПЬ УБИЙСТВ",font_small,cream,fa_right);box(811,215,117*combo_timer/180,2,pink);}
    text_at(28,83,string_format(run_score,6,0),font_ui,cream);
    if(pickup_near>=0&&state=="play")text_at(480,446,"[ E ]  "+weapon_name(drops[pickup_near].kind),font_ui,mint,fa_center);
    if(state=="play") {
        var goal=floor_index==0?room_data.stairs:room_data.exit;
        if(point_distance(p.x,p.y,goal[0],goal[1])<36)text_at(480,416,kills<total_enemies?"СНАЧАЛА ЗАЧИСТИ ЭТАЖ":(floor_index==0?"[ F ] ПОДНЯТЬСЯ НА 2 ЭТАЖ":"[ F ] ЗАВЕРШИТЬ АДРЕС"),font_ui,mint,fa_center);
        else {var di=nearest_door(p.x,p.y,36);if(di>=0)text_at(480,416,doors[di].target==0?"[ F ] ОТКРЫТЬ ДВЕРЬ":"[ F ] ЗАКРЫТЬ ДВЕРЬ",font_ui,mint,fa_center);}
    }
    if(intro>0&&state=="play") {
        var alpha=min(1,intro/20);draw_set_alpha(alpha);
        if(kills==total_enemies){box(268,90,424,58,ink,.88);text_at(480,104,floor_index==0?"ЭТАЖ ЗАЧИЩЕН / К ЛЕСТНИЦЕ":"ЭТАЖ ЗАЧИЩЕН / К ВЫХОДУ",font_ui,mint,fa_center);}
        else {box(276,89,408,48,ink,.86);text_at(480,101,level_subtitles[level],font_ui,cream,fa_center);}
        draw_set_alpha(1);
    }
}
function draw_ui() {
    if(state=="hub"||state=="shop"){draw_hub_ui();return;}
    if(state=="dialogue"){draw_dialogue();return;}
    if(state=="menu") {
        draw_sprite(title_sprite,0,0,0);
        box(31,28,28,3,pink);text_at(71,18,"A MIDNIGHT TRANSMISSION",font_small,cream);
        text_at(39,81,"DEAD",font_title,cream);text_at(36,179,"FREQUENCY",font_title,pink);
        text_at(43,322,"ОДНА НОЧЬ. ШЕСТЬ АДРЕСОВ. НИКАКИХ ВОПРОСОВ.",font_small,cream);
        if(ui_button(43,363,322,"НАЧАТЬ СМЕНУ     [ ENTER ]")||keyboard_check_pressed(vk_enter))start_chapter(selected_level);
        if(ui_button(618,363,300,"МАСТЕРСКАЯ     [ V ]")||keyboard_check_pressed(ord("V")))enter_hub(hub_next);
        text_at(43,420,"ГЛАВА",font_small,muted_col);
        for(var i=0;i<array_length(level_data);i++) {
            var xx=111+i*47;box(xx,416,41,28,i==selected_level?pink:col(0x28313f));
            text_at(xx+20,419,i<=unlocked?"0"+string(i+1):"—",font_ui,i==selected_level?ink:cream,fa_center);
            if(i<=unlocked&&mouse_check_button_pressed(mb_left)&&point_in_rectangle(device_mouse_x_to_gui(0),device_mouse_y_to_gui(0),xx,416,xx+41,444))selected_level=i;
        }
        text_at(43,471,"WASD  ДВИЖЕНИЕ    МЫШЬ  ПРИЦЕЛ    ЛКМ  ОГОНЬ",font_small,cream);
        text_at(43,490,"SPACE РЫВОК  ПКМ НОЖ  E ОРУЖИЕ  F ДВЕРЬ / ЛЕСТНИЦА",font_small,muted_col);
        text_at(930,487,"F1  "+(assist?"2 ПОПАДАНИЯ":"1 ПОПАДАНИЕ"),font_small,mint,fa_right);
        text_at(930,508,"M  "+(muted?"ЗВУК ВЫКЛ":"ЗВУК ВКЛ")+"   /   F11 ЭКРАН",font_small,cream,fa_right);
        box(43,531,870,1,col(0x795169));
        return;
    }
    draw_sprite_stretched(vignette_sprite,0,0,0,960,540);
    draw_hud();draw_grapple();
    if(flash>0)box(0,0,960,540,pink,flash);
    if(state=="dead") {
        box(0,67,960,413,ink,.70);box(42,179,5,151,pink);
        text_at(67,169,"СИГНАЛ",font_big,cream);text_at(64,235,"ПОТЕРЯН",font_big,pink);
        text_at(69,324,"ЕЩЕ ОДНА ПОПЫТКА. БЕЗ ОЖИДАНИЯ.",font_small,cream);
        if(ui_button(69,363,325,"ПОПРОБОВАТЬ СНОВА    [ R ]"))restart_floor();
        text_at(925,431,"ESC  /  МЕНЮ",font_small,muted_col,fa_right);
    }
    if(state=="pause") {
        box(0,67,960,413,ink,.92);text_at(480,124,"ТИШИНА В ЭФИРЕ",font_big,cream,fa_center);
        if(ui_button(318,226,324,"ПРОДОЛЖИТЬ     [ ESC ]")){state="play";set_music();}
        text_at(480,301,"M   ЗВУК: "+(muted?"ВЫКЛ":"ВКЛ"),font_ui,cream,fa_center);
        text_at(480,334,"F2   ТРЯСКА: "+(shake_on?"ВКЛ":"ВЫКЛ")+"     F3   КРОВЬ: "+(blood_on?"ВКЛ":"ВЫКЛ"),font_small,muted_col,fa_center);
        text_at(480,378,"F1   "+(assist?"ПОМОЩЬ: ДВА ПОПАДАНИЯ":"КЛАССИКА: ОДНО ПОПАДАНИЕ")+"  (СО СЛЕДУЮЩЕЙ ПОПЫТКИ)",font_small,mint,fa_center);
        text_at(480,433,"BACKSPACE  /  В ГЛАВНОЕ МЕНЮ",font_small,muted_col,fa_center);
    }
    if(state=="clear") {
        box(0,0,960,540,ink,.94);text_at(42,32,"СМЕНА 0"+string(level+1)+" / ЗАВЕРШЕНА",font_small,mint);
        text_at(39,87,level==array_length(level_data)-1?"КОНЕЦ ЭФИРА":"ЛИНИЯ ЧИСТА",font_big,cream);
        var rank=elapsed<55?"S":(elapsed<95?"A":(elapsed<150?"B":"C"));
        text_at(914,90,rank,font_title,pink,fa_right);
        box(44,198,870,2,pink);
        text_at(45,228,"ОЧКИ",font_small,muted_col);text_at(45,254,string(run_score),font_big,cream);
        text_at(358,228,"ВРЕМЯ",font_small,muted_col);text_at(358,254,string_format(elapsed,0,1)+"s",font_big,cream);
        text_at(687,228,"ЦЕЛИ",font_small,muted_col);text_at(687,254,string(chapter_kills+kills),font_big,cream);
        text_at(45,355,"ОПЛАТА: $ "+string(payout)+"   /   НА СЧЁТЕ: $ "+string(wallet),font_ui,mint);
        if(ui_button(45,402,386,"В МАСТЕРСКУЮ    [ ENTER ]")||keyboard_check_pressed(vk_enter)) {
            enter_hub(level<5?level+1:0);
        }
        text_at(916,492,"R ПЕРЕИГРАТЬ   /   РЕКОРД "+string(best),font_small,mint,fa_right);
    }
    // Fine CRT lines are deliberately subdued; never obscure combat.
    for(var scan=0;scan<540;scan+=3)box(0,scan,960,0,c_black,.035);
}
