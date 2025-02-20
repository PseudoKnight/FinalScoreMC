register_command('platform', array(
	description: 'Creates a temporary moving shulker platform.',
	usage: '/platform <color> <offset> <ms>',
	permission: 'command.platform',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(reflect_pull('enum', 'DyeColor'), @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		@color = @args[0];
		@offset = integer(@args[1]);
		@ms = integer(@args[2]);
		
		@loc = get_command_block();
		@loc['x'] += 0.5;
		@loc['y'] += 2;
		@loc['z'] += 0.5;
		@loc['yaw'] = 0.0;
		@loc['pitch'] = 0.0;
		
		@entities = array();
		@previous = spawn_entity('MINECART', 1, @loc, iclosure(@e){
			set_entity_saves_on_unload(@e, false);
			set_entity_silent(@e, true);
		})[0];
		@entities[] = @previous;
		
		@spec = array(visible: false);
		while(@offset > 0) {
			@stand = spawn_entity('ARMOR_STAND', 1, @loc, closure(@e){
				set_entity_saves_on_unload(@e, false);
				if(@offset == 1) {
					@spec['small'] = true;
				}
				set_entity_spec(@e, @spec);
				add_scoreboard_tag(@e, 'remove');
			})[0];
			@entities[] = @stand;
			set_entity_rider(@previous, @stand);
			@previous = @stand;
			@offset -= 2;
		}
		
		@shulker = spawn_entity('SHULKER', 1, @loc, closure(@e){
			set_entity_saves_on_unload(@e, false);
			try(set_entity_spec(@e, array(color: @color)))
			set_entity_ai(@e, false);
		})[0];
		set_entity_loc(@shulker, @loc);
		set_entity_rider(@previous, @shulker);
		@entities[] = @shulker;
		
		set_timeout(@ms, closure(){
			foreach(@entity in @entities) {
				try(entity_remove(@entity))
			}
		});
	}
));
