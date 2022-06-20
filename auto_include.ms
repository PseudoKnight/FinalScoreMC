/*
	Gets a value from any number of nested arrays using multiple keys.
	Returns null if expected arrays or keys don't exist.
	Example: @value = _nested_array_get(@nestedArrays, 'key_for_parent_array', 'key_for_nested_array');
*/
proc _nested_array_get(@value) {
	@size = array_size(@arguments);
	for(@i = 1, @i < @size, @i++) {
		if(is_array(@value)) {
			@key = @arguments[@i];
			if(array_index_exists(@value, @key)) {
				@value = @value[@key];
			} else {
				return(null);
			}
		} else {
			return(null);
		}
	}
	return(@value);
}

/*
	Registers an event listener with a closure that executes whenever _trigger_event()
	is called for that event. An associative array is passed to the closure.
	Unlike bind(), all event data is mutable, so any modifications to the array reference
	in the closure are seen by subsequent listeners and the code following the event trigger.

	@eventName an arbitrary string used to trigger an event
	@id used for unregistering the listener later
	@priority an int used to sort listener execution order, low to high
	@closure executed on event trigger and accepts an associative array argument of event data
 */
void proc _register_listener(string @eventName, string @id, int @priority, closure @closure){
	_unregister_listener(@eventName, @id);
	array @listeners = import('event.'.@eventName, array());
	@listeners[] = array(id: @id, priority: @priority, closure: @closure);
	array_sort(@listeners, closure(@left, @right) {
		return(@left['priority'] > @right['priority']);
	});
	export('event.'.@eventName, @listeners);
}

/*
	Unregisters an event listener with the specified id.

	@eventName an arbitrary string used to trigger an event
	@id from when the listener was registered
 */
void proc _unregister_listener(string @eventName, string @id){
	array @listeners = import('event.'.@eventName, array());
	foreach(@index: @listener in @listeners) {
		if(@listener['id'] == @id) {
			array_remove(@listeners, @index);
			return();
		}
	}
}

/*
	Executes all listeners for an event of the given name.
	The array key 'cancelled' is added to the event data.

	@eventName an arbitrary string used to trigger an event
	@data is the associative array of event data
 */
void proc _trigger_event(string @eventName, array @data){
	@data['cancelled'] = false;
	array @listeners = import('event.'.@eventName, array());
	foreach(@listener in @listeners){
		try {
			execute(@data, @listener['closure']);
			if(@data['cancelled']) {
				break();
			}
		} catch(Exception @ex) {
			console(split('.', @ex['classType'])[-1].': '.@ex['message']);
			foreach(@trace in @ex['stackTrace']) {
				console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id']);
			}
		}
	}
}

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
