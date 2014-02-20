# DeadboltHelper
# Automatically locks chests when right-clicking with sign. 
# This feature already exists in Deadbolt, however,
# this allows me to customize which blocks I want to auto-protect with signs.
# DEPENDENCIES:
# _relative() procedure

bind('player_interact', null, array('button': 'right', 'item': 323, 'block': 54), @e) {
	if(@e['action'] != 'right_click_block' || pinfo(player(), 11)) { die() }
	if(sk_can_build(@e['location'])) {
		foreach(@dir in array('north', 'south', 'east', 'west')) {
			@checkblock = _relative(@e['location'], @dir)
			switch(split(':', get_block_at(@checkblock))[0]) {
			case 68:
				if(strip_colors(to_lower(get_sign_text(@checkblock)[0])) == '[private]', die('Already protected.'))
			case 54:
				foreach(@recdir in array('north', 'south', 'east', 'west')) {
					if(split(':', get_block_at(_relative(@checkblock, @recdir)))[0] == '68' 
					&& strip_colors(to_lower(get_sign_text(_relative(@checkblock, @recdir))[0])) == '[private]') {
						die('Already protected.')
					}
				}
			}
		}
		switch(@e['facing']) {
		case 'north':
			@data = 2
		case 'south':
			@data = 3
		case 'west':
			@data = 4
		case 'east':
			@data = 5
		default: 
			die()
		}
		@location = _relative(@e['location'], @e['facing'])
		set_block_at(@location, '68:'.@data)
		set_sign_text(@location, array(color('dark_red').'[PRIVATE]', player(), '', ''))
		@slot = pinv(player(), null)
		if(@slot['qty'] == 1) {
			set_pinv(array(null: null))
		} else {
			@slot['qty'] = @slot['qty'] - 1
			set_pinv(array(null: @slot))
		}
		cancel()
	}
}