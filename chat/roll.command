register_command('roll', array(
	'description': 'Rolls a random number up to the value given.',
	'usage': '/roll [sides]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@num = 1;
		@sides = 6;
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
			die(color('a').'[Dice] '.color('f').'There\'s a limit of 100 sides.');
		}
		if(@sides < 2) {
			die(color('a').'[Dice] '.color('f').'There\'s a minimum of 2 sides.');
		}
		@message = '';
		if(@sides == 2) {
			@message = color('a').'[Coin] '.display_name().color('f').' flipped a coin and got '.if(rand(2) == 0, 'heads.', 'tails.');
		} else {
			@rolls = array();
			while(@num-- > 0) {
				@rolls[] = rand(@sides) + 1;
			}
			@message = colorize('&a[Dice] '.display_name().'&r rolled &a'.array_implode(@rolls, ' and ').'&r on '.@sides.'-sided die.');
		}
		broadcast(@message, all_players(pworld()));
	}
));
