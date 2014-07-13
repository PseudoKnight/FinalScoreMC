switch(@action) {
case 'load':
	bind('entity_damage_player', array('id': @player.'werewolf'), null, @e, @p = @player) {
		if(@e['player'] == @p) {
			play_sound(ploc(@p), array('sound': 'WOLF_HURT', 'pitch': 0.75))
		} else if(@e['data'] == @p && !is_null(pinv(@p, 103)) && !rand(4)) {
			play_sound(ploc(@p), array('sound': 'WOLF_GROWL', 'pitch': 0.9))
		}
	}

	bind('player_death', array('id': @player.'kill'), null, @e, @player = @player) {
		if(@e['killer'] == @player) {
			set_phealth(@player, min(20, pinfo(@player, 5) + 4))
			play_sound(ploc(@player), array('sound': 'EAT', 'pitch': 0.5))
			set_timeout(1000, closure(){
				set_phealth(@player, min(20, pinfo(@player, 5) + 4))
				play_sound(ploc(@player), array('sound': 'EAT', 'pitch': 0.5))
			})
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
	queue_clear(@player.'evolve')
	
case 'powerup':
	set_peffect(@player, 1, 3, 15)
	set_peffect(@player, 5, 3, 15)
	play_sound(ploc(@player), array('sound': 'WOLF_HOWL', 'pitch': 0.9, 'volume': 2))
	set_pinv(@player, array(
		100: array('type': 301, 'meta': array('color': array('r': 50, 'g': 50, 'b': 50))),
		101: array('type': 300, 'meta': array('color': array('r': 50, 'g': 50, 'b': 50))),
		102: array('type': 299, 'meta': array('color': array('r': 50, 'g': 50, 'b': 50))),
		103: array('type': 35, 'data': 7),
	))
	queue_clear(@player.'evolve')
	queue_delay(50, @player.'evolve')
	queue_push(closure(){
		set_peffect(@player, 16, 0, 22)
	}, @player.'evolve')
	queue_delay(15000, @player.'evolve')
	queue_push(closure(){
		if(pinfo(@player, 5) > 0) {
			@r = rand(0, 256)
			@g = rand(0, 256)
			@b = rand(0, 256)
			set_pinv(@player, array(
				100: array('type': 301, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
				101: array('type': 300, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
				102: array('type': 299, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
				103: null,
			))
			_clear_peffects(@player)
		}
	}, @player.'evolve')

case 'unload':
	unbind(@player.'werewolf')
	unbind(@player.'kill')
	queue_clear(@player.'evolve')
	
}