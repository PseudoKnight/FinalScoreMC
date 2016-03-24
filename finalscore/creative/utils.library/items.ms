proc _pgive_item(@item, @amount) {
    @item = split(':', @item);
	if(!is_numeric(@item[0])) {
        @item[0] = data_values(@item[0]);
    }
	if(is_null(@item[0])) {
        die('Unknown item name');
    }
	if(array_size(@item) == 1) {
        @item[1] = 0;
    }
	if(!is_integral(@amount) || @amount < 1) {
        die('Amount must be a positive integer.');
    }
	try {
		pgive_item(@item[0].':'.@item[1], $amount);
		msg(color('yellow').'You\'ve been given '.@amount.' '.data_name(@item[0].':'.@item[1]).'.');
	} catch(Exception @ex) {
		msg(color('red').'The item '.@item.' doesn\'t appear to exist.');
	}
}

proc _enchant_item(@type, @level) {
    # enchantment aliases
    @enchants = associative_array(
        'power': 'ARROW_DAMAGE',
        'flame': 'ARROW_FIRE',
        'infinity': 'ARROW_INFINITE',
        'punch': 'ARROW_KNOCKBACK',
        'sharpness': 'DAMAGE_ALL',
        'baneofarthropods': 'DAMAGE_ARTHROPODS',
        'smite': 'DAMAGE_UNDEAD',
        'efficiency': 'DIG_SPEED',
        'unbreaking': 'DURABILITY',
        'fireaspect': 'FIRE_ASPECT',
        'knockback': 'KNOCKBACK',
        'fortune': 'LOOT_BONUS_BLOCKS',
        'looting': 'LOOT_BONUS_MOBS',
        'respiration': 'OXYGEN',
        'protection': 'PROTECTION_ENVIRONMENTAL',
        'blastprotection': 'PROTECTION_EXPLOSIONS',
        'featherfalling': 'PROTECTION_FALL',
        'fireprotection': 'PROTECTION_FIRE',
        'projectileprotection': 'PROTECTION_PROJECTILE',
        'silktouch': 'SILK_TOUCH',
        'thorns': 'THORNS',
        'aquaaffinity': 'WATER_WORKER',
        'depthstrider': 'DEPTH_STRIDER',
    );
    if(!is_integral(@level)) {
        die('Enchantment level must be an integer.');
    }
    if(array_index_exists(@enchants, to_lower(@type))) {
        enchant_inv_unsafe(null, @enchants[to_lower(@type)], @level);
    } else {
        msg(color('red').'Available enchantments: '.array_keys(@enchants));
    }
}
