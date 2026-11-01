if( global.ds_hh_exist == true ){
  exit;
}

global.ds_hh_exist = true;

global.list_hh_fname = ds_list_create();

global.list_hh_x = ds_list_create();
global.list_hh_y = ds_list_create();

// 2つ目以降の穴の位置を覚えさせる！
// x座標は下16ビット、y座標は上16ビット
var i;
for( i=0;i<EXTRA_HIP_HOLE_MAX; i+=1){
    global.list_hh_extra[i] = ds_list_create();
}
