register_command('times', array(
	'description': 'Lists and manages time trial records.',
	'usage': '/times <top|avg|segmented|reset|resetplayer|recalculate> [course_id] [player]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('top', 'avg', 'segmented', 'reset', 'resetplayer', 'recalculate'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@action = 'top';
		if(@args) {
			@action = @args[0];
		}
		
		@id = '';
		@player = '';
		if(array_size(@args) > 1) {
			@id = @args[1];
			if(array_size(@args) > 2) {
				@player = @args[2];
			}
		} else {
			@regions = sk_current_regions();
			if(!@regions) {
				die(color('gold').'You are not standing in a course.');
			}
			@id = @regions[-1];
		}

		try {
			include('../commands.library/'.@action.'.ms');
		} catch(IOException @ex) {
			return(false);
		}
	}
));
