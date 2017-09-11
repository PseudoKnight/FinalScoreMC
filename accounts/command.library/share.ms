register_command('share', array(
	'description': 'Share horses (and other things) with friends you trust.',
	'usage': '/share <player> <sharable[s]>',
	'settabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) > 1) {
			return(_strings_start_with_ic(array('horses'), @args[-1]));
		}
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		if(array_size(@args) == 1) {
			@share = import('share'.player());
			if(!@share) {
				die(color('gold').'No shares to confirm.');
			}
			
			if(@args[0] != 'confirm') {
				die(color('gold').'You need to type "/share confirm" to confirm a share. Otherwise do nothing.');
			}
		
			@pdata = _pdata(@share['player']);
			if(!array_index_exists(@pdata, 'shared')) {
				@pdata['shared'] = associative_array();
			}
			if(!array_index_exists(@pdata['shared'], player())) {
				@pdata['shared'][player()] = array();
			}
			foreach(@type in @share['types']) {
				@pdata['shared'][player()][] = @type;
			}
			_store_pdata(@share['player'], @pdata);
			tmsg(@share['player'], color('green').'Now sharing '.array_implode(@share['types'], ' and ').' with '.player().'.');
		
			@pdata = _pdata(player());
			if(!array_index_exists(@pdata, 'shared')) {
				@pdata['shared'] = associative_array();
			}
			if(!array_index_exists(@pdata['shared'], @share['player'])) {
				@pdata['shared'][@share['player']] = array();
			}
			foreach(@type in @share['types']) {
				@pdata['shared'][@share['player']][] = @type;
			}
			_store_pdata(player(), @pdata);
			msg(color('green').'Now sharing '.array_implode(@share['types'], ' and ').' with '.@share['player'].'.');
		} else {
			export('share'.player(), null);
			
			@player = _find_player(@args[0]);
			@shareables = array('horses');
			@types = @args[1..-1];
			foreach(@type in @types) {
				if(!array_contains(@shareables, @type)) {
					die(color('red').'Unknown type: '.@type.'\nShareable: '.@shareables);
				}
			}
			export('share'.@player, array(
				'player': player(),
				'types': @types
			));
			msg(color('yellow').'Requested '.@player.' to share '.array_implode(@types, ' and ').'.');
			tmsg(@player, color('yellow').player().' requested to share '.array_implode(@types, ' and ').'. Type "/share confirm".');
		}
	}
));
