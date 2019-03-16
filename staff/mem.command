register_command('mem', array(
	'description': 'Displays memory usage',
	'usage': '/mem',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@maxMem = get_server_info(14);
		@barMem = round(@maxMem / 77);
		@allocMem = get_server_info(15);
		@freeMem = get_server_info(16);
		@actuallyFree = @maxMem - @allocMem + @freeMem;
		@bar = array();
		array_resize(@bar, integer((@allocMem - @freeMem) / @barMem), '\u258D');
		@bar[] = color(7);
		array_resize(@bar, array_size(@bar) + integer(@freeMem / @barMem), '\u258D');
		@bar[] = color(8);
		array_resize(@bar, array_size(@bar) + integer((@maxMem - @allocMem) / @barMem), '\u258D');
		@color = 'green';
		if(@actuallyFree < @maxMem / 10) {
			@color = 'red';
		} else if(@actuallyFree < @maxMem / 5) {
			@color = 'gold';
		} else if(@actuallyFree < @maxMem / 3) {
			@color = 'yellow';
		}
		msg(floor((@allocMem - @freeMem) / 1000000).'MB Used - '
		.floor(@allocMem / 1000000).'MB Allocated - '
		.floor(@maxMem / 1000000).'MB Max');
		msg(color(@color).array_implode(@bar, ''));
	}
));
