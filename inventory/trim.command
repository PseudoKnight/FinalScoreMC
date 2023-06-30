@trimArguments = array_map(array_merge(reflect_pull('enum', 'TrimPattern'), reflect_pull('enum', 'TrimMaterial')), closure(@value) {
	return(to_lower(string(@value)));
});
register_command('trim', array(
	description: 'Changes the trim on current armor.',
	usage: '/trim <pattern|material> [armorSlot]',
	permission: 'command.items',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(@trimArguments, @args[0]));
		} else if(array_size(@args) == 2) {
			return(_strings_start_with_ic(array('boots', 'leggings', 'chestplate', 'helmet'), @args[1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@slots = array('BOOTS', 'LEGGINGS', 'CHESTPLATE', 'HELMET');
		if(array_size(@args) == 2) {
			if(!array_contains_ic(@slots, @args[1])) {
				die('Incorrect slot name. Should be one of: '.array_implode(', ', @slots));
			}
			@slots = array(to_upper(@args[1]));
		}
		@armor = pinv();
		if(array_contains_ic(reflect_pull('enum', 'TrimPattern'), @args[0])) {
			for(@i = 100, @i <= 103, @i++) {
				if(@armor[@i] && array_contains(@slots, split('_', @armor[@i]['name'])[-1])) {
					if(!@armor[@i]['meta']) {
						@armor[@i]['meta'] = array(trim: array(material: 'QUARTZ'));
					} else if(!@armor[@i]['meta']['trim']) {
						@armor[@i]['meta']['trim'] = array(material: 'QUARTZ');
					}
					@armor[@i]['meta']['trim']['pattern'] = to_upper(@args[0]);
					set_pinv(player(), @i, @armor[@i]);
				}
			}
		} else if(array_contains_ic(reflect_pull('enum', 'TrimMaterial'), @args[0])) {
			for(@i = 100, @i <= 103, @i++) {
				if(@armor[@i] && array_contains(@slots, split('_', @armor[@i]['name'])[-1])) {
					if(!@armor[@i]['meta']) {
						@armor[@i]['meta'] = array(trim: array(pattern: 'WARD'));
					} else if(!@armor[@i]['meta']['trim']) {
						@armor[@i]['meta']['trim'] = array(pattern: 'WARD');
					}
					@armor[@i]['meta']['trim']['material'] = to_upper(@args[0]);
					set_pinv(player(), @i, @armor[@i]);
				}
			}
		} else {
			return(false);
		}
	}
));
