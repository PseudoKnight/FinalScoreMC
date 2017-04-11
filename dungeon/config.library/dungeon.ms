@level = 5;
@maxRoomHeight = 8;

proc _set_locations(@start, @end){
	set_ploc(@start);
	set_block_at(_relative(@end, 'up'), data_values('beacon'), false);
}

proc _get_loot(@level, @random, @loot = array(
	array(0.50, associative_array('name': 'TORCH', 'qty': array(1, 10))),
	array(0.40, associative_array('name': 'BREAD', 'qty': array(1, 5))),
	array(0.35, associative_array('name': 'GOLDEN_APPLE')),
	array(0.25, associative_array('name': 'DIAMOND_AXE', 'data': 1546)),
	array(0.20, associative_array('name': 'DIAMOND_SWORD', 'data': 1546)),
	array(0.04, associative_array('name': 'LEATHER_HELMET')),
	array(0.04, associative_array('name': 'LEATHER_CHESTPLATE')),
	array(0.04, associative_array('name': 'LEATHER_LEGGINGS')),
	array(0.04, associative_array('name': 'LEATHER_BOOTS')),
	array(0.03, associative_array('name': 'GOLD_HELMET', 'data': 50)),
	array(0.03, associative_array('name': 'GOLD_CHESTPLATE', 'data': 50)),
	array(0.03, associative_array('name': 'GOLD_LEGGINGS', 'data': 50)),
	array(0.03, associative_array('name': 'GOLD_BOOTS', 'data': 50)),
	array(0.02, associative_array('name': 'CHAINMAIL_HELMET', 'data': 100)),
	array(0.02, associative_array('name': 'CHAINMAIL_CHESTPLATE', 'data': 100)),
	array(0.02, associative_array('name': 'CHAINMAIL_LEGGINGS', 'data': 100)),
	array(0.02, associative_array('name': 'CHAINMAIL_BOOTS', 'data': 100)),
	array(0.01, associative_array('name': 'IRON_HELMET', 'data': 150)),
	array(0.01, associative_array('name': 'IRON_CHESTPLATE', 'data': 150)),
	array(0.01, associative_array('name': 'IRON_LEGGINGS', 'data': 150)),
	array(0.01, associative_array('name': 'IRON_BOOTS', 'data': 150)),
	array(0.03, associative_array('name': 'SHIELD', 'data': 300)),
	array(0.03, associative_array('name': 'INK_SACK', 'data': 4, 'qty': array(1, 3))),
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
				'wall': array('24:0', '24:2'),
				'room': '0:0',
				'door': '0:0',
				'column': '24:1',
				'ladder': '65:3',
				'ceiling': '24:0',
				'floor': array('172:0'),
				'utility': array(58),
				'decor': array(31),
				'edge': array('128:4', '128:5', '128:6', '128:7'),
			));
		case 1:
			return(associative_array(
				'empty': '7:0',
				'wall': array('162'),
				'room': '0:0',
				'door': '0:0',
				'column': '162:1',
				'ladder': '65:3',
				'ceiling': '161:1',
				'floor': array('2'),
				'utility': array(58),
				'decor': array('18:2'),
				'edge': array('161', '161', '161', '161'),
			));
		case 2:
			return(associative_array(
				'empty': '7:0',
				'wall': array('112'),
				'room': '0:0',
				'door': '0:0',
				'column': '113',
				'ladder': '65:3',
				'ceiling': '112:0',
				'floor': array('112:1'),
				'utility': array(61, '145:2'),
				'decor': array('118:2'),
				'edge': array('114:4', '114:5', '114:6', '114:7'),
			));
		case 3:
			return(associative_array(
				'empty': '7:0',
				'wall': array('1:6', '98:0', '98:1', '98:2', '97:4'),
				'room': '0:0',
				'door': '0:0',
				'column': '47:0',
				'ladder': '65:3',
				'ceiling': '98:0',
				'floor': array('98:1'),
				'utility': array('58', '116', '117', '118:2'),
				'decor': array('66'),
				'edge': array('109:4', '109:5', '109:6', '109:7'),
			));
		default:
			return(associative_array(
				'empty': '7:0',
				'wall': array(201),
				'room': '0:0',
				'door': '0:0',
				'column': 202,
				'ladder': '65:3',
				'ceiling': 201,
				'floor': array(201),
				'utility': array('116'),
				'decor': array('199'),
				'edge': array('203:4', '203:5', '203:6', '203:7'),
			));
	}
}

proc _spawner_mobs(@level) {
	switch(@level) {
		case 0:
			return(array('ENDER_CRYSTAL', 'ENDERMITE', 'ZOMBIE'));
		case 1:
			return(array('CAVE_SPIDER', 'SPIDER', 'SILVERFISH'));
		case 2:
			return(array('PIG_ZOMBIE', 'MAGMA_CUBE', 'BLAZE'));
		case 3:
			return(array('ENDER_CRYSTAL', 'ZOMBIE',	'SPIDER', 'SILVERFISH', 'SKELETON', 'BLAZE', 'WITCH', 'CREEPER'));
		default:
			return(array('ENDER_CRYSTAL', 'ENDERMITE', 'ENDERMAN', 'GUARDIAN', 'SHULKER'));
	}
}
