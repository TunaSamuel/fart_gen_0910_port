// argument0: 使用するサウンドリストのindex
// argument1: ピッチ変化幅
// 戻り値: 再生したサウンドのindex

if( ds_list_size( argument0 ) == 0) return -1;

var rand, pitch;
rand = floor( random( ds_list_size( argument0 )) );
rand = ds_list_find_value( argument0, rand );
pitch = max( 0, min( 1, argument1 ));

// 再生！
if( global.use_extra_sound_system == 1 ){
    SS_PlaySound( rand );
//    show_debug_message("SS_PlaySound executed!");
}else if( global.use_extra_sound_system == 2){
    rand = FMODSoundPlay( rand, false );
//  ピッチ変更？
    pitch = random(pitch*2) + 1 - pitch
    FMODInstanceSetPitch(rand, pitch );
    show_debug_message("FMOD_SOUND_PLAY  --- pitch +" + string(pitch) );
}else{
    sound_play( rand );
}
return rand;


