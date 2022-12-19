register_command('acme', array(
	description: 'Drops an anvil on somone',
	usage: '/acme <player> [silent]',
	permission: 'command.acme',
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = _find_player(@args[0]);
		@message = color('b').'Lovely weather we are having today.';
		if(!_is_survival_world(pworld(@player))) {
			@loc = location_shift(ploc(@player), 'up', 24);
			if(get_block(@loc) !== 'AIR') {
				die('Anvil blocked.');
			}
			set_pmode(@player, 'ADVENTURE');
			if(array_size(@args) == 1) {
				set_pinv(@player, array( # guts
					0: array('name': 'REDSTONE', 'meta': array('display': 'Blood of '.@player)),
					1: array('name': 'BONE', 'meta': array('display': 'Funny Bone of '.@player)),
					2: array('name': 'FERMENTED_SPIDER_EYE', 'meta': array('display': 'Heart of '.@player)),
					3: array('name': 'BONE_MEAL', 'meta': array('display': 'Bone Powder of '.@player)),
					4: array('name': 'RED_DYE', 'meta': array('display': 'Brain of '.@player)),
					5: array('name': 'MUTTON', 'meta': array('display': 'Lung of '.@player)),
					6: array('name': 'SPIDER_EYE', 'meta': array('display': 'Eyeball of '.@player)),
					7: array('name': 'SKELETON_SKULL', 'meta': array('display': 'Skull of '.@player)),
					8: array('name': 'BEETROOT', 'meta': array('display': 'Kidney of '.@player)),
					9: array('name': 'IRON_NUGGET', 'meta': array('display': 'Right Molar of '.@player)),
					10: array('name': 'IRON_NUGGET', 'meta': array('display': 'Muscle Fiber of '.@player)),
				));
				set_peffect(@player, 'SLOWNESS', 20, 5, true);
				pfacing(@player, pfacing(@player)[0], -90);
				tmsg(@player, @message);
				play_sound(@loc, array('sound': 'ENTITY_CHICKEN_EGG', 'volume': 3));
			}
			set_block(@loc, 'ANVIL');
			set_timeout(5000, closure(){
				for(@i = @loc[1], @i > 0, @i--) {
					if(string_ends_with(get_block(array(@loc[0], @i, @loc[2], @loc[3])), 'ANVIL')) {
						set_block(array(@loc[0], @i, @loc[2], @loc[3]), 'AIR');
						make_effect(array(@loc[0], @i, @loc[2], @loc[3]), 'SMOKE:4');
						break();
					}
				}
			});
		}
	}
));
