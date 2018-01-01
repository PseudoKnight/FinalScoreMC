bind(entity_death, null, null, @event) {
	@loc = @event['location'];
	@colors = array();
	for(@i = 0, @i < 3, @i++) {
		@colors[] = array(rand(256), rand(256), rand(256));
	}

	@meta = associative_array('strength': 0, 'effects': array());
	@type = array_rand(array('BALL', 'BALL_LARGE', 'STAR', 'BURST', 'CREEPER'), 1, false)[0];
	@startcolors = array_rand(@colors, rand(1, 3), false);
	@endcolors = array_filter(@colors, closure(@key, @value){
		return(!array_contains(@startcolors, @value));
	});
	@meta['effects'][] = associative_array(
		'flicker': rand(2),
		'colors': @startcolors,
		'fade': @endcolors,
		'type': @type,
	);
	@firework = launch_firework(@loc, @meta);
}
