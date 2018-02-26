if(@id == 'all') {

	@top = get_value('times');
	msg(colorize('&e&m|------------------&e&l[ TOP SCORE TOTALS ]'));
	for(@i = 0, @i < array_size(@top), @i++) {
		msg(colorize(' '.if(@i < 9, '&80').'&7'.(@i + 1).'&a [ '.@top[@i][2].' ] &r'.@top[@i][1]));
	}

} else if(@player) {
	@uuid = _get_uuid(to_lower(@player));
	@time = get_value('times.'.@id, @uuid);
	if(!@time) {
		die('No time for '.@player.' on '.@id.'.')
	}
	msg(color('yellow').@player.'\'s best time for '.color('gold').to_upper(@id).color('r').' is '.color('green').@time.' seconds.')
	
} else {
	
	@times = get_value('times', @id);
	if(!@times) {
		die('No top times for '.to_upper(@id).'.');
	}
	msg(colorize('&e&m|-------------------&e&l[ TOP TIMES: '.to_upper(@id).' ]'));
	@lastTime = 1.0;
	@lastCount = 0;
	for(@i = 0, @i < array_size(@times), @i++) {
		@thisTime = @times[@i][2];
		if(@thisTime == @lastTime){
			@lastCount++;
		} else {
			@lastCount = 0;
		}
		@time = '';
		if(@thisTime >= 60) {
			@time = simple_date('m\u0027m\u0027 ss.S', integer(@thisTime * 1000));
		} else {
			@time = simple_date('s.S', integer(@thisTime * 1000));
		}
		@time = substr(@time, 0, length(@time) - 2).'s';
		@place = @i + 1 - @lastCount;
		msg(colorize(' '.if(@place < 10, '&80').'&7'.@place.'&a [ '.@time.' ] &r'.@times[@i][1]));
		@lastTime = @thisTime;
	}

}
