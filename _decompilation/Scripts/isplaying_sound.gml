if( global.use_extra_sound_system == 1 )
    return SS_IsSoundPlaying(argument0);
else if ( global.use_extra_sound_system == 2 )
    return FMODInstanceIsPlaying(argument0);
else
    return sound_isplaying(argument0); 
 
 
