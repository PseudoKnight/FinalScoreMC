register_command('mscript', array(
	description: 'Runs a script from a commandblock',
	usage: '/mscript <filename>',
	permission: 'command.cb',
	executor: closure(@alias, @sender, @args, @info) {
		@filename = @args[0];
		include(".library/@filename.ms");
	}
));