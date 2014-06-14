switch(@action) {
case 'load':
	@armor = array(
		100: @pvp['arena']['classes'][@class]['kit'][100],
		101: @pvp['arena']['classes'][@class]['kit'][101],
		102: @pvp['arena']['classes'][@class]['kit'][102],
		103: @pvp['arena']['classes'][@class]['kit'][103],
	)
	bind('player_toggle_sneak', array('id': @player.'ninja'), array('player': @player), @e, @armor) {
		if(@e['sneaking']) {
			set_pinv(array(
				100: null,
				101: null,
				102: null,
				103: null,
			))
			set_peffect(player(), 16, 0, 30)
			set_peffect(player(), 14, 0, 30)
			play_effect(_relative(ploc(), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2))
		} else {
			set_pinv(@armor)
			set_peffect(player(), 14, 0, 0)
			set_peffect(player(), 16, 0, 0)
			play_effect(_relative(ploc(), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2))
		}
	}

case 'unload':
	unbind(@player.'ninja')
	
}