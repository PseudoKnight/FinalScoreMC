@level = 9;
@maxRoomHeight = 9;

proc _set_locations(@start, @end, @spawns){
	set_ploc(@start);
	
	set_block_at(@end, data_values('beacon'), false);
}

proc _get_loot(@level, @random, @loot = array(

	array('chance': 0.60, 'item': array('name': 'TORCH', 'qty': array(1, 16))),
	array('chance': 0.40, 'item': array('name': 'BREAD', 'qty': array(1, 4))),
	array('chance': 0.35, 'item': array('name': 'GOLDEN_APPLE')),
	array('chance': 0.15, 'item': array('name': 'ARROW', 'qty': array(1, 6))),
	array('chance': 0.07, 'item': array('name': 'WOOD_SWORD')),
	array('chance': 0.05, 'item': array('name': 'STONE_SWORD'), 'data': 132),
	array('chance': 0.03, 'item': array('name': 'GOLD_SWORD'), 'data': 33),
	array('chance': -0.01, 'item': array('name': 'IRON_SWORD'), 'data': 251),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_SWORD'), 'data': 1562),
	array('chance': 0.07, 'item': array('name': 'WOOD_AXE')),
	array('chance': 0.05, 'item': array('name': 'STONE_AXE'), 'data': 132),
	array('chance': -0.01, 'item': array('name': 'IRON_AXE'), 'data': 251),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_AXE'), 'data': 1562),
	array('chance': 0.03, 'item': array('name': 'BOW'), 'data': 385),
	array('chance': 0.06, 'item': array('name': 'LEATHER_HELMET')),
	array('chance': 0.06, 'item': array('name': 'LEATHER_CHESTPLATE')),
	array('chance': 0.06, 'item': array('name': 'LEATHER_LEGGINGS')),
	array('chance': 0.06, 'item': array('name': 'LEATHER_BOOTS')),
	array('chance': 0.04, 'item': array('name': 'GOLD_HELMET')),
	array('chance': 0.04, 'item': array('name': 'GOLD_CHESTPLATE')),
	array('chance': 0.04, 'item': array('name': 'GOLD_LEGGINGS')),
	array('chance': 0.04, 'item': array('name': 'GOLD_BOOTS')),
	array('chance': 0.02, 'item': array('name': 'CHAINMAIL_HELMET'), 'data': 166),
	array('chance': 0.02, 'item': array('name': 'CHAINMAIL_CHESTPLATE'), 'data': 241),
	array('chance': 0.02, 'item': array('name': 'CHAINMAIL_LEGGINGS'), 'data': 226),
	array('chance': 0.02, 'item': array('name': 'CHAINMAIL_BOOTS'), 'data': 196),
	array('chance': -0.00, 'item': array('name': 'IRON_HELMET'), 'data': 166),
	array('chance': -0.00, 'item': array('name': 'IRON_CHESTPLATE'), 'data': 241),
	array('chance': -0.00, 'item': array('name': 'IRON_LEGGINGS'), 'data': 226),
	array('chance': -0.00, 'item': array('name': 'IRON_BOOTS'), 'data': 166),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_HELMET'), 'data': 364),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_CHESTPLATE'), 'data': 529),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_LEGGINGS'), 'data': 496),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_BOOTS'), 'data': 430),
	array('chance': 0.00, 'item': array('name': 'TOTEM')),
	array('chance': 0.01, 'item': array('name': 'GOLDEN_CARROT', 'qty': array(1, 4))),
	array('chance': 0.01, 'item': array('name': 'SHIELD'), 'data': 336),
	array('chance': 0.01, 'item': array('name': 'INK_SACK', 'data': 4, 'qty': array(1, 4))),
)) {
	@inv = array();
	foreach(@weightedLoot in @loot){
		if(srand(@random) < @weightedLoot['chance'] + @level * 0.01){
			@item = @weightedLoot['item'][];
			if(array_index_exists(@item, 'qty') && is_array(@item['qty'])) {
				@item['qty'] = integer(srand(@random) * (@item['qty'][1] - @item['qty'][0]) + @item['qty'][0]);
			}
			if(array_index_exists(@weightedLoot, 'data')) {
				@item['data'] = integer(srand(@random) * @weightedLoot['data']);
			}
			@inv[] = @item;
		}
	}
	return(@inv);
}

