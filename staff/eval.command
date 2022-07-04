register_command('eval', array(
	'description': 'Runs a script',
	'usage': '/eval <code>',
	'permission': 'command.eval',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@script = array_implode(@args);
		if(player() == '~console') {
			console(@script);
		}
		@output = eval(
			'<! suppressWarnings: UseBareStrings >'
			. @script
		);
		if(length(@output)) {
			msg(@output);
		}
	}
));
