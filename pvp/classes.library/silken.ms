switch(@action) {
case 'load':
	set_peffect(@player, 'MINING_FATIGUE', 1, 9999, true, false);
	set_pcooldown(@player, 'WEB', 0);
	bind('entity_damage', array(id: @player.'damage'), array(type: 'PLAYER', cause: 'ENTITY_ATTACK'), @e, @p = @player) {
		if(@e['damager'] == @p) {
			@weapon = pinv(@p, null);
			if(@weapon && @weapon['name'] == 'STONE_HOE') {
				modify_event('amount', pattack_cooldown(@p) * 2);
				set_mob_effect(@e['id'], 'wither', 1, pattack_cooldown(@p) * 7);
			}
		}
	}

	bind('player_interact', array(id: @player.'web'), array(player: @player, button: 'right', itemname: 'COBWEB'), @e, @pvp) {
		@item = pinv(player(), null);
		if(@item && pcooldown(@item['name']) == 0) {
			@item['qty'] = 1;
			ptake_item(@item);
			set_pcooldown(@item['name'], 10000 / 20);
			@loc = location_shift(ploc(), 'up', 2.5);
			@v = get_vector(@loc);
			@loc['x'] += @v['x'];
			@loc['y'] += @v['y'];
			@loc['z'] += @v['z'];
			for(@i = 0, @i < 100, @i++) {
				queue_push(closure(){
					@loc['x'] += @v['x'];
					@loc['y'] += @v['y'];
					@loc['z'] += @v['z'];
					if(get_block(@loc) == 'AIR') {
						foreach(@p in array_keys(@pvp['players'])) {
							psend_block_change(@p, @loc, 'COBWEB');
						}
						play_sound(@loc, array(sound: 'ENTITY_SPIDER_AMBIENT', pitch: 2));
					} else {
						queue_clear(player().'web');
					}
				}, player().'web');
			}
		}
	}

case 'unload':
	unbind(@player.'damage');
	unbind(@player.'web');

}
