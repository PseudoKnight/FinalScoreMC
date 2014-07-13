array_push(@pvp['binds'], @id.'shotgunshoot')
bind('player_interact', array('id': @id.'shotgunshoot'), array('item': 332, 'button': 'right'), @e, assign(@id, @id)) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())
	cancel()
	@entities = array()
	for(@i = 0, @i < 8, @i++) {
		@entities[@i] = shoot_projectile(player(), 'SNOWBALL')
		@v = entity_velocity(@entities[@i])
		set_entity_velocity(@entities[@i], array(@v['x'] * 3.4 + ((rand(3) - 1)), @v['y'] * 3.4 + ((rand(3) - 1)), @v['z'] * 3.4 + ((rand(3) - 1))))
	}
	play_sound(ploc(), array('sound': 'ZOMBIE_WOOD', 'pitch': 1.5, 'volume': 2))
	play_sound(ploc(), array('sound': 'EXPLODE', 'pitch': 2, 'volume': 2))
	@item = pinv(player(), null)
	@item['qty'] = @item['qty'] - 1
	if(@item['qty'] == 0) {
		set_pinv(array(null: null))
	} else {
		@item['type'] = 341
		set_pinv(array(null: @item))
		@slot = pinfo(player(), 15)
		set_timeout(300, closure(){
		for(@i = 0, @i < 8, @i++) {
			if(entity_exists(@entities[@i]), entity_remove(@entities[@i]))
		}
		set_timeout(700, closure(){
				@item = pinv(player(), @slot)
				if(!is_null(@item) && @item['type'] == 341) {
				play_sound(ploc(), array('sound': 'PISTON_RETRACT', 'pitch': 1.5))
				@inv = array()
				@item['type'] = 332
				@inv[@slot] = @item
				set_pinv(@inv)
			}
		})
		})
	}
}
array_push(@pvp['binds'], @id.'shotgunreload')
bind('entity_damage', array('id': @id.'shotgunreload'), array('type': 'PLAYER', 'cause': 'PROJECTILE', 'world': 'custom'), @e, assign(@id, @id)) {
	if(ponline(@e['shooter'])) {
		@pvp = import('pvp'.@id)
		if(array_index_exists(@pvp['players'], @e['shooter'])
		&& pinv(@e['shooter'], null)
		&& pinv(@e['shooter'], null)['type'] == 341) {
			modify_event('amount', 8)
		}
	}
}