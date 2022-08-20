register_command('discord', array(
	description: 'Gets the discord invite and links accounts.',
	usage: '/discord [user_id]',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			die(colorize('&lWe have a Discord server @ \n>>> &a&lhttps://discord.gg/GHgfWp4 &l<<<'));
		}
		@id = @args[0];
		if(is_integral(@id)) {
			@pdata = _pdata(player());
			@pdata['discord'] = @id;
			store_value('discord', @id, puuid(player(), true));
			msg(color('green').'Account linked.');
		} else {
			msg(color('red').'Invalid user id. Expecting a number.');
		}
	}
));