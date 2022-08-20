register_command('colors', array(
	description: 'Displays available colors and their corresponding code.',
	usage: '/colors',
	aliases: array('colours'),
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		msg(colorize('&00&11&22&33&44&55&66&77&88&99&aa&bb&cc&dd&ee&ff &kk&r&ll&r&mm&r&nn&r&oo &rr'));
	}
));
