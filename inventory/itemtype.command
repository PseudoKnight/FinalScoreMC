register_command('itemtype', array(
	description: 'Changes item type but keeps meta',
	usage: '/itemtype <type> [data]',
	permission: 'command.items',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(import('materials', array()), @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@type = to_upper(@args[0]);
		@item = pinv(player(), null);
		@item['name'] = @type;
		if(@type == 'PLAYER_HEAD') {
			@value = @args[1];
			@item['meta']['owneruuid'] = uuid();
			@item['meta']['texture'] = @value;
		}
		set_pinv(player(), null, @item);
	}
));
