// argument0 : filename



{
  var dsid, filename, sep, fid, i;
  filename = argument0; // save file name

  sep = chr(13)+chr(10); // ',' + '\n\r'

// 同名のファイルがあれば、バックアップにしとく
  if( file_exists( filename ) ){
    file_rename(filename, filename+".backup");
  }

  // ファイルを開く
  fid = file_text_open_write(filename);

  if( fid > 0 ){
  
    for( i=0; i<ds_list_size(global.list_hh_fname); i+=1){
      if( i != 0 ){
        file_text_write_string(fid, sep); // 区切り
      }
      file_text_write_string(fid, string(ds_list_find_value(global.list_hh_fname, i))); // file name
      file_text_write_string(fid, sep); // 区切り

      file_text_write_string(fid, string(ds_list_find_value(global.list_hh_x, i))); // x axis
      file_text_write_string(fid, sep); // 区切り
      
      file_text_write_string(fid, string(ds_list_find_value(global.list_hh_y, i))); // y axis
      
      // ExtraHoleがある場合はx,yを追記？
    }

    file_text_close(fid);
  }
  


}
