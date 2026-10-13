draw_ui();

if(perf_mode&&perf_frame>60)array_push(perf_draw,(get_timer()-perf_draw_start)/1000);
