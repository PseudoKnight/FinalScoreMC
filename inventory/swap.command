register_command('swap', array(
	'description': 'Toggles the experimental time swapper.',
	'usage': '/swap',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(has_bind('timeswap')) {
			unbind('timeswap');
			msg('Disabled time swap.');
		} else {
			bind('player_interact', array('id': 'timeswap'), array('item': 347, 'button': 'right', 'hand': 'main_hand'), @event) {
				if(pworld() == 'dev' && !pcooldown('WATCH')) {
					@loc = ploc();
					if(@loc['z'] > -1000) {
						@z = -50;
						@loc['z'] -= 50;
					} else {
						@z = 50;
						@loc['z'] += 50;
					}
					if(!get_block_info(location_shift(@loc, 'up'), 'solid')
					&& !get_block_info(location_shift(@loc, 'up', 2), 'solid')) {
						set_peffect(player(), 15, 0, 1, true, false);
						set_peffect(player(), 16, 0, 1, true, false);
						@item = pinv(player(), null);
						@slot = pheld_slot();
						set_timeout(50, closure(){
							if(ponline(player()) && pworld() == 'dev') {
								set_pcooldown('WATCH', 2000 / 50);
								relative_teleport(array(0, 0, @z, @loc['world']));
								set_peffect(player(), 25, 0, 0);
								play_named_sound(@loc, array('sound': 'entity.illusion_illager.mirror_move', 'pitch': 1.2));
								play_sound(@loc, array('sound': 'WITHER_SHOOT', 'pitch': 1.3, 'volume': 0.1));
							}
						});
					} else {
						@loc = ploc();
						play_sound(@loc, array('sound': 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR', 'pitch': 2, 'volume': 0.6));
						play_sound(@loc, array('sound': 'FIZZ', 'pitch': 2));
					}
				}
			}
			msg('Enabled time swap.');
		}
	}
));
