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
		if(material_info(@material, 'isItem')
		&& !array_contains(@bannedItems, @material)) {
			@items[@index] = to_lower(@material);
		} else {
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
					throw(Exception, 'Player was in wrong world.');
				}
				@inv = pinv(@player);
				@slot = -1;
				while(++@slot < 9) {
					if(!@inv[@slot]) {
						@item = array_get_rand(@items);
						if(is_array(@item)) {
							set_pinv(@player, @slot, @item);
						} else {
							@qty = 1;
							if(material_info(@item, 'maxStackSize') > 1) {
								while(!rand(5)) {
									@qty++;
								}
							}
							set_pinv(@player, @slot, array(name: @item, qty: @qty));
						}
						break();
					}
				}
			}
		} catch(Exception @ex) {
			console(@ex['message']);
			clear_task();
		}
	});
}