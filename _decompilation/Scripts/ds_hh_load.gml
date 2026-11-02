// argument0 : filename

{
  var filename, sep, fid, dat, len, ind, pos, readstr;

  filename = argument0;

  sep = chr(13)+chr(10); // 区切り文字
  fid = file_text_open_read(filename);

  if( fid > 0 ){

    // ファイル読み込みして，ひとつの文字列変数にまとめる
    dat = "";
    while(!file_text_eof(fid)){
      dat += file_text_read_string(fid);
      file_text_readln(fid);
      dat += sep;
    }

    len = string_length(sep); // sepの文字数を保存
    ind = 0; // ループインデックス

    // datにsepが含まれる数だけ繰り返す
    repeat ( string_count(sep, dat) ) {
      pos = string_pos(sep, dat)-1; // 次のsepの位置を保存
      readstr = string_copy(dat, 1, pos);
      show_debug_message(readstr);
      if( ind mod 3 == 0 ) {
        ds_list_add(global.list_hh_fname, readstr);
        
        // ExtraHole一時しのぎ
        var i; i=0;
        repeat(EXTRA_HIP_HOLE_MAX){
            ds_list_add(global.list_hh_extra[i], 0);
            i+=1;
        }
            
      }else if( ind mod 3 == 1 ) {
        ds_list_add(global.list_hh_x, readstr);
        
        
      }else{
        ds_list_add(global.list_hh_y, readstr);
        
        
      }
      dat = string_delete(dat, 1, pos+len);
      ind += 1;
    }
    file_text_close(fid);
    return 0;
  }else{
    return -1;
  } 
}
