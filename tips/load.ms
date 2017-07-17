foreach(@group in array('survival', 'dev', 'minigames')) {
	@file = read(@group.'.txt');
	@tips = split('\n\n', @file);
	export(@group.'-tips', @tips);
}
