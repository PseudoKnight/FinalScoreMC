proc _class_load(@player, @pvp) {
	bind('target_player', array(id: @player.'necrotarget'), array(player: @player), @e) {
		cancel();
	}
	bind('entity_damage', array(id: @player.'necrodamage', priority: 'HIGH'), array(type: 'PLAYER'), @e, @p = @player) {
		if(@e['player'] == @p
		&& ((array_index_exists(@e, 'damager')
		&& @e['damagertype'] === 'ZOMBIE')
		|| (array_index_exists(@e, 'shooter')
		&& !ponline(@e['shooter'])
		&& entity_type(@e['shooter']) === 'SKELETON'))) {
			cancel();
			consume();
		}
	}
	bind('player_death', array(id: @player.'necrodeath'), null, @e, @player) {
		if(@e['player'] == @player, die());
		@a = ploc(@e['player']);
		@b = ploc(@player);
		@dist = distance(@a, @b);
		if(@dist < 24) {
			@effects = get_peffect(@player);
			if(array_index_exists(@effects, 'absorption')) {
				set_peffect(@player, 'ABSORPTION', @effects['absorption']['strength'] + 1, 20);
			} else {
				set_peffect(@player, 'ABSORPTION', 0, 999);
			}
		}
	}
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'necrotarget');
	unbind(@player.'necrodamage');
	unbind(@player.'necrodeath');
}
