// argument0 : filename
// ExtraHoleも保存するようにしたバージョン

{
  var dsid, filename, sep, fid, i, j;
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
      for( j=0; j<EXTRA_HIP_HOLE_MAX; j+=1){
          if( ds_list_find_value(global.list_hh_extra[j], i) == 0 ){
            break;
          }else{
          // ExtraHole保存！！
            file_text_write_string(fid, sep); // 区切り
            file_text_write_string(fid, string( downer16(ds_list_find_value(global.list_hh_extra[j], i)) ));
            file_text_write_string(fid, sep); // 区切り
            file_text_write_string(fid, string( upper16(ds_list_find_value(global.list_hh_extra[j], i)) ));
          }
      }
    }
    file_text_close(fid);
  }
  


}
