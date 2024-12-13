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
			// we have no completions for this arg
			return(array());
		}
		@completions = @argumentCompletions[array_size(@args) - 1];
		if(is_array(@completions)) {
			// normal arg completion
			@arg = @args[-1];
			while(is_associative(@completions)) {
				// handles nested conditional completions
				@conditionalCompletions = array();
				foreach(@condition: @array in @completions) {
					// This is associative, so order cannot be used.
					// Previous argument and permission conditionals should not be mixed.
					// Use nested associative arrays instead when mixing conditionals.
					if(!@condition) {
						// null is default completions if nothing else matches
						@conditionalCompletions = @array;
						// continue loop
					} else if(@condition[0] === '<') {
						// previous argument conditional
						@argOffset = 1;
						while(@condition[@argOffset] === '<') {
							@argOffset++;
						}
						@previousArg = @args[array_size(@args) - 1 - @argOffset];
						foreach(@conditionalArg in split('|', substr(@condition, @argOffset))) {
							if(@previousArg === @conditionalArg) {
								@conditionalCompletions = @array;
								break(2);
							}
						}
					} else if(has_permission(@condition)) {
						// permission conditional
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
			// custom arg completion
			return(execute(@alias, @sender, @args, @completions));
		}
		// no completions for this arg (should use null for this)
		return(array());
	});
}
