/// Direct file URL on Pixeldrain's API (spec §2.1): range-request friendly
/// and CORS-open, so the player streams it and the downloader saves it.
String pixeldrainFileUrl(String id) => 'https://pixeldrain.net/api/file/$id';
