register_command('eval', array(
	description: 'Runs a script. When run on an entity, @e is its UUID.',
	usage: '/eval [on <entity_type>] <code>',
	permission: 'command.eval',
	tabcompleter: _create_tabcompleter(
		array('on'),
		array('<on': reflect_pull('enum', 'EntityType')),
		null
	),
	executor: closure(@alias, @sender, @args) {
		@mode = @args[0];
		@codeIndex = 0;
		@e = null; // can be used in script
		if(@mode == 'on') {
			@codeIndex = 2;
			@type = @args[1];
			@location = ploc();
			@closestDistance = 32;
			foreach(@entity in entities_in_radius(@location, @closestDistance, @type)) {
				@distance = distance(@location, entity_loc(@entity));
				if(@distance < @closestDistance) {
					@closestDistance = @distance;
					@e = @entity;
				}
			}
		}
		@script = array_implode(@args[cslice(@codeIndex, -1)]);
		if(player() == '~console') {
			console(@script);
		}
		@output = eval(
			'<! strict: off; suppressWarnings: UseBareStrings >'
			. @script
		);
		if(length(@output)) {
			msg(@output);
		}
	}
));
