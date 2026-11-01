// argument0 : filename
// ExtraHoleも読みこむように頑張ったバージョン. 下記のような形式で保存されてるセーブデータを読める．前バージョンとの互換性も完備（多分
/*
FileName.jpg
x
y
x (extra1)
y (extra1)
x (extra2)
y (extra2)
...
*/

{
  var filename, sep, fid, dat, len, ind, pos, readstr, readflag, extranum, buf;

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
    readflag = 0; // 次に何を読み込むかのフラグ 0:ファイル名（拡張子が含まれない場合はExtraHoleのx座標,．1:x座標, 2:y座標, 3:ExtraHoleのy座標
    extranum = 0; // ExtraHoleをいくつ読み込んだかを保存
    
    // datにsepが含まれる数だけ繰り返す
    repeat ( string_count(sep, dat) ) {
      pos = string_pos(sep, dat)-1; // 次のsepの位置を保存
      readstr = string_copy(dat, 1, pos);
//      show_debug_message(readstr);
      
      if( readflag == 0 ) { // read Filename
        if( string_count(".", readstr) >= 1 ){ // 次の文字列が拡張子を含む（ピリオドがある）かどうかをチェック
            ds_list_add(global.list_hh_fname, readstr);
            
            // ExtraHole一時しのぎ
            var i; i=0;
            repeat(EXTRA_HIP_HOLE_MAX){
                // 各配列のケツに0を追加
                ds_list_add(global.list_hh_extra[i], 0);
                i+=1;
            }
            
            readflag = 1;
            extranum = 0;
        } else { // read Extra X
            buf = real( readstr ); // バッファに記憶しとく
        
            readflag = 3;
        }
      }else if( readflag == 1 ) { // read X
        ds_list_add(global.list_hh_x, readstr);
        readflag = 2;
        
      }else if( readflag == 2 ) { // read Y
        ds_list_add(global.list_hh_y, readstr);
        readflag = 0;
        
      }else if( readflag == 3 ) { // read Extra Y
        if( extranum < EXTRA_HIP_HOLE_MAX )
            ds_list_replace(global.list_hh_extra[extranum], ds_list_size(global.list_hh_extra[extranum])-1, (real(readstr) << 16 ) + buf);
        readflag = 0;
        extranum += 1;
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

