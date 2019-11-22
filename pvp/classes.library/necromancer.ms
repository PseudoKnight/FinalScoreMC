switch(@action) {
case 'load':
	bind('target_player', array('id': @player.'necrotarget'), array('player': @player), @e) {
		cancel();
	}
	bind('entity_damage', array('id': @player.'necrodamage', 'priority': 'HIGH'), array('type': 'PLAYER'), @e, @p = @player) {
		if(@e['player'] == @p
		&& ((array_index_exists(@e, 'damager')
		&& !ponline(@e['damager'])
		&& entity_type(@e['damager']) === 'ZOMBIE')
		|| (array_index_exists(@e, 'shooter')
		&& !ponline(@e['shooter'])
		&& entity_type(@e['shooter']) === 'SKELETON'))) {
			cancel();
			consume();
		}
	}
	bind('player_death', array('id': @player.'necrodeath'), null, @e, @player) {
		if(@e['player'] == @player, die());
		@a = ploc(@e['player']);
		@b = ploc(@player);
		@dist = distance(@a, @b);
		if(@dist < 24) {
			foreach(@e in get_peffect(@player)) {
				if(@e['id'] == 22) {
					set_peffect(@player, 'ABSORPTION', @e['strength'] + 1, 20);
					die();
				}
			}
			set_peffect(@player, 'ABSORPTION', 0, 999);
		}
	}

case 'unload':
	unbind(@player.'necrotarget');
	unbind(@player.'necrodamage');
	unbind(@player.'necrodeath');
	
}
