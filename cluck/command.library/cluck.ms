register_command('cluck', array(
	'description': 'A game of shooting chickens.',
	'usage': '/cluck [start] [player]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			@scores = get_value('cluck');
			@top = @scores['top'];
			msg(color('bold').'TOP '.array_size(@top).' CLUCK PLAYERS');
			msg(color('gray').'Since '.@scores['date']);
			for(@i = 0, @i < array_size(@top), @i++) {
				msg(if(length(@top[@i]['score']) < 2, '0').@top[@i]['score'].' - '.@top[@i]['name']);
			}
		} else if(@args[0] == 'start') {
			if(!get_command_block()) {
				die();
			}
			@player = @args[1];
			// TODO: remove when done with rewrite
			if(!pisop(@player)) {
				_regionmsg('cluck', 'Cluck is undergoing a rewrite. Come back another day.');
				die();
			}
		
			include('../includes.library/procedures.ms');
		
			@cluck = import('cluck');
			if(!@cluck) {
				@cluck = _cluck_defaults();
				export('cluck', @cluck);
			} else if(@cluck['state']) {
				die();
			}
			
			@cluck['player'] = @player;
			_cluck_start(@cluck);
		} else if(@args[0] == 'reset') {
			if(!has_permission('group.moderator')) {
				die(color('gold').'No permission.');
			}
			store_value('cluck', array(
				'top': array(),
				'date': simple_date('MMM d'),
			));
		} else {
			return(false);
		}
	}
));
