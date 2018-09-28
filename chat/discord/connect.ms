if(extension_exists('CHDiscord')) {
	// connect to finalscoremc server
	discord_connect(trim(read('token.txt')), '104504215983890432');
}
