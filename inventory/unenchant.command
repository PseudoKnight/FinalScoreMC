register_command('unenchant', array(
	description: 'Removes all enchantments from the item in hand.',
	usage: '/unenchant',
	permission: 'command.items',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		@item = pinv(player(), null);
		array_remove(@item, 'enchants');
		array_remove(@item['meta'], 'enchants');
		set_pinv(player(), null, @item);
	}
));
