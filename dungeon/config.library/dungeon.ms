@level = 8;
@maxRoomHeight = 9;

proc _set_locations(@start, @end, @spawns){
	set_ploc(@start);
	
	set_block_at(@end, data_values('beacon'), false);
}

proc _get_loot(@level, @random, @loot = array(

	array(0.50, associative_array('name': 'TORCH', 'qty': array(1, 9))),
	array(0.40, associative_array('name': 'BREAD', 'qty': array(1, 4))),
	array(0.40, associative_array('name': 'IRON_SWORD')),
	array(0.35, associative_array('name': 'GOLDEN_APPLE')),
	array(0.20, associative_array('name': 'ARROW', 'qty': array(1, 8))),
	array(0.25, associative_array('name': 'DIAMOND_AXE', 'data': 1546)),
	array(0.20, associative_array('name': 'DIAMOND_SWORD', 'data': 1546)),
	array(0.04, associative_array('name': 'BOW', 'data': 376)),
	array(0.05, associative_array('name': 'LEATHER_HELMET')),
	array(0.05, associative_array('name': 'LEATHER_CHESTPLATE')),
	array(0.05, associative_array('name': 'LEATHER_LEGGINGS')),
	array(0.05, associative_array('name': 'LEATHER_BOOTS')),
	array(0.04, associative_array('name': 'GOLD_HELMET', 'data': 50)),
	array(0.04, associative_array('name': 'GOLD_CHESTPLATE', 'data': 50)),
	array(0.04, associative_array('name': 'GOLD_LEGGINGS', 'data': 50)),
	array(0.04, associative_array('name': 'GOLD_BOOTS', 'data': 50)),
	array(0.03, associative_array('name': 'CHAINMAIL_HELMET', 'data': 100)),
	array(0.03, associative_array('name': 'CHAINMAIL_CHESTPLATE', 'data': 100)),
	array(0.03, associative_array('name': 'CHAINMAIL_LEGGINGS', 'data': 100)),
	array(0.03, associative_array('name': 'CHAINMAIL_BOOTS', 'data': 100)),
	array(0.02, associative_array('name': 'IRON_HELMET', 'data': 125)),
	array(0.02, associative_array('name': 'IRON_CHESTPLATE', 'data': 200)),
	array(0.02, associative_array('name': 'IRON_LEGGINGS', 'data': 185)),
	array(0.02, associative_array('name': 'IRON_BOOTS', 'data': 155)),
	array(0.01, associative_array('name': 'DIAMOND_HELMET', 'data': 333)),
	array(0.01, associative_array('name': 'DIAMOND_CHESTPLATE', 'data': 498)),
	array(0.01, associative_array('name': 'DIAMOND_LEGGINGS', 'data': 465)),
	array(0.01, associative_array('name': 'DIAMOND_BOOTS', 'data': 399)),
	array(0.01, associative_array('name': 'TOTEM')),
	array(0.01, associative_array('name': 'GOLDEN_CARROT'), 'qty': array(8, 16)),
	array(0.03, associative_array('name': 'SHIELD', 'data': 300)),
	array(0.03, associative_array('name': 'INK_SACK', 'data': 4, 'qty': array(1, 4))),
)) {
	@inv = array();
	foreach(@weightedLoot in @loot){
		if(srand(@random) < @weightedLoot[0]){
			if(array_index_exists(@weightedLoot[1], 'qty')
			&& is_array(@weightedLoot[1]['qty'])) {
				@item = @weightedLoot[1][];
				@item['qty'] = integer(srand(@random) * (@item['qty'][1] - @item['qty'][0]) + @item['qty'][0]);
			} else {
				@item = @weightedLoot[1];
			}
			@inv[] = @item;
		}
	}
	return(@inv);
}

proc _materials(@level) {
	switch(@level) {
		case 0:
			return(associative_array(
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
			return(associative_array(
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
		case 2:
			return(associative_array(
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
		case 3:
			return(associative_array(
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
		case 4:
			return(associative_array(
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
		case 5:
			return(associative_array(
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
		case 6:
			return(associative_array(
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
			return(associative_array(
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

proc _spawner_mobs(@level) {
	switch(@level) {
		case 0:
			return(array('ZOMBIE', 'SPIDER'));
		case 1:
			return(array('ENDER_CRYSTAL', 'ENDERMITE', 'ZOMBIE_VILLAGER'));
		case 2:
			return(array('CAVE_SPIDER', 'SPIDER', 'SILVERFISH'));
		case 3:
			return(array('PIG_ZOMBIE', 'MAGMA_CUBE', 'BLAZE'));
		case 4:
			return(array('ENDER_CRYSTAL', 'ZOMBIE',	'SPIDER', 'SILVERFISH', 'SKELETON', 'STRAY', 'WITCH', 'CREEPER'));
		case 5:
			return(array('GUARDIAN'));
		case 6:
			return(array('VINDICATOR', 'VEX', 'EVOKER'));
		default:
			return(array('ENDER_CRYSTAL', 'ENDERMITE', 'ENDERMAN', 'SHULKER'));
	}
}
