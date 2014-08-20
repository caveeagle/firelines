
function setAlphaPNG( img )
{
  var isIE = (navigator.appName.indexOf("Microsoft")!=-1);
  
  var objimg=document.getElementById(img);
  var img_src=objimg.src;

  if ( isIE )
  {
    objimg.src = '/images/px.gif';
    objimg.style.filter = "progid:DXImageTransform.Microsoft.AlphaImageLoader"+"(src='"+img_src+"',sizingMethod='image')";
  }
}
