register_command('enchant', array(
	description: 'Sets an enchantment on the item in hand.',
	usage: '/enchant <enchantment> [level=1]',
	permission: 'command.items',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			@enchants = array(
				'power', 'flame', 'infinity', 'punch', 'sharpness', 'bane_of_arthropods', 'smith', 'efficiency',
				'unbreaking', 'fire_aspect', 'knockback', 'fortune', 'looting', 'respiration', 'protection',
				'blast_protection', 'feather_falling', 'fire_protection', 'projectile_protection', 'silk_touch',
				'thorns', 'aqua_affinity', 'depth_strider', 'mending', 'frost_walker', 'sweeping_edge', 'channeling',
				'impaling', 'riptide', 'loyalty', 'vanishing_curse', 'binding_curse', 'swift_sneak', 'piercing',
				'multishot', 'quick_charge'
			);
			return(_strings_start_with_ic(@enchants, @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@type = @args[0];
		@level = array_get(@args, 1, 1);
		@item = pinv(player(), null);
		if(!@item) {
			die('You must hold an item.');
		}
		if(!is_integral(@level)) {
			die('Enchantment level must be an integer.');
		}
		@level = integer(clamp(@level, 1, 10));
		try {
			enchant_item(null, @type, @level);
		} catch (Exception @ex) {
			msg(color('red').'Invalid enchantment: '.@type);
		}
	}
));