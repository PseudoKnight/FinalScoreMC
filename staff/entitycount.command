register_command('entitycount', array(
	description: 'Returns the number of entities of each type in this world.',
	usage: '/entitycount',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		sudo('/paper mobcaps');
		@entities = all_entities(pworld());
		@specificTypes = associative_array();
		foreach(@e in @entities) {
			@type = entity_type(@e);
			if(!array_index_exists(@specificTypes, @type)) {
				@specificTypes[@type] = 0;
			}
			@specificTypes[@type]++;
		}
		@sortedTypes = array();
		foreach(@type: @count in @specificTypes) {
			@sortedTypes[] = array(name: @type, count: @count);
		}
		@sortedTypes = array_sort(@sortedTypes, closure(@left, @right) {
			return(@left['count'] < @right['count']);
		});
		@sortedTypes = @sortedTypes[cslice(0, min(9, array_size(@sortedTypes) - 1))]
		msg('Top entity counts:');
		foreach(@type in @sortedTypes) {
			msg('  '.color('GRAY').to_lower(@type['name']).color('RESET').': '.@type['count']);
		}
	}
));
