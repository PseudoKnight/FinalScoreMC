register_command('heal', array(
	'description': 'Sets a player\'s health, hunger and status to defaults.',
	'usage': '/heal [player]',
	'permission': 'command.heal',
	'executor': closure(@alias, @sender, @args, @info) {
		@player = player();
		if(@args) {
			if(!has_permission('command.heal.others')) {
				die(color('gold').'You do not have permission to heal others.');
			}
			@player = _find_player(@args[0]);
			if(pworld(@player) != pworld()) {
				die(color('gold').'You cannot heal a player in another world.');
			}
		}
		set_phunger(@player, 20);
		set_psaturation(@player, 5.0);
		set_phealth(@player, 20);
		foreach(@effect in get_peffect(@player)) {
			set_peffect(@player, @effect['id'], 0, 0);
		}
		tmsg(@player, color('green').'Healed!');
		if(@player != player()) {
			msg(color('green').'Healed!');
		}
	}
));
