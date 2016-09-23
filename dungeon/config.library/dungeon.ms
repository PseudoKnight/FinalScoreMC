@level = 5;
@scale = 2;

proc _set_locations(@start, @end){
	noop();
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
				'stairs': '128:2',
				'ceiling': '24:0',
				'floor': '172:0',
				'utility': array(58),
				'decor': array(31),
			));
		case 1:
			return(associative_array(
				'empty': '7:0',
				'wall': array('162'),
				'room': '0:0',
				'door': '0:0',
				'column': '162:1',
				'stairs': '164:2',
				'ceiling': '161:1',
				'floor': '2',
				'utility': array(58),
				'decor': array('18:2'),
			));
		case 2:
			return(associative_array(
				'empty': '7:0',
				'wall': array('112'),
				'room': '0:0',
				'door': '0:0',
				'column': '113',
				'stairs': '114:2',
				'ceiling': '112:0',
				'floor': '112:1',
				'utility': array(61, '145:2'),
				'decor': array('118:2'),
			));
		case 3:
			return(associative_array(
				'empty': '7:0',
				'wall': array('1:0', '98:0', '98:1', '98:2', '98:3', '97:4'),
				'room': '0:0',
				'door': '0:0',
				'column': '47:0',
				'stairs': '109:2',
				'ceiling': '98:0',
				'floor': '98:1',
				'utility': array('58', '116', '117', '118:2'),
				'decor': array('66'),
			));
		default:
			return(associative_array(
				'empty': '7:0',
				'wall': array(201),
				'room': '0:0',
				'door': '0:0',
				'column': 202,
				'stairs': '203:2',
				'ceiling': 201,
				'floor': 201,
				'utility': array('116'),
				'decor': array('199'),
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
