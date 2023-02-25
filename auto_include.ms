/*
	Returns a tabcompleter closure that supports an ordered list of static or dynamic returns.
	Example:
		set_tabcompleter('player', _create_tabcompleter(
			array('player.management': array('set', 'get'), ), // requires permission to see
			null, // no completion
			array('health', 'hunger'), // simple list of options
			array('<health|hunger': array('min', 'max', 'none'), // requires previous to be health or hunger
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
			@arg = to_lower(@args[-1]);
			if(is_associative(@completions)) {
				@result = array();
				foreach(@perm: @array in @completions) {
					if(!@perm) {
						@result = @array;
					} else if(@perm[0] == '<') {
						@count = 1;
						while(@perm[@count] == '<') {
							@count++;
						}
						@previous = @args[array_size(@args) - 1 - @count];
						@split = split('|', substr(@perm, @count));
						foreach(@s in @split) {
							if(@previous == @s) {
								@result = @array;
								break();
							}
						}
					} else if(has_permission(@perm)) {
						@result = @array;
						break();
					}
				}
				return(array_filter(@result, closure(@key, @value) {
					return(string_starts_with(@value, @arg));
				}));
			} else {
				return(array_filter(@completions, closure(@key, @value) {
					return(string_starts_with(@value, @arg));
				}));
			}
		} else if(is_closure(@completions)) {
			return(execute(@completions));
		}
		return(array());
	});
}
