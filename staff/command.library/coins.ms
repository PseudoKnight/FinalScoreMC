register_command('coins', array(
	'description': 'Displays and manages player coins.',
	'usage': '/coins [add|sub|info] [player] [amount]',
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			msg(color('gold').integer(_acc_balance(player())).' coins');
		} else {
			if(!has_permission('group.moderator')) {
				die(color('gold').'You do not have permission.');
			}
			if(array_size(@args) < 2) {
				return(false);
			}
			@player = @args[1];
			switch(@args[0]) {
				case 'add':
				case 'give':
					if(array_size(@args) < 3) {
						return(false);
					}
					@amount = integer(@args[2]);
					_acc_add(@player, @amount);
					msg('Gave '.@player.' '.@amount.' coins.');
					
				case 'sub':
				case 'subtract':
				case 'remove':
					if(array_size(@args) < 3) {
						return(false);
					}
					@amount = integer(@args[2]);
					_acc_subtract(@player, @amount);
					msg('Subtracted '.@amount.' coins from '.@player);
					
				case 'info':
					@coins = _acc_balance(@player);
					msg(color('gold').integer(_acc_balance(@player)).' coins');
					
				default:
					return(false);
			}
		}
	}
));
