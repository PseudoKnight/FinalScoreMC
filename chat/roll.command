register_command('roll', array(
	description: 'Rolls a random number up to the value given.',
	usage: '/roll [sides=6], /roll [dice=1d6]',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		@num = 1;
		@sides = 6;
		@name = if(player() == '~console', '', display_name());
		if(@args) {
			@split = split('d', @args[0]);
			if(array_size(@split) == 2) {
				@num = integer(@split[0]);
				@sides = integer(@split[1]);
			} else {
				@sides = integer(@args[0]);
			}
		}
		if(@sides > 100) {
			die(colorize('&a[Dice]&f There is a limit of 100 sides.'));
		}
		if(@sides < 2) {
			die(colorize('&a[Dice]&f There is a minimum of 2 sides.'));
		}

		proc _get_dice_result() {
			switch(rand(6)) {
				case 0:
					return('\u2680');
				case 1:
					return('\u2681');
				case 2:
					return('\u2682');
				case 3:
					return('\u2683');
				case 4:
					return('\u2684');
				case 5:
					return('\u2685');
				default:
					throw('RangeException', 'Must be 0-6');
			}
		}

		@message = '';
		if(@sides == 2) {
			@result = if(rand(2) == 0, 'heads.', 'tails.');
			@message = colorize("&a[Coin] @name&r flipped a coin and got &a@result");
		} else {
			@rolls = array();
			while(@num-- > 0) {
				@rolls[] = if(@sides == 6, _get_dice_result(), rand(@sides) + 1);
			}
			@result = array_implode(@rolls, ' and ');
			if(@sides == 6) {
				@message = colorize("&a[Dice] @name&r rolled @result");
			} else {
				@message = colorize("&a[Dice] @name&r rolled @result on @sides-sided die.");
			}
		}
		_broadcast(@message);
	}
));
