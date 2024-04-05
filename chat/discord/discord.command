register_command('discord', array(
	description: 'Gets the discord invite and links accounts.',
	usage: '/discord link <user_id> | /discord unlink',
	tabcompleter: _create_tabcompleter(array('invite', 'link', 'unlink')),
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args || @args[0] == 'invite') {
			msg(colorize('&lWe have a Discord server @ \n>>> &a&lhttps://discord.gg/XAJAdCXdwr &l<<<'));
		} else if(@args[0] == 'link') {
			if(array_size(@args) == 1) {
				die('Needs a numeric Discord User ID.');
			}
			@id = @args[1];
			if(is_integral(@id)) {
				@pdata = _pdata(player());
				@pdata['discord'] = @id;
				store_value('discord', @id, puuid(player(), true));
				msg(color('green').'Account linked.');
			} else {
				msg(color('red').'Expected a numeric Discord User ID.');
			}
		} else if(@args[0] == 'unlink') {
			@player = player();
			if(array_size(@args) == 2) {
				if(!has_permission('group.admin')) {
					die('You do not have permission to unlink other players.');
				}
				@player = @args[1];
			}
			@pdata = _pdata(@player);
			@id = array_remove(@pdata, 'discord');
			if(is_null(@id)) {
				die('Account was not linked.');
			}
			if(!has_value('discord', @id)) {
				console('Could not find stored Discord link. Removed link from account anyway.');
			}
			clear_value('discord', @id);
			msg(color('green').'Account unlinked.');
		} else {
			return(false);
		}
	}
));