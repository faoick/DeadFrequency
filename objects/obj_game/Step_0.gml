if(perf_mode){perf_step();exit;}
var step_start_us=test_mode?get_timer():0;
var dt=clamp(delta_time/16666.667,.1,2);ticks+=dt;
if(state=="play"&&!window_has_focus()&&!test_mode){state="pause";set_music();}
if(keyboard_check_pressed(vk_f11))window_set_fullscreen(!window_get_fullscreen());
if(keyboard_check_pressed(ord("M"))){muted=!muted;audio_master_gain(muted?0:1);set_music();save_progress();}
if(keyboard_check_pressed(vk_f1)){assist=!assist;save_progress();}
if(keyboard_check_pressed(vk_f2)){shake_on=!shake_on;save_progress();}
if(keyboard_check_pressed(vk_f3)){blood_on=!blood_on;if(!blood_on)decals=[];save_progress();}
if(keyboard_check_pressed(vk_escape)&&state!="dialogue") {
    if(state=="play"){state="pause";set_music();}
    else if(state=="pause"){state="play";set_music();}
    else if(state=="shop")state="hub";
    else if(state=="hub")state="menu";
    else if(state=="dead"||state=="clear"){state="menu";set_music();}
    else if(state=="menu")game_end();
}
if(state=="pause"&&keyboard_check_pressed(vk_backspace)){state="menu";set_music();}
if((state=="dead"||state=="clear")&&keyboard_check_pressed(ord("R")))restart_floor();
if(state=="dialogue")step_dialogue(dt);else if(state=="play")step_game(dt);else if(state=="arrival")step_arrival(dt);else if(state=="hub")step_hub(dt);
if(state!="pause"&&state!="dialogue")step_effects(dt);
if(state=="dead")death_timer+=dt;
var lookx=clamp((mouse_x-p.x)*.13,-65,65),looky=clamp((mouse_y-p.y)*.13,-40,40);
camx=lerp(camx,clamp(p.x-320+lookx,0,320),1-power(.9,dt));camy=lerp(camy,clamp(p.y-180+looky,0,320),1-power(.9,dt));
camera_set_view_pos(camera,round(camx+(shake_on?random_range(-shake,shake):0)),round(camy+(shake_on?random_range(-shake,shake):0)));
window_set_cursor(state=="play"?cr_none:cr_default);
if(test_mode){
    if(test_frame>20){var measured_us=get_timer()-step_start_us;test_step_us+=measured_us;test_step_max_us=max(test_step_max_us,measured_us);test_step_samples++;}
    test_frame++;smoke_test_step();
}
