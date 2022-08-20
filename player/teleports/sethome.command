register_command('sethome', array(
	description: 'Sets your home for this world.',
	usage: '/sethome [player]',
	permission: 'command.sethome',
	executor: closure(@alias, @sender, @args, @info) {
		if(@args && !has_permission('command.sethome.others')) {
			die(color('gold').'You cannot set other player\'s homes.');
		}
		@player = player();
		if(@args) {
			@player = @args[0];
		}
		@pdata = _pdata(@player);
		if(!array_index_exists(@pdata, 'homes')) {
			@pdata['homes'] = associative_array();
		}
		@loc = ploc();
		@facing = pfacing();
		@pdata['homes'][pworld()] = array(
			floor(@loc[0]) + 0.5,
			@loc[1],
			floor(@loc[2]) + 0.5,
			pworld(),
			round(@facing[0], 2),
			round(@facing[1], 2),
		);
		_store_pdata(@player, @pdata);
		msg(color('green').'Set home to this location.');
	}
));
