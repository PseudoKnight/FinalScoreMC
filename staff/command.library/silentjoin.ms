register_command('silentjoin', array(
	'description': 'Toggles silent joining for admins.',
	'usage': '/silentjoin [on|off]',
	'permission': 'command.silentjoin',
	'executor': closure(@alias, @sender, @args, @info) {
		@state = 1;
		if(!@args) {
			@state = if(get_value('silentjoin'), 0, 1);
		} else {
			@state = @args[0];
		}
		switch(@state) {
			case 'on':
			case 'true':
			case 1:
				store_value('silentjoin', true);
				msg('Turned silent join on for admins.');

			case 'off':
			case 'false':
			case 0:
				store_value('silentjoin', false);
				msg('Turned silent join off for admins.');

		}
	}
));
