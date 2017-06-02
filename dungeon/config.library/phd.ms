@maxRoomHeight = 8;

proc _set_locations(@start, @end, @spawns){
	_start_game(@start, @end, @spawns);
}

proc _get_loot(@level, @random) {
	return(array());
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

proc _level_mobs(@level) {
	return(array('spawner': array(), 'single': array()));
}
