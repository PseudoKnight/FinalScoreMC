register_command('contribution', array(
	description: 'Adds a donation amount to the account of a player.',
	usage: '/contribution <account> <amount>',
	aliases: array('support', 'donation'),
	permission: 'command.contribution',
	executor: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@player = @args[0];
		@amount = integer(@args[1]);
		@pdata = _pdata(@player);
		if(array_index_exists(@pdata, 'support')) {
			@pdata['support'] += @amount;
			msg('Added $'.@amount.' to the total contributions of '.@pdata['name'].'; Total: $'.@pdata['support'].'.')
		} else {
			@pdata['support'] = @amount
			msg('Set contribution amount of '.@pdata['name'].' to $'.@amount.'.')
		}
		if(@pdata['group'] === 'member' || @pdata['group'] === 'regular') {
			@pdata['group'] = 'donor';
		}
		_store_pdata(@player, @pdata);
	}
));
