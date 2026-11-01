var tmp;

ini_open(INI_FILE_NAME);

// 画像読み込み先
global.image_dir = ini_read_string("Directory", "ImageDir", ".");

// デバッグモード？
global.debug = ini_read_real("Parameter", "Debug", 0);

// SuperSound_DLLサウンドシステムをしようするかどうか
global.use_extra_sound_system = ini_read_real("Parameter", "UseExtraSoundSystem", false);

// Shake関連
global.shake = ini_read_real("Effect", "Shake", 0);
global.shake_speed = ini_read_real("Effect", "ShakeSpeed", 1);
global.shake_synchro = ini_read_real("Effect", "ShakeSynchro", 1);

// ファイル読み込み関連
global.image_dir = ini_read_string("Directory", "ImageDir", ".");
global.ini_image_dir = ini_read_string("Directory", "ImageDirRoot", "");
global.read_recursive = ini_read_real("Directory", "ReadRecursive", false);

// ヘルプメッセージを表示？
global.show_osd = ini_read_real("Parameter", "ShowOSD", true);

// スライドショーの画像切替時間
global.slideshow_interval = ini_read_real("Parameter", "SlideshowInterval", 5);
global.slideshow_interval = min( max( global.slideshow_interval, TIME_MIN ), TIME_MAX)

// メモリー時間の指定  
global.memory_time_max = ini_read_real("Parameter", "MemoryTime", MEMORY_TIME_MAX);
 
// 発射から次回の発射までの待ち時間
tmp = ini_read_real("AutoFire", "IntervalMin", 1.0);
global.emit_interval_min = room_speed * tmp;
tmp = ini_read_real("AutoFire", "IntervalMax", 3.0);
global.emit_interval_max = room_speed * tmp;

// 発射時間
tmp = ini_read_real("AutoFire", "EmitTimeMin", 1.0);
global.emit_time_min = room_speed * tmp;
tmp = ini_read_real("AutoFire", "EmitTimeMax", 2.0);
global.emit_time_max = room_speed * tmp;

// この回数だけ放屁したら、画像を切り替える
global.fart_until_changing_img = ini_read_real("AutoFire", "CountToChangeImage", 3);

// 音とエフェクトをシンクロさせる
global.synchro_mode = ini_read_real("Parameter", "SynchroMode", false);

// オナラ音のピッチを弄る
global.fart_sound_pitch = ini_read_real("Parameter", "FartPitchRandom", true);

// ボイスのピッチを弄る
global.voice_pitch = ini_read_real("Parameter", "VoicePitchRandom", false);

ini_close();

