// 再生中の音声の音量を返す
// FMODSoundSystemのみ対応。それ以外のシステムでは，常に1を返す
if( global.use_extra_sound_system == 2 ){
    var t;
    t = max( WavMaxTest(global.prev_fart_sound), 0.01);
    //show_debug_message( "get_sound_level ..." + string(t));
    return t;

}else{
    return 1;
}


