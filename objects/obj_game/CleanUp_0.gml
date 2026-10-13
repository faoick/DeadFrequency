for(var i=0;i<array_length(actors);i++)sprite_delete(actors[i]);
for(var i=0;i<array_length(backgrounds);i++)sprite_delete(backgrounds[i]);
sprite_delete(glow_sprite);sprite_delete(title_sprite);
sprite_delete(vignette_sprite);
font_delete(font_small);font_delete(font_ui);font_delete(font_big);font_delete(font_title);
camera_destroy(camera);audio_stop_all();

sprite_delete(weapon_sprite);sprite_delete(blood_sprite);

for(var i=0;i<array_length(upper_backgrounds);i++)sprite_delete(upper_backgrounds[i]);
for(var i=0;i<array_length(portraits);i++)sprite_delete(portraits[i]);
font_delete(font_dialogue);

sprite_delete(workshop_sprite);
