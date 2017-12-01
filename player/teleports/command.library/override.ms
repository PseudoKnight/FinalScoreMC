register_command('override', array(
	'description': 'Overrides to activate an unsafe teleport.',
	'usage': '/override',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		include('../includes.library/teleports.ms');
		@overrides = import('tp.overrides');
		if(!@overrides || !array_index_exists(@overrides, player())) {
			die(color('gold').'You do not have an unsafe teleport to override.');
		}
		_warmuptp(player(), @overrides[player()]);
		array_remove(@overrides, player());
		export('tp.overrides', @overrides);
	}
));
