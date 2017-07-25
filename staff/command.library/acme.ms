register_command('acme', array(
	'description': 'Drops an anvil on the player\'s head',
	'usage': '/acme <player>',
	'permission': 'command.acme',
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = _find_player(@args[0]);
		@message = color('b').'Lovely weather we\'re having today.';
		if(!_is_survival_world(pworld(@player))) {
			@loc = _relative(ploc(@player), 'up', 24)
			if(get_block_at(@loc)[0] !== '0') {
				die('Anvil blocked.');
			}
			set_pmode(@player, 'ADVENTURE');
			set_pinv(@player, array( # guts
				0: array('type': 331, 'meta': array('display': @player.'\'s Blood')),
				1: array('type': 352, 'meta': array('display': @player.'\'s Funny Bone')),
				2: array('type': 376, 'meta': array('display': @player.'\'s Heart')),
				3: array('type': 351, 'data': 15, 'meta': array('display': @player.'\'s Bone Powder')),
				4: array('type': 351, 'data': 1, 'meta': array('display': @player.'\'s Brain')),
				5: array('type': 423, 'meta': array('display': @player.'\'s Lung')),
				6: array('type': 375, 'meta': array('display': @player.'\'s Eyeball')),
				7: array('type': 397, 'meta': array('display': @player.'\'s Skull')),
				8: array('type': 434, 'meta': array('display': @player.'\'s Kidney')),
				9: array('type': 452, 'meta': array('display': @player.'\'s Right Molar')),
				10: array('type': 452, 'meta': array('display': @player.'\'s Muscle Fiber')),
			));
			set_peffect(@player, 2, 20, 5, true);
			pfacing(@player, pfacing(@player)[0], -90);
			tmsg(@player, @message);
			play_sound(@loc, array('sound': 'CHICKEN_EGG_POP', 'volume': 3));
			set_block_at(@loc, data_values('anvil'));
			set_timeout(5000, closure(){
				for(@i = @loc[1], @i > 0, @i--) {
					if(split(':', get_block_at(array(@loc[0], @i, @loc[2], @loc[3])))[0] == data_values('anvil')) {
						set_block_at(array(@loc[0], @i, @loc[2], @loc[3]), '0:0');
						make_effect(array(@loc[0], @i, @loc[2], @loc[3]), 'SMOKE:4');
						break();
					}
				}
			});
		}
	}
));