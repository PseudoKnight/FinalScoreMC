proc _get_random_wave(@random, @waveNum) {
	@free = false;
	if(!@random) {
		@random = res_create_resource('RANDOM', time());
		@free = true;
	}
	@mobs = array(
		array(type: 'BEE', damage: 10, adjective: 'Buzzing', noun: 'Insects'),
		array(type: 'BLAZE', damage: 9, ranged: true, adjective: 'Blazing', noun: 'Powder'),
		array(type: 'CAVE_SPIDER', damage: 9, adjective: 'Poisonous', noun: 'Crawlers'),
		array(type: 'CREEPER', damage: 32, adjective: 'Explosive', noun: 'Bombers'),
		array(type: 'DROWNED', damage: 4.5, adjective: 'Gurgly', noun: 'Sea People'),
		array(type: 'ENDERMAN', damage: 10.5, adjective: 'Slender', noun: 'Teleporters'),
		array(type: 'ENDERMITE', damage: 3, adjective: 'Tiny', noun: 'Mites'),
		array(type: 'EVOKER', damage: 13.5, ranged: false, adjective: 'Magic', noun: 'Casters'),
		array(type: 'GHAST', damage: 25, ranged: true, adjective: 'Balloon', noun: 'Ghosts'),
		array(type: 'GUARDIAN', damage: 9, ranged: true, adjective: 'Spikey', noun: 'Lasers'),
		array(type: 'HUSK', damage: 4.5, unarmed: true, adjective: 'Hungry', noun: 'Desert Folk'),
		array(type: 'ILLUSIONER', damage: 5, ranged: true, adjective: 'Magic', noun: 'Mirror Man'),
		array(type: 'IRON_GOLEM', damage: 32, adjective: 'Lumbering', noun: 'Giants'),
		array(type: 'MAGMA_CUBE', damage: 4.5, adjective: 'Hot', noun: 'Magma',
			data: array(tags: array(size: 1))),
		array(type: 'MAGMA_CUBE', damage: 6, adjective: 'Hot', noun: 'Magma',
			data: array(tags: array(size: 2))),
		array(type: 'MAGMA_CUBE', damage: 9, adjective: 'Giant', noun: 'Magma',
			data: array(tags: array(size: 4))),
		array(type: 'PHANTOM', damage: 6, adjective: 'Flying', noun: 'Sting Rays'),
		array(type: 'PHANTOM', damage: 12, adjective: 'Gliding', noun: 'Sting Rays',
			data: array(tags: array(size: 6))),
		array(type: 'PILLAGER', damage: 4.5, ranged: true, adjective: 'Gray', noun: 'Raiders'),
		array(type: 'POLAR_BEAR', damage: 9, ranged: true, adjective: 'Protective', noun: 'Bears'),
		array(type: 'RABBIT', damage: 12, adjective: 'Hoppy', noun: 'Killer',
			data: array(tags: array(type: 'THE_KILLER_BUNNY'))),
		array(type: 'RAVAGER', damage: 18, adjective: 'Stompy', noun: 'Bisons'),
		array(type: 'SHULKER', damage: 5, ranged: true, adjective: 'Shy', noun: 'Blocks'),
		array(type: 'SILVERFISH', damage: 1.5, adjective: 'Wiggly', noun: 'Bugs'),
		array(type: 'SKELETON', damage: 4, ranged: true, adjective: 'Boney', noun: 'Archers'),
		array(type: 'SKELETON', damage: 3, unarmed: true, adjective: 'Spooky', noun: 'Skellies'),
		array(type: 'SLIME', damage: 3, adjective: 'Bouncy', noun: 'Cubes',
			data: array(tags: array(size: 2))),
		array(type: 'SLIME', damage: 6, adjective: 'Large', noun: 'Cubes',
			data: array(tags: array(size: 4))),
		array(type: 'SNOWMAN', damage: 2, ranged: true, adjective: 'Frosty', noun: 'Snowman',
			data: array(targetnear: 16)),
		array(type: 'SPIDER', damage: 3, adjective: 'Crawly', noun: 'Arachnids'),
		array(type: 'STRAY', damage: 5, ranged: true, adjective: 'Cold', noun: 'Wights'),
		array(type: 'STRAY', damage: 3, unarmed: true, adjective: 'Ragged', noun: 'Wights'),
		array(type: 'VEX', damage: 13.5, adjective: 'Spirit', noun: 'Fairies'),
		array(type: 'VEX', damage: 6, unarmed: true, adjective: 'Spirit', noun: 'Fairies'),
		array(type: 'VINDICATOR', damage: 19.5, adjective: 'Ill Tempered', noun: 'Axemen'),
		array(type: 'VINDICATOR', damage: 7.5, unarmed: true, adjective: 'Ill Tempered', noun: 'Butlers'),
		array(type: 'WITCH', damage: 18, ranged: true, adjective: 'Cackling', noun: 'Brewers'),
		array(type: 'WITHER', damage: 52, ranged: true, adjective: 'Ominous', noun: 'Boss'),
		array(type: 'WITHER_SKELETON', damage: 17, adjective: 'Withering', noun: 'Swordsmen'),
		array(type: 'WITHER_SKELETON', damage: 8, unarmed: true, adjective: 'Withering', noun: 'Coal Miners'),
		array(type: 'WOLF', damage: 6, adjective: 'Howling', noun: 'Pack'),
		array(type: 'ZOGLIN', damage: 12, adjective: 'Meatey', noun: 'Hogs'),
		array(type: 'ZOMBIE', damage: 4.5, unarmed: true, adjective: 'Fleshy', noun: 'Brain Eaters'),
		array(type: 'ZOMBIE_VILLAGER', damage: 4.5, unarmed: true, adjective: 'Unemployed', noun: 'Mumblers'),
		array(type: 'ZOMBIFIED_PIGLIN', damage: 12, adjective: 'Zombified', noun: 'Swarm'),
		array(type: 'ZOMBIFIED_PIGLIN', damage: 7,  unarmed: true, adjective: 'Zombified', noun: 'Swarm'),
	);
	@mobTypes = array();
	@numTypes = 1 + integer(srand(@random) * @waveNum * 0.1);
	while(@numTypes > 0) {
		@m = array_keys(@mobs)[integer(srand(@random) * array_size(@mobs))];
		if(@mobs[@m]['damage'] <= 2.5 + @waveNum / 2 && !array_contains(@mobTypes, @m)) {
			@mobTypes[] = @m;
			@numTypes--;
		}
	}

	@wave = array(mobs: array(), subtitle: '');
	foreach(@m in @mobTypes) {
		@mobData = @mobs[@m];
		@mob = array(type: @mobData['type']);
		if(array_index_exists(@mobData, 'ranged')) {
			@mob['count'] = 1 + integer(@waveNum / @mobData['damage'] / 3) + integer(srand(@random) * @waveNum / @mobData['damage'] / array_size(@mobTypes) / 3);
		} else {
			@mob['count'] = 1 + integer(@waveNum / @mobData['damage']) + integer(srand(@random) * @waveNum / @mobData['damage'] / array_size(@mobTypes));
		}
		if(array_index_exists(@mobData, 'unarmed')) {
			@mob['gear'] = array(WEAPON: null);
		}
		if(array_index_exists(@mobData, 'data')) {
			@mob = array_merge(@mob, @mobData['data']);
		}
		@wave['mobs'][] = @mob;
	}

	@nounIndex = @mobTypes[integer(srand(@random) * array_size(@mobTypes))];
	if(array_size(@mobTypes) > 1) {
		array_remove_values(@mobTypes, @nounIndex);
		@adjectiveIndex = @mobTypes[integer(srand(@random) * array_size(@mobTypes))];
		@wave['subtitle'] = @waveNum .': '. @mobs[@adjectiveIndex]['adjective'].' '.@mobs[@nounIndex]['noun'];
	} else {
		@wave['subtitle'] = @waveNum .': '.@mobs[@nounIndex]['noun'];
	}
	console('Wave #'.@waveNum.': '.@wave['subtitle']);

	if(@free) {
		res_free_resource(@random);
	}
	return(@wave);
}