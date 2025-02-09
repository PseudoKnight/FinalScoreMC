proc _weapon_bind_events(@pvp) {
	@pvp['binds'][] = bind('item_held', null, null, @event, @pvp) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}

		@item = pinv(player(), @event['to']);
		if(@item && @item['name'] === 'COMPASS') {
			set_interval(1000, 50, closure(){
				if(pinfo(player(), 6) === 'COMPASS') {
					foreach(@p: @player in @pvp['players']) {
						if(@player['team'] != @pvp['players'][player()]['team']) {
							@loc1 = ploc();
							@loc2 = ploc(@p);
							@item['meta'] = array(
								display: color('white').'Tracking',
								lodestone: false,
								target: @loc2,
							);
							set_pinv(player(), null, @item);
							@dist = distance(@loc1, @loc2);
							if(@dist < 50) {
								@pitch = 0.5 + (0.5 * ((50 - @dist) / 50));
								play_sound(@loc1, array(sound: 'BLOCK_NOTE_BLOCK_PLING', pitch: @pitch), player());
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
}
