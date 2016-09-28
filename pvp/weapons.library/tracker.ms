array_push(@pvp['binds'], @id.'tracker');
bind(item_held, array('id': @id.'tracker'), null, @event, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}

	if(pinfo(player(), 6) === '345:0') {
		set_interval(1500, 500, closure(){
			if(pinfo(player(), 6) === '345:0') {
				foreach(@p: @player in @pvp['players']) {
					if(@player['team'] != @pvp['players'][player()]['team']) {
						@loc1 = ploc();
						@loc2 = ploc(@p);
						set_compass_target(@loc2);
						@dist = _distance(@loc1, @loc2);
						if(@dist < 32) {
							@pitch = 0.5 + (0.5 * ((32 - @dist) / 32));
							play_sound(@loc1, array('sound': 'NOTE_STICKS', 'pitch': @pitch), player());
							break();
						}
					}
				}
			} else {
				clear_task();
			}
		});
	}
}
