register_command('mem', array(
	'description': 'Displays memory usage',
	'usage': '/mem',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@maxMem = get_server_info(14);;
		@barMem = round(@maxMem / 77);
		@allocMem = get_server_info(15);
		@freeMem = get_server_info(16);
		@bar = array();
		array_resize(@bar, integer((@allocMem - @freeMem) / @barMem), '\u258D');
		@bar[] = color(7);
		array_resize(@bar, array_size(@bar) + integer(@freeMem / @barMem), '\u258D');
		@bar[] = color(8);
		array_resize(@bar, array_size(@bar) + integer((@maxMem - @allocMem) / @barMem), '\u258D');
		@color = 'green';
		if(@allocMem == @maxMem && @freeMem < @maxMem / 10) {
			@color = 'red';
		} else if(@allocMem - @freeMem > @maxMem / 2) {
			@color = 'yellow';
		}
		msg(floor((@allocMem - @freeMem) / 1000000).'MB Used - '
		.floor(@allocMem / 1000000).'MB Allocated - '
		.floor(@maxMem / 1000000).'MB Max');
		msg(color(@color).array_implode(@bar, ''));
	}
));
