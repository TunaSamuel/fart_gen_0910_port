// room生成時に、gas_generatorオブジェクト生成イベントで呼ばれる
show_debug_message("obj_gas_generator creation code called");

// Globalな変数をINIファイルから読み込み
read_global_var_from_inifile();
show_debug_message("read inifile to global variables");

// SSスクリプトを使用するために初期化
if( global.use_extra_sound_system == 1 )
    SS_Init();
else if( global.use_extra_sound_system == 2 ){
    LoadFMOD();
    FMODinit(100, false);
}


// ボタンを作成
if( global.room_restarted ){
  instance_create(0, 0, obj_set_hole);
  
  instance_create(0, 0, obj_load_image);
  
  instance_create(0, 0, obj_auto_fire);
  
  instance_create(0, 0, obj_hide_button);
  
  instance_create(0, 0, obj_memory);
  
  instance_create(0, 0, obj_mode_pattern_viewer);
  
  instance_create(0, 0, obj_sound_container);
  
  instance_create(0, 0, obj_voice_container);
  
  instance_create(0, 0, obj_gas_num_editor);
  
  instance_create(0, 0, obj_gas_size_editor);
  
  instance_create(0, 0, obj_gas_speed_editor);
  
  instance_create(0, 0, obj_gas_amount_editor);
  
  instance_create(0, 0, obj_color_selector);

  instance_create(0, 0, obj_debug_window);
}
