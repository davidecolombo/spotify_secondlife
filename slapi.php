<?php

function llEscapeURL($s)
{
  $s = str_replace(
    array(" ","+","-",".","_"),
    array("%20","%20","%2D","%2E","%5F"),
    urlencode($s)
  );
  return $s;
}

$hash = urldecode(strip_tags(stripslashes(trim($_GET['hash']))));
if (!isset($hash) || empty($hash)) {
  die();
}

$SECRET_NONCE = 123456789;
$SECRET_HASH = 'SECRET_HASH';

$body = '';
$i = 0;
foreach ($_POST as $name => $value) {
  if ($i++ > 0) {
    $body .= '&';
  }
  $body .= llEscapeURL($name) . '=' . llEscapeURL(stripslashes($value));
}

$md5 = md5($body . $SECRET_HASH . ':' . $SECRET_NONCE);
if ($hash != $md5) {
  die();
}
