register_command('entereffect', array(
	description: 'Sets the server enter effect of a player.',
	usage: '/entereffect <type>',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array('lightning', 'kaboom', 'clear'));
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@type = to_lower(@args[0]);
		@types = array('lightning', 'kaboom', 'clear');
		if(array_contains(@types, @type)) {
			@pdata = _pdata(player());
			if(@type == 'clear') {
				array_remove(@pdata, 'entereffect');
				msg(color('green').'Enter effect cleared.');
			} else {
				@pdata['entereffect'] = @type;
				msg(color('green').'Enter effect set to '.color('bold').@type);
			}
			_store_pdata(player(), @pdata);
		} else {
			msg(color('red').'Unknown effect type. Requires one of: '. array_implode(@types));
		}
	}
));