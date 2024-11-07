register_command('exiteffect', array(
	description: 'Sets the server exit effect of a player.',
	usage: '/exiteffect <type>',
	tabcompleter: _create_tabcompleter(array('smoke', 'lightning', 'clear')),
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@type = to_lower(@args[0]);
		@types = array('smoke', 'clear');
		if(array_contains(@types, @type)) {
			@pdata = _pdata(player());
			if(@type == 'clear') {
				array_remove(@pdata, 'exiteffect');
				msg(color('green').'Exit effect cleared.');
			} else {
				@pdata['exiteffect'] = @type;
				msg(color('green').'Exit effect set to '.color('bold').@type);
			}
			_store_pdata(player(), @pdata);
		} else {
			msg(color('red').'Unknown effect type. Requires one of: '. array_implode(@types));
		}
	}
));