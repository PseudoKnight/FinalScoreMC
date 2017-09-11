register_command('dye', array(
	'description': 'Dyes leather armor or maps.',
	'usage': '/dye <r#> <g#> <b#> (0-255)',
	'permission': 'command.items',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 3) {
			return(false);
		}
		@item = pinv(player(), null);
		if(!@item) {
			die(color('gold').'You must be holding an item in your hand.');
		}
		@color = array(
			integer(clamp(@args[0], 0, 255)),
			integer(clamp(@args[1], 0, 255)),
			integer(clamp(@args[2], 0, 255))
		);
		if(string_starts_with(@item['name'], 'LEATHER_')) {
			try {
				set_armor_color(pinfo(player(), 15), @color);
			} catch(Exception @ex) {
				die(color('gold').'Hold leather armor in your hand and type the command. eg. /dye 255 255 255');
			}
		} else if(@item['name'] == 'MAP') {
			if(!@item['meta']) {
				@item['meta'] = array('color': @color);
			} else {
				@item['meta']['color'] = @color;
			}
			set_pinv(player(), array(null: @item));
		} else {
			die(color('gold').'You must be holding leather armor or a map in your hand.');
		}
	}
));
