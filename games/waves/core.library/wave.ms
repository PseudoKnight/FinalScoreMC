proc _get_random_wave(@random, @waveNum) {
	@free = false;
	if(!@random) {
		@random = res_create_resource('RANDOM', time());
		@free = true;
	}
	@mobs = array(
	1: array(
		array(type: 'ENDERMITE', adjective: 'Tiny', noun: 'Mites'),
		array(type: 'DROWNED', adjective: 'Gurgly', noun: 'Sea People',
			gear: array(weapon: null)),
		array(type: 'HUSK', adjective: 'Hungry', noun: 'Desert Folk',
			gear: array(weapon: null, helmet: null, chestplate: null, leggings: null, boots: null)),
		array(type: 'MAGMA_CUBE', adjective: 'Hot', noun: 'Magma',
			tags: array(size: 1)),
		array(type: 'SILVERFISH', adjective: 'Wiggly', noun: 'Bugs'),
		array(type: 'SLIME', adjective: 'Bouncy', noun: 'Cubes',
			tags: array(size: 2)),
		array(type: 'ZOMBIE', adjective: 'Fleshy', noun: 'Brain Eaters',
			gear: array(weapon: null, helmet: null, chestplate: null, leggings: null, boots: null)),
		array(type: 'ZOMBIE_VILLAGER', adjective: 'Unemployed', noun: 'Mumblers',
			gear: array(weapon: null, helmet: null, chestplate: null, leggings: null, boots: null)),
		array(type: 'CREAKING', adjective: 'Creaking', noun: 'Tangle',
			health: 6.0), // crit with wood sword
	),
	2: array(
		array(type: 'BEE', adjective: 'Buzzing', noun: 'Insects'),
		array(type: 'BOGGED', adjective: 'Boggy', noun: 'Mushheads',
			gear: array(weapon: null, helmet: null, chestplate: null, leggings: null, boots: null)),
		array(type: 'MAGMA_CUBE', adjective: 'Hot', noun: 'Magma',
			tags: array(size: 2)),
		array(type: 'SKELETON', adjective: 'Spooky', noun: 'Skellies',
			gear: array(weapon: null, helmet: null, chestplate: null, leggings: null, boots: null)),
		array(type: 'SLIME', adjective: 'Large', noun: 'Cubes',
			tags: array(size: 4)),
		array(type: 'SPIDER', adjective: 'Crawly', noun: 'Arachnids'),
		array(type: 'STRAY', adjective: 'Ragged', noun: 'Wights',
			gear: array(weapon: null, helmet: null, chestplate: null, leggings: null, boots: null)),
		array(type: 'WOLF', adjective: 'Howling', noun: 'Pack'),
	),
	3: array(
		array(type: 'BREEZE', adjective: 'Breezy', noun: 'Tornados'),
		array(type: 'GUARDIAN', adjective: 'Spikey', noun: 'Lasers'),
		array(type: 'MAGMA_CUBE', adjective: 'Giant', noun: 'Magma',
			tags: array(size: 4)),
		array(type: 'PHANTOM', adjective: 'Flying', noun: 'Sting Rays'),
		array(type: 'PILLAGER', adjective: 'Gray', noun: 'Raiders'),
		array(type: 'POLAR_BEAR', adjective: 'Protective', noun: 'Bears'),
		array(type: 'SHULKER', adjective: 'Shy', noun: 'Blocks'),
		array(type: 'SKELETON', adjective: 'Boney', noun: 'Archers'),
		array(type: 'STRAY', adjective: 'Cold', noun: 'Wights'),
		array(type: 'VEX', adjective: 'Spirit', noun: 'Fairies',
			gear: array(weapon: null)),
		array(type: 'VINDICATOR', adjective: 'Ill Tempered', noun: 'Butlers',
			gear: array(weapon: null)),
		array(type: 'ZOMBIFIED_PIGLIN', adjective: 'Zombified', noun: 'Swarm',
			gear: array(weapon: null)),
	),
	4: array(
		array(custom: 'worm', adjective: 'Wormy', noun: 'Worm'),
		array(type: 'BOGGED', adjective: 'Poisonous', noun: 'Mushheads'),
		array(type: 'BLAZE', adjective: 'Blazing', noun: 'Powder'),
		array(type: 'CAVE_SPIDER', adjective: 'Poisonous', noun: 'Crawlers'),
		array(type: 'GHAST', adjective: 'Balloon', noun: 'Ghosts'),
		array(type: 'CREEPER', adjective: 'Explosive', noun: 'Bombers'),
		array(type: 'ILLUSIONER', adjective: 'Magic', noun: 'Mirror Man'),
		array(type: 'PHANTOM', adjective: 'Gliding', noun: 'Sting Rays',
			tags: array(size: 6)),
		array(type: 'RABBIT', adjective: 'Hoppy', noun: 'Killer',
			tags: array(type: 'THE_KILLER_BUNNY')),
		array(type: 'WITHER_SKELETON', adjective: 'Withering', noun: 'Coal Miners',
			gear: array(weapon: null)),
		array(type: 'ZOGLIN', adjective: 'Meatey', noun: 'Hogs'),
		array(type: 'ZOMBIFIED_PIGLIN', adjective: 'Zombified', noun: 'Swarm'),
		array(type: 'WITCH', adjective: 'Cackling', noun: 'Brewers'),
	),
	5: array(
		array(type: 'IRON_GOLEM', adjective: 'Lumbering', noun: 'Giant'),
		array(type: 'ELDER_GUARDIAN', adjective: 'Ocean', noun: 'King'),
		array(type: 'ENDERMAN', adjective: 'Slender', noun: 'Teleporters'),
		array(type: 'EVOKER', adjective: 'Magic', noun: 'Casters'),
		array(type: 'RAVAGER', adjective: 'Stompy', noun: 'Bisons'),
		array(type: 'VINDICATOR', adjective: 'Ill Tempered', noun: 'Axemen'),
		array(type: 'VEX', adjective: 'Spirit', noun: 'Fairies'),
		array(type: 'WITHER_SKELETON', adjective: 'Withering', noun: 'Swordsmen'),
	),
	6: array(
		array(type: 'WARDEN', adjective: 'The', noun: 'Warden'),
		array(type: 'WITHER', adjective: 'The', noun: 'Wither'),
	));
	@wave = array(mobs: array(), subtitle: '');
	@totalCount = max(1, integer(@waveNum * 0.25 + srand(@random) * @waveNum * 0.75));
	@numTypes = if(@waveNum >= 5, 2, 1);
	while(@numTypes > 0 && @totalCount > 0) {
		@tier = 1;
		if(!@wave['mobs']) {
			@tier = 1 + integer(@waveNum / 10);
		} else if(array_size(@wave['mobs']) == 1) {
			@tier = max(1, integer(@waveNum / 10));
		}
		@mobData = @mobs[@tier][integer(srand(@random) * array_size(@mobs[@tier]))][];
		if(@waveNum == 50) {
			@wave['duplicate'] = 1;
			@mobData['count'] = 1;
			@totalCount = 0;
		} else if(!@wave['mobs']) {
			@mobData['count'] = min(@totalCount, @waveNum % 10 + 1);
		} else {
			@mobData['count'] = ceil(srand(@random) * @totalCount);
		}
		if(@mobData['count'] == 1) {
			@mobData['pos'] = 'center';
		}
		@totalCount -= @mobData['count'];
		@wave['mobs'][] = @mobData;
		@numTypes--;
	}

	@wave['effects'] = array(array(id: 'regeneration', strength: 1, seconds: 6));

	if(@waveNum == 50) {
		if(@wave['mobs'][0]['type'] == 'WARDEN') {
			@wave['music'] = 'music.overworld.deep_dark';
		} else {
			@wave['music'] = 'music.nether.basalt_deltas';
		}
	} else if(@waveNum == 40) {
		@wave['music'] = 'music.credits';
	} else if(@waveNum % 10 == 0) {
		@wave['music'] = 'music.game';
	}

	if(array_size(@wave['mobs']) > 1) {
		@wave['bossbar'] = color('bold').@waveNum .': '. @wave['mobs'][1]['adjective'].' '.@wave['mobs'][0]['noun'];
	} else {
		@wave['bossbar'] = color('bold').@waveNum .': '.@wave['mobs'][0]['noun'];
	}
	console('Wave '.@wave['bossbar']);

	if(@free) {
		res_free_resource(@random);
	}
	return(@wave);
}