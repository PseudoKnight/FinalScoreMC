switch(@action) {
case 'load':
	bind(player_interact, array('id': @player.'lightning'), array('item': 369, 'button': 'right', 'player': @player), @e, @pvp = @pvp) {
		@loc = pcursor();
		bind(entity_damage, array('id': player().'lightningdmg'), array('type': 'PLAYER', 'cause': 'LIGHTNING', 'world': 'custom'), @e,
				@damager = player(), @loc = @loc, @pvp = @pvp) {
				
			if(!array_index_exists(@pvp['players'], @e['player']), die());
			@eloc = entity_loc(@e['id']);
			if(@eloc['x'] < @loc['x'] + 4 && @eloc['x'] > @loc['x'] - 4
			&& @eloc['z'] < @loc['z'] + 4 && @eloc['z'] > @loc['z'] - 4) {
				_stats_damage(@damager, @e['player'], @e['amount'], @pvp);
			}
		}
		lightning(@loc);
		@slot = pinfo(player(), 15)
		@item = pinv(player(), null)
		set_pinv(player(), array('null': array('type': 280)))
		queue_clear(player().'lightning');
		queue_delay(1000, player().'lightning');
		queue_push(closure(){
			unbind(player().'lightningdmg');
		}, player().'lightning');
		queue_delay(5000, player().'lightning');
		queue_push(closure(){
			@newitem = pinv(player(), @slot)
			if(@newitem && @newitem['type'] == 280) {
				set_inventory_item(pinfo(player(), 13), @slot, @item)
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
			
			damage_entity(pinfo(@player, 13), 1, pinfo(player(), 13))
			
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
		
		play_sound(@loc1, array('sound': 'ENDERDRAGON_WINGS', 'pitch': 0.5))
		play_sound(@loc1, array('sound': 'GHAST_FIREBALL', 'pitch': 0.9))
		play_effect(_relative(@loc1, 'up', 2), 'CLOUD', array(
			'particleCount': 60, 
			'speed': 0.5,
		))
		
		@slot = pinfo(player(), 15)
		@item = pinv(player(), null)
		set_pinv(player(), array('null': array('type': 351)))
		queue_clear(player().'woosh')
		queue_delay(6000, player().'woosh')
		queue_push(closure(){
			@newitem = pinv(player(), @slot)
			if(@newitem && @newitem['type'] == 351) {
				set_inventory_item(pinfo(player(), 13), @slot, @item)
			}
		}, player().'woosh')
	}
		
case 'unload':
	unbind(@player.'lightning')
	unbind(@player.'woosh')
	
}