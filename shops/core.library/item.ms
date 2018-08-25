/*
	Get material name from aliases
*/
proc _item_get_material(@name) {
	if(!@name) {
		return(null);
	}
	@name = replace(to_upper(@name), ' ', '_');
	try {
		material_info(@name, 'isBlock'); // continues if material name is valid
		return(@name);
	} catch(IllegalArgumentException @ex) {
		// try legacy
		try {
			@split = split(':', @name);
			if(array_size(@split) == 2) {
				if(is_integral(@split[0])) {
					return(data_name(@name));
				}
				return(data_name(array('name': @split[0], 'data': @split[1])));
			}
			if(is_integral(@name)) {
				return(data_name(@name));
			}
			return(data_name(array('name': @name)));
		} catch(FormatException @ex) {
			return(_item_get_from_alias(@name));
		}
	}
}

/*
	Get current item type from currency notation
*/
proc _item_get_currency(@id) {
	switch(@id) {
		case 'd':
			return('DIAMOND');
		case 'e':
			return('EMERALD');
		case 'g':
			return('GOLD_INGOT');
		case 'i':
			return('IRON_INGOT');
		default:
			throw('FormatException', 'Shop has unhandled currency: '.@shop['sell'][4]);
	}
}

/*
	Fancy display name for materials
*/
proc _item_display(@name) {
	@split = split('_', @name);
	@newName = '';
	foreach(@s in @split) {
		@newName .= @s[0].to_lower(substr(@s, 1));
	}
	return(@newName);
}

/*
	Returns a modern material name from an old alias
*/
proc _item_get_from_alias(@name) {
	// old aliases
	switch(@name) {
		case 'PINE_SAPLING':
			return('SPRUCE_SAPLING');
		case 'PINE_LOG':
			return('SPRUCE_LOG');
		case 'BROWNMUSHROOM':
			return('BROWN_MUSHROOM');
		case 'MOSS_STONE':
			return('MOSSY_COBBLESTONE');
		case 'LIGHTBLUEWOOL':
			return('LIGHT_BLUE_WOOL');
		case 'LIGHTGRAYWOOL':
			return('LIGHT_GRAY_WOOL');
		case 'STONEBRICK':
			return('STONE_BRICKS');
		case 'LEATHER_HAT':
			return('LEATHER_HELMET');
		case 'SLIMEBALL':
			return('SLIME_BALL');
		case 'GLOWSTONEDUST':
			return('GLOWSTONE_DUST');
		case 'LIGHTGRAYDYE':
			return('LIGHT_GRAY_DYE');
		case 'YELLOW_DYE':
			return('DANDELION_YELLOW');
		case 'LIGHTBLUEDYE':
			return('LIGHT_BLUE_DYE');
		case 'STEAK':
			return('COOKED_BEEF');
		case 'SPECKLEDMELON':
			return('GLISTERING_MELON_SLICE');
	}
	return(null);
}
