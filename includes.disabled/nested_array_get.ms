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