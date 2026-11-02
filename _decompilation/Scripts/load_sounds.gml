// 指定したディレクトリからWAVEファイルを読み込む。読み込んだサウンドのindexをリストに格納して返す
// Arguments
// [0]: Directory path
// [1]: ロードしたサウンドのindexを格納するリスト

var ind, temp_ind;

// read wav
fname = file_find_first(argument0+"\*.wav", 63);
fullpath = argument0 + "\" + fname;

// 全角ファイルをリネームする時の新名称に使用
temp_ind = 0;

while( true ){
   if( fname == "" ){ break;}
   
   // サウンドファイルを読み込み
   if( global.use_extra_sound_system == 1 ){
      //show_debug_message("SS_LoadSound ... [" + string(ind) + "] from " + fullpath);
      ind = SS_LoadSound(fullpath, 0);
   }
   
   else if ( global.use_extra_sound_system == 2 ){
      ind = FMODSoundAdd(fullpath, false, false);
      
      if( ind == 0 ){ // 読み込み失敗時
          // 苦肉の策として，ファイル名を適当なのに変えて読みなおしてみる
          var temp_snd;
          
          temp_snd = ".\sound\." + string(game_id) + string(temp_ind) + filename_ext(fname);
          // 問題のファイルを適当にリネーム, コピー
          while( file_exists( temp_snd ) ){ // 名前被りを回避
            temp_ind += 10;
            temp_snd = ".\sound\." + string(game_id) + string(temp_ind) + filename_ext(fname)
          }
          file_copy( fullpath, temp_snd );
          
          // 読み込み直し
          ind = FMODSoundAdd(temp_snd, false, false);
      
          temp_ind += 1;
          
          //show_debug_message("FMODSoundAdd ... [" + string(ind) + "] from " + temp_snd);
      }
      // show_debug_message("FMODSoundAdd ... [" + string(ind) + "] from " + fullpath);
   }
   
   else{
      ind = sound_add(fullpath, 0, true);
   }
   
   ds_list_add(argument1, ind);
   
   fname = file_find_next();
   fullpath = argument0 + "\" + fname;

}
file_find_close();

return argument1;

