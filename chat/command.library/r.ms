register_command('r', array(
	'description': 'Replies to the private message.',
	'usage': '/r <message>',
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@conv = import('conv');
		if(!array_index_exists(@conv, player())) {
			die(color('yellow').'You do not have any current conversations.');
		}
		@player = @conv[player()];
		if(@player !== '~console' && !ponline(@player)) {
			die(color('gold').'That player is no longer online.');
		}
		include('../includes.library/chat.ms');
		_pmsg(@player, array_implode(@args));
	}
));
