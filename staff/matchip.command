register_command('matchip', array(
	'description': 'Finds all players in the database with a matching IP address',
	'usage': '/matchip <ip>',
	'permission': 'command.matchip',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@ip = @args[0];
		@msg = 'Matched players for '.@ip.': ';
		x_new_thread('ip_match', closure(){
			@players = get_values('uuids');
			foreach(@player in @players) {
				if(array_index_exists(@player, 'ips') && array_contains(@player['ips'], @ip)) {
					@msg .= @player['name'].' ';
				}
			}
			msg(@msg);
		});
	}
));
