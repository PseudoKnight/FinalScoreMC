switch(@action) {
case 'load':
	bind(player_interact, array('id': @player.'lightning'), array('item': 369, 'button': 'right', 'player': @player), @e, @pvp) {
		@loc = pcursor(array(0, 65, 66, 68, 70, 72, 77, 85, 143, 147, 148, 157, 171, 188, 189, 190, 191, 192));
		bind(entity_damage, array('id': player().'lightningdmg'), array('type': 'PLAYER', 'cause': 'LIGHTNING', 'world': 'custom'), @e,
				@damager = player(), @pvp) {
				
			if(!array_index_exists(@pvp['players'], @e['player']), die());
			set_timeout(50, closure(){
				@entity = import(@damager.'lightning');
				if(@e['damager'] == import(@damager.'lightning')) {
					_stats_damage(@damager, @e['player'], @e['amount'], @pvp);
				}
			});
		}
		@lightning = lightning(@loc);
		export(player().'lightning', @lightning);
		@block = get_block_at(@loc);
		psend_block_change(@loc, 41);
		@slot = pinfo(player(), 15)
		@item = pinv(player(), null)
		set_pinv(player(), array(null: array('type': 280)))
		queue_clear(player().'lightning');
		queue_delay(1000, player().'lightning');
		queue_push(closure(){
			unbind(player().'lightningdmg');
			psend_block_change(@loc, @block);
			export(player().'lightning', null);
		}, player().'lightning');
		queue_delay(5000, player().'lightning');
		queue_push(closure(){
			@newitem = pinv(player(), @slot)
			if(!is_null(@newitem) && @newitem['type'] == 280) {
				@inv = array();
				@inv[@slot] = @item;
				set_pinv(@inv);
				play_sound(ploc(), array('sound': 'FIZZ'))
			}
		}, player().'lightning')
	}
	
	bind(player_interact, array('id': @player.'woosh'), array('item': 288, 'button': 'right', 'player': @player), @e) {
		@loc1 = ploc()
		foreach(@player in players_in_radius(ploc(), 8)) {
			if(@player == player() || pinfo(@player, 5) <= 0, continue())
			@loc2 = ploc(@player)
			@loc2['y'] += 2
			@dist = sqrt(((@loc2['x'] - @loc1['x']) ** 2) + ((@loc2['y'] - @loc1['y']) ** 2) + ((@loc2['z'] - @loc1['z']) ** 2))
			
			damage_entity(puuid(@player), 1, puuid())
			
			try(
				# if we use a queue, velocity works more consistently with grounded entities
				queue_push(closure(){
					set_pvelocity(@player, 
						1.4 * ((@loc2['x'] - @loc1['x']) / @dist), # vector normalization
						max(0.1, min(1.4, (@loc2['y'] - @loc1['y']) / @dist)), # always bounce upwards
						1.4 * ((@loc2['z'] - @loc1['z']) / @dist),
					)
				})
			)
		}
		
		play_sound(@loc1, array('sound': 'ENDERDRAGON_WINGS', 'pitch': 0.5));
		play_sound(@loc1, array('sound': 'GHAST_FIREBALL', 'pitch': 0.9));
		play_effect(_relative(@loc1, 'up', 2), 'CLOUD', array(
			'particleCount': 60, 
			'speed': 0.5,
		));
		_weapon_cooldown(player(), 6000, 'INK_SACK', false, 0);
	}
		
case 'unload':
	unbind(@player.'lightning')
	unbind(@player.'woosh')
	
}