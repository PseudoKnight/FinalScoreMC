register_command('acme', array(
	'description': 'Drops an anvil on the player\'s head',
	'usage': '/acme <player> [silent]',
	'permission': 'command.acme',
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = _find_player(@args[0]);
		@message = color('b').'Lovely weather we\'re having today.';
		if(!_is_survival_world(pworld(@player))) {
			@loc = location_shift(ploc(@player), 'up', 24);
			if(get_block(@loc) !== 'AIR') {
				die('Anvil blocked.');
			}
			set_pmode(@player, 'ADVENTURE');
			if(array_size(@args) == 1) {
				set_pinv(@player, array( # guts
					0: array('name': 'REDSTONE', 'meta': array('display': @player.'\'s Blood')),
					1: array('name': 'BONE', 'meta': array('display': @player.'\'s Funny Bone')),
					2: array('name': 'FERMENTED_SPIDER_EYE', 'meta': array('display': @player.'\'s Heart')),
					3: array('name': 'BONE_MEAL', 'meta': array('display': @player.'\'s Bone Powder')),
					4: array('name': 'ROSE_RED', 'meta': array('display': @player.'\'s Brain')),
					5: array('name': 'MUTTON', 'meta': array('display': @player.'\'s Lung')),
					6: array('name': 'SPIDER_EYE', 'meta': array('display': @player.'\'s Eyeball')),
					7: array('name': 'SKELETON_SKULL', 'meta': array('display': @player.'\'s Skull')),
					8: array('name': 'BEETROOT', 'meta': array('display': @player.'\'s Kidney')),
					9: array('name': 'IRON_NUGGET', 'meta': array('display': @player.'\'s Right Molar')),
					10: array('name': 'IRON_NUGGET', 'meta': array('display': @player.'\'s Muscle Fiber')),
				));
				set_peffect(@player, 2, 20, 5, true);
				pfacing(@player, pfacing(@player)[0], -90);
				tmsg(@player, @message);
				play_sound(@loc, array('sound': 'ENTITY_CHICKEN_EGG', 'volume': 3));
			}
			set_block(@loc, 'ANVIL');
			set_timeout(5000, closure(){
				for(@i = @loc[1], @i > 0, @i--) {
					if(get_block(array(@loc[0], @i, @loc[2], @loc[3])) == 'ANVIL') {
						set_block(array(@loc[0], @i, @loc[2], @loc[3]), 'AIR');
						make_effect(array(@loc[0], @i, @loc[2], @loc[3]), 'SMOKE:4');
						break();
					}
				}
			});
		}
	}
));
