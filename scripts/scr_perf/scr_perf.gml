/// Opt-in repeatable moving-player benchmark, without profile writes.
function perf_stats(_values) {
    var sorted=array_sort_copy(_values),count=array_length(sorted),sum=0,over=0;
    for(var i=0;i<count;i++){sum+=sorted[i];if(sorted[i]>16.667)over++;}
    return {mean_ms:sum/max(1,count),p95_ms:sorted[floor((count-1)*.95)],p99_ms:sorted[floor((count-1)*.99)],max_ms:sorted[count-1],over_16ms:over};
}
function array_sort_copy(_values) {var result=[];array_copy(result,0,_values,0,array_length(_values));array_sort(result,true);return result;}
function perf_step() {
    if(perf_frame==0){
        random_set_seed(417);load_level(0);audio_master_gain(0);
        for(var i=0;i<array_length(doors);i++){doors[i].open=1;doors[i].target=1;}
        p.x=180;p.y=318;p.inv=999999;intro=0;update_flow();
    }
    var started=get_timer();
    // Identical fixed-step workload before/after; delta_time records delivered frames separately.
    ticks++;p.x=180+abs(((perf_frame*4) mod 1200)-600);p.y=318;p.inv=999999;
    for(var i=0;i<array_length(enemies);i++)enemies[i].alert=300;
    step_game(1);
    if(perf_frame mod 4==0)burst(p.x,p.y,0,8,true);
    step_effects(1);camx=clamp(p.x-320,0,320);camy=138;camera_set_view_pos(camera,camx,camy);
    if(perf_frame>60){array_push(perf_cpu,(get_timer()-started)/1000);array_push(perf_delta,delta_time/1000);}
    perf_frame++;
    if(perf_frame==721){
        var result={scenario:"13 alert guards, open doors, moving target, blood effects, 660 measured frames",step:perf_stats(perf_cpu),frame_interval:perf_stats(perf_delta),draw:perf_stats(perf_draw),navigation:perf_stats(perf_nav)};
        var f=file_text_open_write("perf_result.json");file_text_write_string(f,json_stringify(result));file_text_close(f);game_end();
    }
}
