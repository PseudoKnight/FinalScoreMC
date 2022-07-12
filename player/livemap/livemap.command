register_command('livemap', array(
	'description': 'Displays a link to this or another player\'s location on the livemap.',
	'usage': '/livemap <player>',
	'executor': closure(@alias, @sender, @args, @info) {
		@player = player();
		if(@args) {
			@player = _find_player(@args[0]);
		}
		@loc = ploc(@player);
		@x = @loc['x'];
		@z = @loc['z'];
		@world = @loc['world'];
		@url = "http://".get_server_info(12).":27836/?worldname=@{world}&mapname=detailed&zoom=2&x=@{x}&y=64&z=@{z}";
		@msg = '["",{"text":"'.color('b').'[\u21D6 Go to Live Map]'.color('r').'","clickEvent":{"action":"open_url","value":"'.@url.'"}}]';
		runas('~console', '/tellraw '.player().' '.@msg);
	}
));
