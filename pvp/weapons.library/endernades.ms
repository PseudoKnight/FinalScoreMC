array_push(@pvp['binds'], @id.'endernades')
bind(player_teleport, array('id': @id.'endernades'), array('type': 'ENDER_PEARL'), @e, assign(@id, @id)) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())
	
	cancel()
	#explosion(@e['to'], 2)
	play_sound(@e['to'], array('sound': 'EXPLODE', 'pitch': 0.8))
	if(function_exists('play_effect')) {
		play_effect(@e['to'], 'EXPLOSION_LARGE')
	}
	@loc1 = @e['to']
	foreach(@player in players_in_radius(@loc1, 4)) {
		if(pinfo(@player, 5) <= 0, continue())
		@loc2 = ploc(@player)
		@loc2['y'] += 1.5
		@dist = sqrt(((@loc2['x'] - @loc1['x']) ** 2) + ((@loc2['y'] - @loc1['y']) ** 2) + ((@loc2['z'] - @loc1['z']) ** 2))
		
		damage_entity(pinfo(@player, 13), 24 - ((@dist / 4) * 24), pinfo(player(), 13))

		try(
			# if we use a queue, velocity works more consistently with grounded entities
			queue_push(closure(){
				set_pvelocity(@player, 
					(@loc2['x'] - @loc1['x']) / @dist, # vector normalization
					0.45, # always bounce upwards
					(@loc2['z'] - @loc1['z']) / @dist,
				)
			})
		)
	}
}

array_push(@pvp['binds'], @id.'endernadesreload')
bind(player_interact, array('id': @id.'endernadesreload', 'priority': 'highest'), array('item': 368, 'button': 'right'), @e, assign(@id, @id)) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())
	cancel()
	shoot_projectile(player(), 'ENDER_PEARL')
	play_sound(ploc(), array('sound': 'SHOOT_ARROW', 'pitch': 0.5))
	@item = pinv(player(), null)
	@item['qty'] -= 1
	if(@item['qty'] == 0) {
		set_pinv(array('null': null))
	} else {
		@item['type'] = 378
		set_pinv(array('null': @item))
		@slot = pinfo(player(), 15)
		set_timeout(800, closure(){
				@item = pinv(player(), @slot)
				if(!is_null(@item) && @item['type'] == 378) {
				play_sound(ploc(), array('sound': 'IRONGOLEM_THROW'))
				@inv = array()
				@item['type'] = 368
				@inv[@slot] = @item
				set_pinv(@inv)
			}
		})
	}
}