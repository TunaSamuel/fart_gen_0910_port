// 全サウンドを止めたい
if( global.use_extra_sound_system == 0 ){ 
    sound_stop_all();
}

else if( global.use_extra_sound_system == 1 ){
    // SuperSoundには全サウンド停止関数がないので、ゴリ押しで全部止める
    var i, j;
    // fart sound
    for( i=0; i<ds_list_size(global.list_sound_small); i+=1){
        SS_StopSound( ds_list_find_value( global.list_sound_small, i ));
    }
    for( i=0; i<ds_list_size(global.list_sound_medium); i+=1){
        SS_StopSound( ds_list_find_value( global.list_sound_medium, i ));
    }
    for( i=0; i<ds_list_size(global.list_sound_big); i+=1){
        SS_StopSound( ds_list_find_value( global.list_sound_big, i ));
    }
    for( i=0; i<ds_list_size(global.list_sound_huge); i+=1){
        SS_StopSound( ds_list_find_value( global.list_sound_huge, i ));
    }
    for( i=0; i<ds_list_size(global.list_sound_sneaky); i+=1){
        SS_StopSound( ds_list_find_value( global.list_sound_sneaky, i ));
    }
    for( i=0; i<ds_list_size(global.list_sound_special); i+=1){
        SS_StopSound( ds_list_find_value( global.list_sound_special, i ));
    }
    
    // voice
    for( i=0; i<obj_voice_container.voice_max; i += 1){
        for( j=0; j<ds_list_size( global.list_voice[i] ); j+=1){
            SS_StopSound( ds_list_find_value( global.list_voice[i], j ) )
        }
    }
}

else if( global.use_extra_sound_system == 2 ){
    FMODAllStop();
}
