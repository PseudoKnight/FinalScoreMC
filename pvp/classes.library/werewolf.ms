switch(@action) {
case 'load':
	bind('entity_damage_player', array('id': @player.'werewolf'), null, @e, @p = @player) {
		if(@e['player'] == @p) {
			if(is_null(pinv(@p, 103))) {
				set_peffect(@p, 1, 2, 20)
				set_peffect(@p, 16, 0, 25)
				set_peffect(@p, 5, 3, 20)
				play_sound(ploc(@p), array('sound': 'WOLF_HOWL', 'pitch': 0.9, 'volume': 2))
				set_pinv(@p, array(
					100: array('type': 301, 'meta': array('color': array('r': 50, 'g': 50, 'b': 50))),
					101: array('type': 300, 'meta': array('color': array('r': 50, 'g': 50, 'b': 50))),
					102: array('type': 299, 'meta': array('color': array('r': 50, 'g': 50, 'b': 50))),
					103: array('type': 35, 'data': 7),
				))
				queue_clear(@p.'evolve')
				queue_delay(20000, @p.'evolve')
				queue_push(closure(){
					@r = rand(0, 256)
					@g = rand(0, 256)
					@b = rand(0, 256)
					set_pinv(@p, array(
						100: array('type': 301, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
						101: array('type': 300, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
						102: array('type': 299, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
						103: null,
					))
					_clear_peffects(@p)
				}, @p.'evolve')
			} else {
				play_sound(ploc(@p), array('sound': 'WOLF_HURT', 'pitch': 0.75))
			}
		} else if(@e['data'] == @p && !is_null(pinv(@p, 103)) && !rand(4)) {
			play_sound(ploc(@p), array('sound': 'WOLF_GROWL', 'pitch': 0.9))
		}
	}

	bind('player_death', array('id': @player.'kill'), null, @e, @player = @player) {
		if(@e['killer'] == @player) {
			set_phealth(@player, min(20, pinfo(@player, 5) + 4))
			play_sound(ploc(@player), array('sound': 'EAT', 'pitch': 0.5))
		}
	}

case 'equip':
	@r = rand(0, 256)
	@g = rand(0, 256)
	@b = rand(0, 256)
	set_pinv(@player, array(
		100: array('type': 301, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
		101: array('type': 300, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
		102: array('type': 299, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
	))

case 'unload':
	unbind(@player.'werewolf')
	unbind(@player.'kill')
	queue_clear(@player.'evolve')
	
}