proc _materials(@level) {
	switch(@level) {
		case 0:
			return(array(
				'empty': '7:0',
				'wall': array('1:0', '1:0', '1:0', '1:0', '1:0', '1:0', '1:0', '1:0', '1:5', '1:5', '1:5', '15:0'),
				'room': '0:0',
				'door': '0:0',
				'column': '1:0',
				'ladder': '65:3',
				'ceiling': array('1:0', '1:0', '1:0', '1:0', '1:0', '1:0', '1:0', '1:0', '1:5', '1:5', '1:5', '15:0'),
				'floor': array('1:0', '1:0', '1:0', '1:0', '1:0', '1:0', '1:0', '1:0', '1:5', '1:5', '1:5', '15:0'),
				'utility': array('14:0'),
				'decor': array('1:0'),
				'edge': array('1:0', '1:0', '1:0', '1:0'),
			));
		case 1:
			return(array(
				'empty': '7:0',
				'wall': array('162'),
				'room': '0:0',
				'door': '0:0',
				'column': '162:1',
				'ladder': '65:3',
				'ceiling': array('18:2', '161:1'),
				'floor': array('2', '3:2'),
				'utility': array(58),
				'decor': array('18:2', '30'),
				'edge': array('161', '161', '161', '161'),
			));
		case 2:
			return(array(
				'empty': '7:0',
				'wall': array('24:0', '24:2'),
				'room': '0:0',
				'door': '0:0',
				'column': '24:1',
				'ladder': '65:3',
				'ceiling': array('24:0'),
				'floor': array('172:0'),
				'utility': array(58),
				'decor': array(31),
				'edge': array('128:4', '128:5', '128:6', '128:7'),
			));
		case 3:
			return(array(
				'empty': '7:0',
				'wall': array('80', '174'),
				'room': '0:0',
				'door': '0:0',
				'column': '174',
				'ladder': '65:3',
				'ceiling': array('80', '174'),
				'floor': array('80', '174'),
				'utility': array(58),
				'decor': array('174'),
				'edge': array('80', '80', '80', '80'),
			));
		case 4:
			return(array(
				'empty': '7:0',
				'wall': array('112'),
				'room': '0:0',
				'door': '0:0',
				'column': '113',
				'ladder': '65:3',
				'ceiling': array('112:0'),
				'floor': array('112:1', '112:1', '112:1', '112:1', '112:1', '112:1', '213', '88'),
				'utility': array(61, '145:2'),
				'decor': array('118:2'),
				'edge': array('114:4', '114:5', '114:6', '114:7'),
			));
		case 5:
			return(array(
				'empty': '7:0',
				'wall': array('1:6', '98:0', '98:1', '98:2', '97:4'),
				'room': '0:0',
				'door': '0:0',
				'column': '47:0',
				'ladder': '65:3',
				'ceiling': array('98:0'),
				'floor': array('98:1', '98:1', '98:1', '98:1', '98:1', '98:1', '98:2', '98:2', '9:0'),
				'utility': array('58', '116', '117', '118:2'),
				'decor': array('66'),
				'edge': array('109:4', '109:5', '109:6', '109:7'),
			));
		case 6:
			return(array(
				'empty': '7:0',
				'wall': array('168:1'),
				'room': '9:0',
				'door': '9:0',
				'column': '168:1',
				'ladder': '65:3',
				'ceiling': array('168'),
				'floor': array('168:2'),
				'utility': array('169'),
				'decor': array('169'),
				'edge': array('168:2', '168:2', '168:2', '168:2'),
			));
		case 7:
			return(array(
				'empty': '7:0',
				'wall': array('5:5'),
				'room': '0:0',
				'door': '0:0',
				'column': '139:0',
				'ladder': '65:3',
				'ceiling': array('5:2'),
				'floor': array('5:2'),
				'utility': array('116'),
				'decor': array('47'),
				'edge': array('135:4', '135:5', '135:6', '135:7'),
			));
		default:
			return(array(
				'empty': '7:0',
				'wall': array(201),
				'room': '0:0',
				'door': '0:0',
				'column': 202,
				'ladder': '65:3',
				'ceiling': array(201),
				'floor': array(121),
				'utility': array('116'),
				'decor': array('199'),
				'edge': array('203:4', '203:5', '203:6', '203:7'),
			));
	}
}

proc _level_mobs(@level) {
	switch(@level) {
		case 0:
			return(array(
				'spawner': array(),
			 	'single': array()
			));
		case 1:
			return(array(
				'spawner': array('CAVE_SPIDER', 'SPIDER'),
				'single': array()
			));
		case 2:
			return(array(
				'spawner': array('ENDER_CRYSTAL', 'ZOMBIE_VILLAGER'),
				'single': array('HUSK')
			));
		case 3:
			return(array(
				'spawner': array(),
				'single': array('STRAY', 'POLAR_BEAR')
			));
		case 4:
			return(array(
				'spawner': array('PIG_ZOMBIE', 'MAGMA_CUBE', 'BLAZE'),
				'single': array()
			));
		case 5:
			return(array(
				'spawner': array('ENDER_CRYSTAL', 'SKELETON', 'WITCH', 'CREEPER'),
				'single': array('SILVERFISH')
			));
		case 6:
			return(array(
				'spawner': array('GUARDIAN'),
				'single': array('SQUID')
			));
		case 7:
			return(array(
				'spawner': array('VINDICATOR'),
				'single': array('EVOKER')
			));
		default:
			return(array(
				'spawner': array('ENDER_CRYSTAL', 'ENDERMITE', 'ENDERMAN', 'SHULKER'),
				'single': array()
			));
	}
}
