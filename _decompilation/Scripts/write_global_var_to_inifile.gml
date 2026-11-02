ini_open(INI_FILE_NAME);

// Shake関連
ini_write_real("Effect", "Shake", global.shake);
ini_write_real("Effect", "ShakeSpeed",global.shake_speed);
ini_write_real("Effect", "ShakeSynchro", global.shake_synchro);

// ファイル読み込み関連
ini_write_string("Directory", "ImageDir", global.image_dir );
ini_write_real("Directory", "ReadRecursive", global.read_recursive);

// ヘルプメッセージを表示？
ini_write_real("Parameter", "ShowOSD",global.show_osd);

// スライドショーの画像切替時間
ini_write_real("Parameter", "SlideshowInterval", global.slideshow_interval);

// メモリー時間の指定  
ini_write_real("Parameter", "MemoryTime",global.memory_time_max );
 
// 発射から次回の発射までの待ち時間
ini_write_real("AutoFire", "IntervalMin", global.emit_interval_min / room_speed);

ini_write_real("AutoFire", "IntervalMax", global.emit_interval_max / room_speed);

// 発射時間
ini_write_real("AutoFire", "EmitTimeMin", global.emit_time_min / room_speed);

ini_write_real("AutoFire", "EmitTimeMax", global.emit_time_max / room_speed);
 
// この回数だけ放屁したら、画像を切り替える
ini_write_real("AutoFire", "CountToChangeImage", global.fart_until_changing_img);

// 音とエフェクトをシンクロさせる
ini_write_real("Parameter", "SynchroMode", global.synchro_mode);

// オナラ音のピッチを弄る
ini_write_real("Parameter", "FartPitchRandom", global.fart_sound_pitch);

// ボイスのピッチを弄る
ini_write_real("Parameter", "VoicePitchRandom", global.voice_pitch);

ini_close();

