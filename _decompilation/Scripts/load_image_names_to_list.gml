// argument
// [0]: filename_list
// [1]: directory path

// 指定されたディレクトリ内の画像ファイルをリストに追加する

// return list id

{
  var fname, i, fext, listid, path, dir_list;
  i = 0;
  listid = argument0;
  path = argument1;
  dir_list = ds_list_create();
  
  // read jpg, png, bmp
  fname = file_find_first( path+"\*", fa_directory);
  
  while( true ){
    if( fname == "" ){ break;}
  
    // ディレクトリならパスを記憶しておく
    if( directory_exists(path+"\"+fname) && fname != "." && fname != ".." ){
      ds_list_add(dir_list, path+"\"+fname);
//      show_message(fname);
    }
  
    // 画像ファイルならリストに追加
    fext = string_lower(filename_ext(fname));
    if( fext == ".jpg" || fext == ".bmp" || fext == ".png" || fext == ".jpeg" ){
      ds_list_add(listid, path + "\" +fname);
      i+= 1;
    }
  //  else{
  //    show_message(fname);
  //  }
  
    fname = file_find_next();
  }
  file_find_close();
  
  // 記憶したパスの中身を検索
  if( global.read_recursive ){
    for(i = 0; i<ds_list_size(dir_list); i+=1){
      fname = ds_list_find_value(dir_list, i);
      load_image_names_to_list(listid, fname);
    }
  }

  ds_list_destroy(dir_list);  

  return listid;

}
