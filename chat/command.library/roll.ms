register_command('roll', array(
	'description': 'Rolls a random number up to the value given.',
	'usage': '/roll [sides]',
	'settabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@sides = 6;
		if(@args) {
			@sides = integer(@args[0]);
		}
		if(@sides > 100) {
			die(color('a').'[Dice] '.color('f').'There\'s a limit of 100 sides.');
		}
		if(@sides < 2) {
			die(color('a').'[Dice] '.color('f').'There\'s a minimum of 2 sides.');
		}
		if(@sides == 2) {
			@message = color('a').'[Coin] '._colorname(player()).player().color('f').' flipped a coin and got '.if(rand(2) == 0, 'heads.', 'tails.');
		} else {
			@message = color('a').'[Dice] '._colorname(player()).player().color('f').' rolled a '.color('a').(rand(@sides) + 1).' on a '.@sides.'-sided die.';
		}
		foreach(@p in all_players(pworld())) {
			if(!ponline(@p)) {
				continue();
			}
			tmsg(@p, @message);
		}
	}
));
