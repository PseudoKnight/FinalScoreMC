register_command('swap', array(
	description: 'Toggles the experimental swapper.',
	usage: '/swap <axis> <offset>',
	permission: 'command.swap',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		@id = player().'swap';
		if(!has_bind(@id)) {
			@axis = @args[0];
			if(@axis != 'x' && @axis != 'z' && @axis != 'y') {
				die('Axis can only be x, y, or z.');
			}
			@offset = integer(@args[1]);
			@center = ploc()[@axis] + @offset / 2;
			bind('player_interact', array(id: @id), array(itemname: 'CLOCK', button: 'right', hand: 'main_hand', player: player()),
					@event, @axis, @center, @offset) {
				if(pworld() != 'dev') {
					unbind();
				} else if(!pcooldown('CLOCK')) {
					@loc = ploc();
					if(@loc[@axis] > @center) {
						@loc[@axis] -= @offset;
					} else {
						@loc[@axis] += @offset;
					}
					if(!get_block_info(location_shift(@loc, 'up'), 'solid')
					&& !get_block_info(location_shift(@loc, 'up', 2), 'solid')) {
						set_peffect(player(), 'BLINDNESS', 0, 1, true, false);
						set_peffect(player(), 'NIGHT_VISION', 0, 0.5, true, false);
						set_timeout(1, closure(){
							if(ponline(player()) && pworld() == 'dev') {
								set_pcooldown('CLOCK', 2000 / 50);
								@loc['y']++;
								relative_teleport(@loc);
								set_peffect(player(), 'LEVITATION', 0, 0);
								play_sound(@loc, array(sound: 'ENTITY_ILLUSIONER_MIRROR_MOVE', pitch: 1.2));
								play_sound(@loc, array(sound: 'ENTITY_WITHER_SHOOT', pitch: 1.3, volume: 0.1));
							}
						});
					} else {
						@loc = ploc();
						play_sound(@loc, array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR', pitch: 2, volume: 0.6));
						play_sound(@loc, array(sound: 'BLOCK_FIRE_EXTINGUISH', pitch: 2));
					}
				}
			}
			msg('Enabled swap.');
		} else {
			unbind(@id);
			msg('Disabled swap.');
		}
	}
));
