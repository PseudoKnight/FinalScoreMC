proc _arena_bind_events(@id) {
	@pvp = import('pvp'.@id);
	@items = all_materials();
	@bannedItems = array(
		'STRUCTURE_VOID',
		'COMMAND_BLOCK',
		'CHAIN_COMMAND_BLOCK',
		'REPEATING_COMMAND_BLOCK',
		'COMMAND_BLOCK_MINECART',
		'JIGSAW',
		'STRUCTURE_BLOCK',
		'TEST_BLOCK',
		'DEBUG_STICK',
		'TEST_INSTANCE_BLOCK',
		'TEST_BLOCK',
		'LIGHT',
		'WATER_BUCKET',
		'COD_BUCKET',
		'SALMON_BUCKET',
		'TROPICAL_FISH_BUCKET',
		'PUFFERFISH_BUCKET',
		'AXOLOTL_BUCKET',
		'TADPOLE_BUCKET',
		'LAVA_BUCKET',
		'KNOWLEDGE_BOOK',
		'MAP',
		'FILLED_MAP',
		'FIREWORK_ROCKET',
		'ENDER_DRAGON_SPAWN_EGG',
		// special weapons
		'RED_CANDLE',
		'FIRE_CHARGE',
		'SUNFLOWER',
		'WITHER_SKELETON_SKULL',
		'GHAST_TEAR',
		'HEAVY_WEIGHTED_PRESSURE_PLATE',
	);
	foreach(@index: @material in @items) {
		if(!material_info(@material, 'isItem')
		|| array_contains(@bannedItems, @material)) {
			array_remove(@items, @index);
		}
	}

	@weapons = array_get(@pvp['arena'], 'weapons', array());
	if(array_contains(@weapons, 'dynamitestick')) {
		@items[] = array(name: 'RED_CANDLE', qty: 2, meta: array(display: 'Dynamite Stick', rarity: 'RARE'));
	}
	if(array_contains(@weapons, 'fireball')) {
		@items[] = array(name: 'FIRE_CHARGE', qty: 2, meta: array(display: 'Fireball', rarity: 'RARE'));
	}
	if(array_contains(@weapons, 'mine')) {
		@items[] = array(name: 'HEAVY_WEIGHTED_PRESSURE_PLATE', qty: 2, meta: array(display: 'Mine', rarity: 'RARE'));
	}
	if(array_contains(@weapons, 'pistoltears')) {
		@items[] = array(name: 'GHAST_TEAR', qty: 2, meta: array(display: 'Flintlock Pistol', rarity: 'RARE'));
	}
	if(array_contains(@weapons, 'railgun')) {
		@items[] = array(name: 'SUNFLOWER', qty: 2, meta: array(display: 'Railgun', rarity: 'RARE'));
	}
	if(array_contains(@weapons, 'skullrockets')) {
		@items[] = array(name: 'WITHER_SKELETON_SKULL', meta: array(display: 'Skull Rocket', rarity: 'RARE'));
	}
	@items[] = array(name: 'CROSSBOW', meta: array(display: 'Bowcaster', damage: 463, projectiles: array(array(name: 'ARROW')), rarity: 'RARE'));

	set_interval(3000, closure() {
		if(@pvp['running'] > 2) {
			clear_task();
			die();
		}
		try {
			foreach(@player in array_keys(@pvp['players'])) {
				if(pworld(@player) !== @pvp['arena']['world']) {
					throw(InvalidWorldException, 'Player was in wrong world.');
				}

				@item = array_get_rand(@items);

				if(is_array(@item)) {
					pgive_item(@player, @item);
					continue();
				}

				@itemArray = array(name: @item, qty: 1);
				if(material_info(@item, 'maxStacksize') > 1) {
					while(!rand(5)) {
						@itemArray['qty']++;
					}
				} else if(rand(2)) {
					@enchants = get_enchants(@itemArray);
					if(@enchants) {
						@itemArray['meta'] = array(enchants: associative_array());
						do {
							@enchant = array_get_rand(@enchants);
							array_remove_values(@enchants, @enchant);
							@itemArray['meta']['enchants'][@enchant] = rand(1, get_enchant_max(@enchant) + 1);
						} while(rand(2) && @enchants)
					}
				}
				if(@item === 'SUSPICIOUS_STEW') {
					@itemArray['meta'] = array(potions: array());
					@effects = reflect_pull('enum', 'PotionEffectType');
					@effect = array_get_rand(@effects);
					@itemArray['meta']['potions'][@effect] = array(
						seconds: rand(3, 12),
						strength: rand(2));
				} else if(@item === 'POTION' || @item === 'SPLASH_POTION' || @item === 'TIPPED_ARROW'
				|| @item === 'LINGERING_POTION') {
					if(rand(2)) {
						@potionType = array_get_rand(array('INFESTED', 'SWIFTNESS', 'LONG_SWIFTNESS',
						'STRONG_SWIFTNESS', 'SLOWNESS', 'LONG_SLOWNESS', 'STRONG_SLOWNESS',	'STRENGTH',
						'LONG_STRENGTH', 'STRONG_STRENGTH', 'HARMING', 'STRONG_HARMING', 'HEALING', 'STRONG_HEALING',
						'LEAPING', 'LONG_LEAPING', 'STRONG_LEAPING', 'OOZING', 'SLOW_FALLING', 'LONG_SLOW_FALLING',
						'REGENERATION', 'LONG_REGENERATION', 'STRONG_REGENERATION', 'FIRE_RESISTANCE',
						'LONG_FIRE_RESISTANCE', 'INVISIBILITY', 'LONG_INVISIBILITY', 'NIGHT_VISION',
						'LONG_NIGHT_VISION', 'WEAKNESS', 'LONG_WEAKNESS', 'WEAVING', 'POISON', 'LONG_POISON',
						'STRONG_POISON', 'TURTLE_MASTER', 'LONG_TURTLE_MASTER', 'STRONG_TURTLE_MASTER', 'WIND_CHARGED'));
						@itemArray['meta'] = array(potiontype: @potionType);
					} else {
						@itemArray['meta'] = array(potions: array());
						@effects = reflect_pull('enum', 'PotionEffectType');
						do {
							@effect = array_get_rand(@effects);
							@itemArray['meta']['potions'][@effect] = array(
								seconds: rand(1, 480),
								strength: rand(3));
						} while(rand(2))
					}
				} else if(@item === 'ENCHANTED_BOOK') {
					@enchants = array(
						'power', 'flame', 'infinity', 'punch', 'sharpness', 'efficiency', 'fire_aspect', 'knockback',
						'fortune', 'looting', 'protection', 'fire_protection', 'projectile_protection', 'thorns',
						'sweeping_edge', 'loyalty', 'swift_sneak', 'piercing', 'multishot', 'quick_charge', 'breach',
						'density', 'wind_burst', 'lunge');
					@itemArray['meta'] = array(stored: associative_array());
					do {
						@enchant = array_get_rand(@enchants);
						@itemArray['meta']['stored'][@enchant] = 1;
					} while(rand(2))
				} else if(@item === 'BEEHIVE' || @item === 'BEE_NEST') {
					@itemArray['meta'] = array(beecount: 3);
				} else if(@item === 'CROSSBOW') {
					if(rand(2)) {
						if(!array_index_exists(@itemArray, 'meta')) {
							@itemArray['meta'] = associative_array();
						}
						if(rand(2)) {
							@itemArray['meta']['projectiles'] = array(array(name: 'ARROW'));
						} else {
							@itemArray['meta']['projectiles'] = array(array(name: 'FIREWORK_ROCKET', meta: array(firework: array(
								effects: array(array(type: 'LARGE_BALL'), array(type: 'LARGE_BALL'), array(type: 'LARGE_BALL')),
								strength: 1))));
						}
					}
				} else if(@item === 'SPAWNER') {
					@spawnTypes = array('ALLAY', 'ARMADILLO', 'AXOLOTL', 'BAT', 'BEE', 'CAMEL', 'CAT', 'CHICKEN', 'COD',
						'COPPER_GOLEM', 'COW', 'DOLPHIN', 'DONKEY', 'FOX', 'FROG', 'GLOW_SQUID', 'GOAT', 'HAPPY_GHAST',
						'HORSE', 'IRON_GOLEM', 'LLAMA', 'MAGMA_CUBE', 'MULE', 'MOOSHROOM', 'OCELOT', 'PANDA', 'PARROT',
						'PIG', 'POLAR_BEAR', 'RABBIT', 'SALMON', 'SHEEP', 'SNIFFER', 'SNOW_GOLEM', 'SQUID', 'STRIDER',
						'TADPOLE', 'TRADER_LLAMA', 'TROPICAL_FISH', 'VILLAGER', 'WANDERING_TRADER', 'WOLF',
						'ZOMBIE_HORSE', 'BOGGED', 'BREEZE', 'CAVE_SPIDER', 'CREAKING', 'CREEPER', 'DROWNED',
						'ELDER_GUARDIAN', 'ENDERMAN', 'ENDERMITE', 'EVOKER', 'GHAST', 'GUARDIAN', 'HOGLIN', 'HUSK',
						'PHANTOM', 'PIGLIN', 'PIGLIN_BRUTE', 'PILLAGER', 'PUFFERFISH', 'RAVAGER', 'SHULKER',
						'SILVERFISH', 'SKELETON', 'SKELETON_HORSE', 'SLIME', 'SPIDER', 'STRAY', 'VEX', 'VINDICATOR',
						'WITCH', 'WITHER_SKELETON', 'ZOGLIN', 'ZOMBIE', 'ZOMBIE_VILLAGER', 'ZOMBIFIED_PIGLIN');
					@itemArray['meta'] = array(spawntype: array_get_rand(@spawnTypes));
				}
				pgive_item(@player, @itemArray);
			}
		} catch(Exception @ex) {
			console(@ex['message']);
			clear_task();
		}
	});
}