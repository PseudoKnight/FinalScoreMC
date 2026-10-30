proc _weapon_bind_events(@pvp) {
	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'CLOCK', hand: 'main_hand'), @event, @pvp) {
		if(array_index_exists(@pvp['players'], player()) && !pcooldown('CLOCK')) {
			@world = @pvp['arena']['world'];
			_world_time_travel(@world, rand(24000), 100);
			set_pcooldown('CLOCK', 120);
			@item = pinv(player(), null);
			@item['meta']['damage']++;
			if(@item['meta']['damage'] >= @item['meta']['maxdamage']) {
				@item = null;
				@loc = location_shift(ploc(), 'up', 2.3);
				play_sound(@loc, array(sound: 'ITEM_SHIELD_BREAK'));
				@v = get_vector(@loc, 0.4);
				@loc['x'] += @v['x'];
				@loc['y'] += @v['y'];
				@loc['z'] += @v['z'];
				spawn_particle(@loc, array(
					particle: 'ITEM_CRACK',
					count: 3,
					item: 'CLOCK',
					speed: 0.1));
			}
			set_pinv(player(), null, @item);
		}
	}
}