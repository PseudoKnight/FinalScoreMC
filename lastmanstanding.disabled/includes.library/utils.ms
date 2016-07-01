proc _generate_chest() {
	@info = associative_array(
		'id': player(),
		'size': 27,
		'title': 'Chest',
	);
	@inv = _get_random_contents(import('lms'.player()));
	@chestdata = array_merge(@info, @inv);
	create_virtualchest(@chestdata);
}

proc _get_random_contents(@lastTime) {
	@count = 0;
	if(is_null(@lastTime)) {
		@count = 10;
	} else {
		@count = ceil(min(60000, time() - @lastTime) / 6000);
	}
	export('lms'.player(), time());

	@limits = associative_array(
		7: 0,
		15: 8,
		46: 8,
		62: 0,
		137: 0,
		166: 0,
		42: 1,
		54: 0,
		56: 2,
		57: 1,
		138: 1,
		145: 1,
		264: 1,
		265: 4,
		297: 8,
		319: 16,
		320: 8,
		322: 4,
		349: 16,
		350: 8,
		363: 16,
		364: 8,
		365: 16,
		366: 8,
		383: 0,
		392: 16,
		393: 8,
		400: 8,
		403: 0,
		407: 4,
		411: 16,
		412: 8,
		423: 16,
		424: 8,
	);

	@inv = associative_array();
	while(@count > 0) {
		@count--;
		@inv[rand(0, 27)] = _random_item(@limits);
	}
	return(@inv);
}

proc _random_item(@limits) {
	@id = rand(1, 373);
	if(@id > 197) {
		@id += 59;
	}
	@max = max_stack_size(@id);
	@data = 0;
	if(@max == 1) {
		@data = material_info(@id)['maxDurability'] - 25;
	}
	if(array_index_exists(@limits, @id)) {
		@max = @limits[@id];
	}
	if(@max <= 0) {
		return(null);
	}
	@item = associative_array(
		'type': @id,
		'data': @data,
		'qty': rand(1, @max + 1);
	);
	return(@item);
}
