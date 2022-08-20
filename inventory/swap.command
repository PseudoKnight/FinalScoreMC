register_command('swap', array(
	description: 'Toggles the experimental time swapper.',
	usage: '/swap',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(has_bind('timeswap')) {
			unbind('timeswap');
			msg('Disabled time swap.');
		} else {
			bind('player_interact', array('id': 'timeswap'), array('itemname': 'CLOCK', 'button': 'right', 'hand': 'main_hand'), @event) {
				if(pworld() == 'dev' && !pcooldown('CLOCK')) {
					@loc = ploc();
					@time = 'Present';
					if(@loc['z'] > -1000) {
						@z = -50;
						@loc['z'] -= 50;
					} else {
						@z = 50;
						@loc['z'] += 50;
						@time = 'Past';
					}
					if(!get_block_info(location_shift(@loc, 'up'), 'solid')
					&& !get_block_info(location_shift(@loc, 'up', 2), 'solid')) {
						set_peffect(player(), 'BLINDNESS', 0, 1, true, false);
						set_peffect(player(), 'NIGHT_VISION', 0, 0.5, true, false);
						set_pinv(player(), null, array('name': 'CLOCK', 'meta': array('display': color('bold').@time)));
						set_timeout(1, closure(){
							if(ponline(player()) && pworld() == 'dev') {
								set_pcooldown('CLOCK', 2000 / 50);
								@loc['y']++;
								relative_teleport(@loc);
								set_peffect(player(), 'LEVITATION', 0, 0);
								play_sound(@loc, array('sound': 'ENTITY_ILLUSIONER_MIRROR_MOVE', 'pitch': 1.2));
								play_sound(@loc, array('sound': 'ENTITY_WITHER_SHOOT', 'pitch': 1.3, 'volume': 0.1));
							}
						});
					} else {
						@loc = ploc();
						play_sound(@loc, array('sound': 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR', 'pitch': 2, 'volume': 0.6));
						play_sound(@loc, array('sound': 'BLOCK_FIRE_EXTINGUISH', 'pitch': 2));
					}
				}
			}
			msg('Enabled time swap.');
		}
	}
));
