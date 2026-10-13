function test_assert(_condition,_message) {
    var log_file=file_text_open_append("smoke_checks.txt");file_text_write_string(log_file,(_condition?"PASS ":"FAIL ")+_message);file_text_writeln(log_file);file_text_close(log_file);
    if(!_condition){show_debug_message("TEST FAIL: "+_message);array_push(test_failures,_message);}
    else show_debug_message("TEST PASS: "+_message);
}
function test_v4() {
    load_level(0);p.inv=99999;
    var g=panes[0],gx=g.r[0]+g.r[2]/2,gy=g.r[1]+g.r[3]/2;
    test_assert(solid_at(gx,gy,9)&&!solid_at(gx,gy,1),"glass blocks bodies but permits sight");
    fire_bullet(gx,gy+18,90,false,0);for(var n=0;n<3;n++)step_game(1);
    test_assert(g.broken&&array_length(shards)==28&&!solid_at(gx,gy,9),"bullet shatters pane and opens shortcut");
    load_level(0);var boss=enemies[array_length(enemies)-1];
    damage_enemy(boss,1,0);test_assert(boss.alive&&boss.hp==7,"enforcer survives a pistol hit");
    boss.hitcool=0;boss.stun=50;damage_enemy(boss,2,0);test_assert(boss.hp==4,"stunned enforcer takes extra damage");
    p.inv=0;dash_timer=0;test_assert(start_grab(boss),"enforcer can grab vulnerable player");
    grapple_input(ord("D"));test_assert(grab_progress==0,"wrong grapple key does not advance escape");
    for(var n=0;n<6&&!is_undefined(grabber);n++)grapple_input(grab_key);
    test_assert(is_undefined(grabber)&&boss.stun>=90&&p.inv>0,"alternating keys escape and stun enforcer");
    boss.hitcool=0;boss.hp=20;p.inv=0;start_grab(boss);grab_timer=1;p.health=1;step_grapple(2);
    test_assert(state=="dead","failed grapple is lethal in classic mode");
    load_level(0);var e=enemies[0],initial_x=e.x,initial_y=e.y;e.wait=0;
    for(var n=0;n<100;n++)patrol_enemy(e,1);
    test_assert(point_distance(e.x,e.y,initial_x,initial_y)>10,"idle guard walks a patrol route");
    e.wait=50;var heading=e.angle;for(var n=0;n<20;n++)patrol_enemy(e,1);
    test_assert(e.angle==heading,"waiting guard keeps a stable heading");
    load_level(0);p.x=240;p.y=316;var guard=enemies[0];guard.x=245;guard.y=270;guard.hp=1;
    kick_door(p.x,p.y);for(var n=0;n<12;n++)step_doors(1);
    test_assert(guard.alive&&guard.stun>0,"kicked hinged door knocks down a guard without killing him");
    test_assert(doors[0].open==1&&!door_blocks(doors[0],guard.x,guard.y,9),"kick pushes guard clear and fully opens leaf");
    test_assert(doors[0].open>0&&max(doors[0].w,doors[0].h)==40,"hinged door retains full leaf length");
    for(var lv=0;lv<6;lv++){
        load_level(lv);test_assert(p.y>570,"contract starts outside building "+string(lv));
        test_assert(room_data.stairs[0]>800&&!solid_at(room_data.stairs[0],room_data.stairs[1],9),"deep staircase clear "+string(lv));
        load_level(lv,1);test_assert(p.x==room_data.stairs[0]&&p.y==room_data.stairs[1],"spawn on upstairs staircase "+string(lv));
        for(var j=0;j<array_length(enemies);j++)test_assert(!clear_line(p.x,p.y,enemies[j].x,enemies[j].y),"landing is occluded from guard "+string(lv)+":"+string(j));
        for(var n=0;n<120;n++)step_game(1);
        test_assert(state=="play"&&p.health==p.maxhealth,"safe landing has no immediate attack "+string(lv));
    }
    wallet=1000;owned_weapons=1;selected_weapon=0;armor_ready=false;enter_hub(1);
    test_assert(clear_path(p.x,p.y,480,236,9)&&clear_path(p.x,p.y,480,566,9),"workshop connects counter and car with body clearance");
    test_assert(buy_item(1)&&wallet==650&&selected_weapon==1,"SMG purchase deducts price and equips");
    buy_item(1);test_assert(wallet==650,"owned weapon can be selected free");
    test_assert(buy_item(3)&&wallet==450&&armor_ready,"single-contract armor purchase");
    test_assert(!buy_item(3)&&wallet==450,"prepared armor cannot be bought twice");
    test_assert(!buy_item(2)&&wallet==450,"insufficient funds cannot buy shotgun");
    start_chapter(1);end_dialogue();test_assert(state=="arrival"&&weapon==1&&p.maxhealth==(assist?3:2)&&!armor_ready,"car deploys bought equipment and consumes armor");
    step_arrival(60);test_assert(state=="play"&&p.y==room_data.spawn[1],"arrival animation finishes at exterior spawn");
    load_level(0,1);kills=total_enemies;var cash_before=wallet;finish_level();var cash_after=wallet;finish_level();
    test_assert(cash_after>cash_before&&wallet==cash_after,"contract payout cannot be claimed twice");
    load_level(0);state="menu";
}
function smoke_test_step() {
    if(test_frame==1){
        var log_file=file_text_open_write("smoke_checks.txt");file_text_close(log_file);
        var report=file_text_open_write("smoke_result.txt");file_text_write_string(report,"RUNNING");file_text_close(report);
        test_assert(audio_sound_length(snd_night_drive)>23,"160 BPM soundtrack is imported with full duration");
        test_assert(audio_sound_length(snd_smg)>.1,"SMG has its own imported sound");
        test_assert(audio_sound_length(snd_shot)>.15,"gunshot audio is imported");
        load_level(0);audio_master_gain(0);
        test_assert(array_length(enemies)==13,"level 1 has twelve guards and an enforcer");
        test_assert(!solid_at(p.x,p.y,6),"player spawn is clear");
        test_assert(solid_at(75,120,6),"exterior walls are solid");
        test_assert(!clear_line(100,200,400,200),"interior walls block sight and bullets");
        var actor={x:100,y:120};move_actor(actor,-200,0);test_assert(actor.x>85,"substeps prevent wall tunnelling");
        update_flow();var seeded=false;for(var n=0;n<array_length(nav_dist);n++)if(nav_dist[n]==0)seeded=true;
        test_assert(seeded,"navigation seeds a clear cell reachable from the player");
        var e=enemies[0];kill_enemy(e,0);test_assert(!e.alive&&kills==1&&run_score==100,"kill registers run_score and state");
        kill_enemy(e,0);test_assert(kills==1,"dead enemies cannot run_score twice");
        test_assert(array_length(bodies)==1&&array_length(drops)>=3,"kill produces body and weapon");
        p.inv=0;dash_timer=3;hurt_player(0);test_assert(state=="play","dash protects player");
        dash_timer=0;p.health=1;hurt_player(0);test_assert(state=="dead","lethal hit ends attempt");
        load_level(0);test_assert(kills==0&&array_length(bullets)==0&&array_length(bodies)==0,"restart resets combat state");
        load_level(1);test_assert(array_length(enemies)==15,"level 2 loads");
        load_level(2);test_assert(array_length(enemies)==16,"level 3 loads");
        for(var room_index=0;room_index<array_length(level_data)*2;room_index++) {
            var lv=room_index div 2,fl=room_index mod 2;load_level(lv,fl);
            update_flow();
            test_assert(!solid_at(p.x,p.y,9),"player spawn clear "+string(lv));
            for(var j=0;j<array_length(enemies);j++) {
                var e=enemies[j];
                test_assert(!solid_at(e.x,e.y,9),"enemy footprint clear "+string(lv)+":"+string(fl)+":"+string(j));
                var reachable=false,gx=floor(e.x/8),gy=floor(e.y/8);
                for(var yy=max(0,gy-2);yy<=min(79,gy+2);yy++)for(var xx=max(0,gx-2);xx<=min(119,gx+2);xx++)
                    if(nav_dist[yy*120+xx]<9999&&clear_path(e.x,e.y,xx*8+4,yy*8+4,9,false))reachable=true;
                test_assert(reachable,"enemy has doorway route "+string(lv)+":"+string(fl)+":"+string(j));
            }
        }
        // Regression: a shot already winding up must cancel after the target hides.
        load_level(0);var guard=enemies[0];guard.kind=1;guard.x=330;guard.y=200;
        guard.windup=1;guard.cool=0;guard.tx=420;guard.ty=180;p.x=420;p.y=180;
        update_enemy_attack(guard,1,clear_line(guard.x,guard.y,p.x,p.y),100);
        test_assert(guard.windup==0&&array_length(bullets)==0,"hidden target cancels pending shot");
        guard.windup=1;guard.cool=0;guard.tx=420;guard.ty=180;
        p.x=310;p.y=210;
        update_enemy_attack(guard,1,true,25);
        test_assert(array_length(bullets)==0,"locked aim point behind wall cannot fire");
        guard.x=170;guard.y=530;guard.tx=230;guard.ty=530;guard.windup=1;guard.cool=0;p.x=230;p.y=530;
        update_enemy_attack(guard,1,true,60);
        test_assert(array_length(bullets)==1,"visible target still receives a shot");
        load_level(0);var runner={x:330,y:200};
        for(var n=0;n<20;n++){move_actor(runner,18,3);test_assert(!solid_at(runner.x,runner.y,9),"fast diagonal movement keeps full body outside walls");}
        // Chase every spawn to the entrance, exercising real movement + grid connectors.
        for(var room_index=0;room_index<array_length(level_data)*2;room_index++) {
            var lv=room_index div 2,fl=room_index mod 2;load_level(lv,fl);update_flow();
            for(var j=0;j<array_length(enemies);j++) {
                var e=enemies[j];
                for(var n=0;n<1000&&point_distance(e.x,e.y,p.x,p.y)>20;n++){chase_enemy(e,3);step_doors(1);}
                test_assert(!solid_at(e.x,e.y,9),"chaser never ends inside geometry "+string(lv)+":"+string(fl)+":"+string(j));
                test_assert(point_distance(e.x,e.y,p.x,p.y)<22,"chaser reaches player through doors "+string(lv)+":"+string(fl)+":"+string(j)+" at "+string(e.x)+","+string(e.y));
            }
        }
        load_level(0);kill_enemy(enemies[0],0);var marks=array_length(decals);
        for(var n=0;n<180;n++)step_effects(1);
        test_assert(array_length(decals)>=marks&&array_length(bodies)==1,"blood and corpse persist after particles finish");
        load_level(0);p.inv=99999;
        var target=enemies[0];target.x=180;target.y=530;target.alert=0;target.windup=0;
        fire_bullet(146,530,0,false,0);
        for(var n=0;n<5;n++)step_game(1);
        test_assert(!target.alive,"a moving player bullet hits and kills its target");
        load_level(0);p.inv=99999;
        fire_bullet(86,240,180,false,0);
        for(var n=0;n<3;n++)step_game(1);
        test_assert(array_length(bullets)==0,"a projectile is destroyed at a wall");
        reload_timer=1;ammo=0;step_game(1);test_assert(ammo==12,"reload fills the correct magazine");
        // Closed panels participate in movement, line of sight and bullets.
        load_level(0);p.x=240;p.y=316;p.inv=99999;
        test_assert(solid_at(240,287,1),"closed door is solid");
        test_assert(!clear_line(240,260,240,316),"closed door blocks line of sight");
        var walker={x:240,y:316};move_actor(walker,0,-80);
        test_assert(walker.y>=299&&!door_blocks(doors[0],walker.x,walker.y,9),"movement cannot pass through a closed door");
        fire_bullet(240,267,270,false,0);for(var n=0;n<4;n++)step_game(1);
        test_assert(array_length(bullets)==0,"closed door stops bullets");
        set_door(0,1);step_doors(6);test_assert(doors[0].open>0&&doors[0].open<1,"door opens with visible animation");
        step_doors(20);test_assert(clear_line(240,260,240,316),"fully opened door permits sight");
        move_actor(walker,0,-60);test_assert(walker.y<282,"fully opened door permits movement");
        p.x=240;p.y=287;test_assert(!set_door(0,0),"door cannot close on player");
        p.x=240;p.y=316;test_assert(set_door(0,0),"unoccupied door can close");step_doors(20);
        test_assert(solid_at(240,287,1),"closed door restores collision");
        var pursuer={x:240,y:316,frame:0,angle:90};p.x=240;p.y=235;update_flow();
        for(var n=0;n<80;n++){chase_enemy(pursuer,2);step_doors(1);}
        test_assert(pursuer.y<282&&doors[0].open==1,"enemy opens door and crosses threshold");
        load_level(0);p.x=room_data.stairs[0];p.y=room_data.stairs[1];
        test_assert(!advance_floor()&&floor_index==0,"staircase waits for floor clearance");
        kills=total_enemies;weapon=2;ammo=3;p.health=1;run_score=1234;elapsed=23;
        test_assert(advance_floor(),"cleared floor leads upstairs");
        test_assert(floor_index==1&&weapon==2&&ammo==3&&p.health==1,"stairs preserve weapon ammunition and health");
        test_assert(run_score==1234&&elapsed==23&&chapter_kills==13,"stairs preserve chapter score time and kill count");
        test_assert(state=="dialogue","stair landing has a radio scene");
        var old_enemy_x=enemies[0].x,old_time=elapsed;step_dialogue(1);
        test_assert(enemies[0].x==old_enemy_x&&elapsed==old_time,"dialogue freezes combat and the clock");
        end_dialogue();weapon=1;ammo=0;run_score=9999;elapsed=40;p.inv=0;p.health=1;hurt_player(0);restart_floor();
        test_assert(floor_index==1&&weapon==2&&ammo==3&&run_score==1234&&elapsed==23,"death retries current floor with its original checkpoint");
        test_assert(chapter_kills==13&&kills==0&&array_length(bodies)==0,"checkpoint does not duplicate prior kills or corpses");
        for(var n=0;n<array_length(doors);n++)test_assert(doors[n].open==0,"checkpoint resets doors");
        begin_dialogue(story_data.intro[0],"play");next_dialogue();
        test_assert(dialogue_index==0&&dialogue_chars==string_length(dialogue_lines[0].text),"first dialogue input reveals the whole line");
        while(state=="dialogue"){dialogue_chars=999;next_dialogue();}
        test_assert(state=="play","finishing dialogue returns to gameplay");
        load_level(5,1);kills=total_enemies;finish_level();
        test_assert(state=="dialogue"&&dialogue_resume=="clear","final chapter plays the ending");
        end_dialogue();test_assert(state=="clear","skipping ending still reaches results");
        test_v4();load_level(0);state="menu";
    }
    if(test_frame==20){screen_save("smoke_menu.png");start_chapter(0);dialogue_chars=999;}
    if(test_frame==50){screen_save("smoke_dialogue.png");end_dialogue();p.inv=99999;}
    if(test_frame==70)screen_save("smoke_arrival.png");
    if(test_frame==80){step_arrival(60);screen_save("smoke_game.png");p.x=240;p.y=316;intro=0;}
    if(test_frame==100){screen_save("smoke_door_closed.png");set_door(0,1);}
    if(test_frame==125){screen_save("smoke_door_open.png");p.x=476;p.y=318;}
    if(test_frame==140){for(var j=0;j<array_length(enemies);j++)kill_enemy(enemies[j],0);}
    if(test_frame==168){weapon=2;ammo=3;fire_bullet(p.x+29,p.y,0,false,2);}
    if(test_frame==170){screen_save("smoke_effects.png");}
    if(test_frame==180){p.x=room_data.stairs[0];p.y=room_data.stairs[1];hitstop=0;advance_floor();dialogue_chars=999;}
    if(test_frame==200){screen_save("smoke_stair_dialogue.png");end_dialogue();p.inv=99999;intro=0;}
    if(test_frame==225){screen_save("smoke_upper_floor.png");for(var j=0;j<array_length(enemies);j++)kill_enemy(enemies[j],0);}
    if(test_frame==240){p.x=room_data.exit[0];p.y=room_data.exit[1];interact_world();test_assert(state=="clear","second-floor extraction completes chapter");}
    if(test_frame==260){screen_save("smoke_clear.png");load_level(5,1);kills=total_enemies;finish_level();dialogue_chars=999;}
    if(test_frame==290){screen_save("smoke_ending.png");enter_hub(1);}
    if(test_frame==310){screen_save("smoke_workshop.png");state="shop";}
    if(test_frame==330){screen_save("smoke_shop.png");load_level(0);p.x=775;p.y=250;camx=320;camy=80;intro=0;var boss=enemies[array_length(enemies)-1];boss.alert=300;boss.boss_mode="windup";boss.boss_timer=45;p.inv=99999;}
    if(test_frame==350){screen_save("smoke_boss.png");p.inv=0;start_grab(enemies[array_length(enemies)-1]);}
    if(test_frame==360){screen_save("smoke_grapple.png");var f=file_text_open_write("smoke_result.txt");
        file_text_write_string(f,array_length(test_failures)==0?"PASS: 12 floors, 164 enemy routes with doors, door collision/occlusion/animation/AI/occupied closure, weapon+ammo+health transfer, floor checkpoints, Russian dialogue and ending, combat regressions, hinged kick + stun, glass bullet shortcut, patrol stability, enforcer HP + grapple escape/failure, 6 protected landings, car arrival, economy and armor":("FAIL: "+json_stringify(test_failures)));
        file_text_writeln(f);file_text_write_string(f,"Gameplay Step CPU: mean "+string_format(test_step_us/max(1,test_step_samples)/1000,0,3)+" ms; max "+string_format(test_step_max_us/1000,0,3)+" ms (excludes rendering, test setup and level loads)");
        file_text_close(f);game_end();}
}
