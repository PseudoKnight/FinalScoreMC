register_command('cleandatabase', array(
	description: 'Cleans up junk data in database.',
	usage: '/cleandatabase',
	permission: 'command.cleandatabase',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		@players = get_values('uuids');
		foreach(@key: @pdata in @players) {
			// Remove survival state if player is in survival
			// Data is already stored in vanilla player file
			if(array_index_exists(@pdata, 'survival')
			&& array_index_exists(@pdata, 'world')
			&& @pdata['world'] != 'dev'
			&& @pdata['world'] != 'custom') {
				array_remove(@pdata, 'survival');
				store_value(@key, @pdata);
			}
		}
	}
));
