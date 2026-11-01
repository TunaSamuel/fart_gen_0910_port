// argument0: fname

// fnameがデータベースに無いファイルなら，とりあえず全ホールを0にして初期化する

var ind, i;

ind = ds_list_find_index(global.list_hh_fname, argument0);

if( ind == -1 )
{
  ds_list_add(global.list_hh_fname, argument0);
  ds_list_add(global.list_hh_x, 0);
  ds_list_add(global.list_hh_y, 0);
  for( i=0; i<EXTRA_HIP_HOLE_MAX; i+=1){
      ds_list_add(global.list_hh_extra[i], 0);
  }
}

//show_debug_message( "add new file (" + string(argument0) + ") to database!" );

