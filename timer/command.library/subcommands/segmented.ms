@times = get_values('times');
x_new_thread('segmented_times', closure(){
	@players = associative_array();
	@courses = array();
	foreach(@key: @time in @times) {
		if(!is_array(@time)) {
			@split = split('.', @key);
			@course = @split[1];
			if(!array_contains(@courses, @course)) {
				@courses[] = @course;
			}
			@uuid = @split[2];
			if(!array_index_exists(@players, @uuid)) {
				@players[@uuid] = array('total': @time, 'count': 1);
			} else {
				@players[@uuid]['total'] += @time;
				@players[@uuid]['count']++;
			}
		}
	}
	@filtered = array_filter(@players, closure(@key, @value) {
		return(@value['count'] == array_size(@courses));
	});
	@players = array();
	foreach(@uuid: @value in @filtered) {
		@players[] = array('name': _pdata_by_uuid(@uuid)['name'], 'total': @value['total']);
	}
	array_sort(@players, closure(@left, @right){
		return(@left['total'] > @right['total']);
	});
	@output = colorize('&e&m|-------------------&e&l[ TOP SEGMENTED TIMES ]&r');
	foreach(@index: @value in @players) {
		@time = '';
		if(@value['total'] >= 3600) {
			@time = simple_date('h\u0027h\u0027 m\u0027m\u0027 ss.S', integer(@value['total'] * 1000));
		} else {
			@time = simple_date('m\u0027m\u0027 ss.S', integer(@value['total'] * 1000));
		}
		@time = substr(@time, 0, length(@time) - 2).'s';
		@output .= '\n'.color('gray').(@index + 1).color('green').' [ '.@time.' ] '.color('reset').@value['name'];
	}
	msg(@output);
});
