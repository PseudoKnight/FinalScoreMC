array_push(@pvp['binds'], @id.'pistoltears')
bind('player_interact', array('id': @id.'pistoltears'), array('item': 370, 'button': 'right'), @e, assign(@id, @id)) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())
	@entity = shoot_projectile(player(), 'ARROW')
	@v = entity_velocity(@entity)
	set_entity_velocity(@entity, array(@v['x'] * 3, @v['y'] * 3, @v['z'] * 3))
	play_sound(ploc(), array('sound': 'ZOMBIE_WOOD', 'pitch': 2, 'volume': 2))
	@item = pinv(player(), null)
	@item['qty'] = @item['qty'] - 1
	if(@item['qty'] == 0) {
		set_pinv(array(null: null))
	} else {
		@item['type'] = 371
		set_pinv(array(null: @item))
		@slot = pinfo(player(), 15)
		set_timeout(2000, closure(){
				@item = pinv(player(), @slot)
				if(!is_null(@item) && @item['type'] == 371) {
				play_sound(ploc(), array('sound': 'DOOR_OPEN', 'pitch': 2))
				@inv = array()
				@item['type'] = 370
				@inv[@slot] = @item
				set_pinv(@inv)
			}
		})
	}
}