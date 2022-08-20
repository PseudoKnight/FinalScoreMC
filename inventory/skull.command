register_command('skull', array(
	description: 'Generates a skull with a specific account name, UUID, or texture value.',
	usage: '/skull <name>',
	permission: 'command.skull',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@value = @args[0];
		if(length(@value) < 17) {
			pgive_item(array(name: 'PLAYER_HEAD', meta: array(owner: @value)));
		} else if(length(@value) < 37) {
			pgive_item(array(name: 'PLAYER_HEAD', meta: array(owneruuid: @value)));
		} else {
			pgive_item(array(name: 'PLAYER_HEAD', meta: array(owneruuid: puuid(), texture: @value)));
		}

	}
));
