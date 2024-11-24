/*
	Returns a tabcompleter closure that supports an ordered list of static or dynamic returns.
	Example:
 		set_tabcompleter('player', _create_tabcompleter(
			array(
				'player.management': array('set', 'get') // requires permission to see
				null: array('get')), // null key is used when all other conditions fail
			null, // no completion
			array('health', 'hunger', 'mode'), // simple list of options
			array(
				'<health|hunger': array('min', 'max', 'none') // requires previous to be health or hunger
				'<mode': array('creative', 'survival', 'adventure', 'spectator')),
			closure(@alias, @sender, @args){ ... }, // custom tabcompleter for this argument
		));
 */
proc _create_tabcompleter() {
	@argumentCompletions = @arguments;
	return(closure(@alias, @sender, @args) {
		if(array_size(@args) > array_size(@argumentCompletions)) {
			return(array());
		}
		@completions = @argumentCompletions[array_size(@args) - 1];
		if(is_array(@completions)) {
			@arg = @args[-1];
			while(is_associative(@completions)) {
				@conditionalCompletions = array();
				foreach(@condition: @array in @completions) {
					if(!@condition) {
						@conditionalCompletions = @array;
					} else if(@condition[0] == '<') {
						@count = 1;
						while(@condition[@count] == '<') {
							@count++;
						}
						@previous = @args[array_size(@args) - 1 - @count];
						foreach(@s in split('|', substr(@condition, @count))) {
							if(@previous == @s) {
								@conditionalCompletions = @array;
								break(2);
							}
						}
					} else if(has_permission(@condition)) {
						@conditionalCompletions = @array;
						break();
					}
				}
				@completions = @conditionalCompletions;
			}
			if(!length(@arg)) {
				return(@completions);
			}
			return(array_filter(@completions, closure(@key, @value) {
				return(string_starts_with(@value, @arg));
			}));
		} else if(is_closure(@completions)) {
			return(execute(@completions));
		}
		return(array());
	});
}
