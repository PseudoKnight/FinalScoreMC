register_command('here', array(
	'description': 'Sends everyone a link to this location on the livemap.',
	'usage': '/here',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@loc = ploc();
		@x = @loc['x'];
		@z = @loc['z'];
		@world = @loc['world'];
		@url = "http://207.188.7.11:25966/?worldname=@{world}&mapname=detailed&zoom=2&x=@{x}&y=64&z=@{z}";
		@msg = '["",{"text":"'.color('b').'[\u21D6 '.player().'\'s location on the Live Map]'.color('r').'","clickEvent":'
				.'{"action":"open_url","value":"'.@url.'"}}]';
		foreach(@player in all_players()) {
			runas('~console', "/tellraw @player @msg");
		}
	}
));
