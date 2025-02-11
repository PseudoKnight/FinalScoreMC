bind('entity_death', null, null, @event) {
	@loc = location_shift(@event['location'], 'up');
	@colors = array();
	for(@i = 0, @i < 3, @i++) {
		@colors[] = array(rand(256), rand(256), rand(256));
	}

	@meta = array(strength: -1, effects: array());
	@type = array_get_rand(array('BALL', 'BALL_LARGE', 'STAR', 'BURST', 'CREEPER'));
	@startcolors = array_rand(@colors, rand(1, 3), false);
	@endcolors = array_filter(@colors, closure(@key, @value){
		return(!array_contains(@startcolors, @value));
	});
	@meta['effects'][] = array(
		flicker: rand(2),
		colors: @startcolors,
		fade: @endcolors,
		type: @type,
	);
	@firework = launch_firework(@loc, @meta);
}
