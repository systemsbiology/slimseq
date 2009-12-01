function set_select_options(s_id,i,opts_array) {
  var sel=document.getElementById(s_id);
  var t1=opts_array[i].map(function(e) { return "<option value='"+e[0]+"'>"+e[1]+"</option>" }).join("\n");
  sel.innerHTML=t1;
}
