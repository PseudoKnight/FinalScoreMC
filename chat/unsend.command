register_command('unsend', array(
	'description': 'Unsends the last offline message you sent.',
	'usage': '/unsend',
	'settabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@player = import(player().'_mail');
		if(is_null(@player)) {
			die(color('yellow').'There are no offline messages for you to unsend. Perhaps you waited too long.');
		}
		@pdata = _pdata(@player);
		if(!array_index_exists(@pdata, 'mail')) {
			die(color('yellow').'Cannot find last sent mail to '.@player.'. Perhaps they read it already.');
		}
		@letter = null;
		@id = -1;
		foreach(@i: @l in @pdata['mail']) {
			if(@l[1] == player()) {
				@letter = @l;
				@id = @i;
			}
		}
		if(is_null(@letter)) {
			die(color('yellow').'Cannot find last sent mail to '.@player.'.');
		}
		array_remove(@pdata['mail'], @i);
		if(!@pdata['mail']) {
			array_remove(@pdata, 'mail');
		}
		_store_pdata(@player, @pdata);
		msg(color('green').'Removed last sent offline message to '.@player.'.');
	}
));
