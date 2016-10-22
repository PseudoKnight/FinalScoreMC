array_push(@pvp['binds'], @id.'tracker');
bind(item_held, array('id': @id.'tracker'), null, @event, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}

	@item = pinv(player(), @event['to']);
	if(@item && @item['name'] == 'COMPASS') {
		set_interval(1000, 50, closure(){
			if(pinfo(player(), 6) === '345:0') {
				foreach(@p: @player in @pvp['players']) {
					if(@player['team'] != @pvp['players'][player()]['team']) {
						@loc1 = ploc();
						@loc2 = ploc(@p);
						set_compass_target(@loc2);
						@dist = _distance(@loc1, @loc2);
						if(@dist < 50) {
							@pitch = 0.5 + (0.5 * ((50 - @dist) / 50));
							play_sound(@loc1, array('sound': 'NOTE_PLING', 'pitch': @pitch), player());
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
