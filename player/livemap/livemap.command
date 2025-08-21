register_command('livemap', array(
	description: 'Displays a link to the location of a player on the livemap.',
	usage: '/livemap <player>',
	executor: closure(@alias, @sender, @args, @info) {
		@player = player();
		if(@args) {
			@player = _find_player(@args[0]);
		}
		@loc = ploc(@player);
		@x = @loc['x'];
		@z = @loc['z'];
		@world = @loc['world'];
		@url = "http://65.75.211.105:30027/?worldname=@{world}&mapname=detailed&zoom=2&x=@{x}&y=64&z=@{z}";
		@msg = '["",{"text":"'.color('b').'[\u21D6 Go to Live Map]'.color('r').'","click_event":{"action":"open_url","url":"'.@url.'"}}]';
		runas('~console', '/tellraw '.player().' '.@msg);
	}
));
