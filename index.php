<?php

include_once 'slapi.php';
include_once 'psr4.php';

function get_post_var($key) {
  return urldecode(strip_tags(stripslashes(trim($_POST[$key]))));
}

$accessToken = get_post_var('token');
if (!isset($accessToken) || empty($accessToken)) {

  $session = new SpotifyWebAPI\Session(
  'CLIENT_ID'
  , 'CLIENT_SECRET'
  );

  $session->requestCredentialsToken();
  $accessToken = $session->getAccessToken();
  die( $accessToken );
}

$search = get_post_var('search');
if (!isset($search) || empty($search)) {
  die('Please specify a search text!');
}

$api = new SpotifyWebAPI\SpotifyWebAPI();
$api->setAccessToken($accessToken);

$results = $api->search($search, 'artist');
// var_dump( $results );

foreach ($results->artists->items as $artist) {
  echo $artist->id
    . ',' . $artist->name
    . ',' . $artist->external_urls->spotify
    . '|';
}
