register_command('generate', array(
	description: 'Generates something using a script.',
	usage: '/generate <type> <config> <region> [seed=0] [debug]',
	permission: 'command.generate',
	tabcompleter: _create_tabcompleter(
		array('dungeon', 'scaled_level', 'interrupt'),
		array('<dungeon': array('dungeon', 'phd', 'showdown', 'stronghold', 'test'),
			'<scaled_level': array('dirt', 'static')),
		array('<region>'),
		array('<seed>'),
		array('debug'),
	),
	executor: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1 && @args[0] === 'interrupt') {
			x_interrupt('DungeonPlanner');
		} else if(array_size(@args) >= 3) {
			@type = @args[0];
			@config = @args[1];
			@region = @args[2];
			@seed = integer(array_get(@args, 3, 0));
			@debug = array_get(@args, 4, '') === 'debug';
			_generator_create(@type, @config, @region, pworld(), @seed, null, @debug);
		} else {
			return(false);
		}
	}
));
