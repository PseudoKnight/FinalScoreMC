array_push(@pvp['binds'], @id.'fireball')
bind(player_interact, array('id': @id.'fireball'), array('item': 385, 'button': 'right'), @e, assign(@id, @id)) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())
	cancel()
	@entity = shoot_projectile(player(), 'FIREBALL')
	play_sound(ploc(), array('sound': 'GHAST_FIREBALL', 'volume': 2))
	@item = pinv(player(), null)
	@item['qty'] = @item['qty'] - 1
	if(@item['qty'] == 0) {
		set_pinv(array(null: null))
	} else {
		@item['type'] = 402
		set_pinv(array(null: @item))
		@slot = pinfo(player(), 15)
		set_timeout(2000, closure(){
				@item = pinv(player(), @slot)
				if(!is_null(@item) && @item['type'] == 402) {
				play_sound(ploc(), array('sound': 'FIZZ', 'pitch': 1.5))
				@inv = array()
				@item['type'] = 385
				@inv[@slot] = @item
				set_pinv(@inv)
			}
		})
	}
}