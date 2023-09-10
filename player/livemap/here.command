register_command('here', array(
	description: 'Sends everyone a link to this location on the livemap.',
	usage: '/here',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		@loc = ploc();
		@x = @loc['x'];
		@z = @loc['z'];
		@world = @loc['world'];
		@url = "http://65.75.211.105:30027/?worldname=@{world}&mapname=detailed&zoom=2&x=@{x}&y=64&z=@{z}";
		@msg = '["",{"text":"'.color('b').'[\u21D6 Location of '.player().' on the Live Map]'.color('r').'","clickEvent":'
				.'{"action":"open_url","value":"'.@url.'"}}]';
		foreach(@player in all_players()) {
			runas('~console', "/tellraw @player @msg");
		}
	}
));
