switch(@action) {
case 'load':
	@armor = array(
		100: @pvp['arena']['classes'][@class]['kit'][100],
		101: @pvp['arena']['classes'][@class]['kit'][101],
		102: @pvp['arena']['classes'][@class]['kit'][102],
		103: @pvp['arena']['classes'][@class]['kit'][103],
	)
	bind(player_toggle_sneak, array('id': @player.'ninja'), array('player': @player), @e, @gear = @armor) {
		if(@e['sneaking']) {
			set_pinv(array(
				100: null,
				101: null,
				102: null,
				103: null,
			))
			set_peffect(player(), 16, 0, 25)
			set_peffect(player(), 14, 0, 20)
			play_effect(_relative(ploc(), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2))
		} else {
			set_pinv(@gear)
			set_peffect(player(), 14, 0, 0)
			set_peffect(player(), 16, 0, 0)
			play_effect(_relative(ploc(), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2))
		}
	}
	
case 'equip':
	@armor = array(
		100: @pvp['arena']['classes'][@class]['kit'][100],
		101: @pvp['arena']['classes'][@class]['kit'][101],
		102: @pvp['arena']['classes'][@class]['kit'][102],
		103: @pvp['arena']['classes'][@class]['kit'][103],
	)
	
	proc _cloak(@player, @gear) {
		queue_delay(800, @player.'cloaked')
		queue_push(closure(){
			if(ponline(@player) && pinfo(@player, 5) > 0) {
				if(pinfo(@player, 11)) {
					set_pexp(@player, max(0, pexp(@player) - 4))
					if(pexp(@player) <= 0) {
						set_pinv(@player, @gear)
						set_peffect(@player, 14, 0, 0)
						set_peffect(@player, 16, 0, 0)
						play_effect(_relative(ploc(@player), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2))
					}
				} else {
					set_pexp(@player, min(100, pexp(@player) + 4))
				}
				_cloak(@player, @gear)
			}
		}, @player.'cloaked')
	}
	_cloak(@player, @armor)

case 'unload':
	unbind(@player.'ninja')
	queue_clear(@player.'cloaked')
	
}