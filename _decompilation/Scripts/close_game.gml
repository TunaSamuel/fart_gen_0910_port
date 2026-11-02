// obj_set_holeのGame Endで呼ばれる

// 音声ファイルの一時保存先を削除
var fname;
fname = file_find_first( ".\sound\." + string(game_id) + "*", 63);

while( fname != "" ){
    file_delete( ".\sound\" + fname );
    fname = file_find_next();
}

file_find_close();


