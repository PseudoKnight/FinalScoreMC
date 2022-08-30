proc _get_loot(@floor, @random, @bonus = 1.0, @loot = array(
	array(chance: 0.50, item: 'TORCH', qty: array(1, 16)),
	array(chance: 0.08, item: 'APPLE', qty: array(1, 10)),
	array(chance: 0.04, item: 'BREAD', qty: array(1, 10)),
	array(chance: 0.02, item: 'PORKCHOP', qty: array(1, 10)),
	array(chance: 0.00, item: 'GOLDEN_CARROT', qty: array(1, 10)),
	array(chance: 0.20, item: 'GOLDEN_APPLE'),
	array(chance: 0.15, item: 'ARROW', qty: array(1, 6)),
	array(chance: 0.07, item: 'WOODEN_SWORD', damage: 60),
	array(chance: 0.05, item: 'STONE_SWORD', damage: 132),
	array(chance: 0.03, item: 'GOLDEN_SWORD', damage: 33),
	array(chance: -0.01, item: 'IRON_SWORD', damage: 251),
	array(chance: -0.03, item: 'DIAMOND_SWORD', damage: 1562),
	array(chance: -0.06, item: 'NETHERITE_SWORD', damage: 2032),
	array(chance: 0.07, item: 'WOODEN_AXE', damage: 60),
	array(chance: 0.05, item: 'STONE_AXE', damage: 132),
	array(chance: -0.01, item: 'IRON_AXE', damage: 251),
	array(chance: -0.03, item: 'DIAMOND_AXE', damage: 1562),
	array(chance: -0.06, item: 'NETHERITE_AXE', damage: 2032),
	array(chance: -0.03, item: 'TRIDENT', damage: 251),
	array(chance: 0.03, item: 'BOW', damage: 385),
	array(chance: 0.03, item: 'CROSSBOW', damage: 466),
	array(chance: 0.03, item: 'BONE'),
	array(chance: 0.07, item: 'LEATHER_HELMET', damage: 56),
	array(chance: 0.07, item: 'LEATHER_CHESTPLATE', damage: 81),
	array(chance: 0.07, item: 'LEATHER_LEGGINGS', damage: 76),
	array(chance: 0.07, item: 'LEATHER_BOOTS', damage: 66),
	array(chance: 0.04, item: 'GOLDEN_HELMET', damage: 78),
	array(chance: 0.04, item: 'GOLDEN_CHESTPLATE', damage: 113),
	array(chance: 0.04, item: 'GOLDEN_LEGGINGS', damage: 106),
	array(chance: 0.04, item: 'GOLDEN_BOOTS', damage: 92),
	array(chance: 0.01, item: 'CHAINMAIL_HELMET', damage: 166),
	array(chance: 0.01, item: 'CHAINMAIL_CHESTPLATE', damage: 241),
	array(chance: 0.01, item: 'CHAINMAIL_LEGGINGS', damage: 226),
	array(chance: 0.01, item: 'CHAINMAIL_BOOTS', damage: 196),
	array(chance: -0.02, item: 'IRON_HELMET', damage: 166),
	array(chance: -0.02, item: 'IRON_CHESTPLATE', damage: 241),
	array(chance: -0.02, item: 'IRON_LEGGINGS', damage: 226),
	array(chance: -0.02, item: 'IRON_BOOTS', damage: 166),
	array(chance: -0.05, item: 'DIAMOND_HELMET', damage: 364),
	array(chance: -0.05, item: 'DIAMOND_CHESTPLATE', damage: 529),
	array(chance: -0.05, item: 'DIAMOND_LEGGINGS', damage: 496),
	array(chance: -0.05, item: 'DIAMOND_BOOTS', damage: 430),
	array(chance: -0.06, item: 'NETHERITE_HELMET', damage: 408),
	array(chance: -0.06, item: 'NETHERITE_CHESTPLATE', damage: 593),
	array(chance: -0.06, item: 'NETHERITE_LEGGINGS', damage: 556),
	array(chance: -0.06, item: 'NETHERITE_BOOTS', damage: 482),
	array(chance: -0.06, item: 'TURTLE_HELMET', damage: 276),
	array(chance: -0.06, item: 'TOTEM_OF_UNDYING'),
	array(chance: 0.01, item: 'SHIELD', damage: 336),
	array(chance: 0.03, item: 'LAPIS_LAZULI'),
	array(chance: 0.04, item: 'IRON_INGOT'),
	array(chance: 0.03, item: 'DIAMOND'),
	array(chance: 0.04, item: 'POTION'),
	array(chance: 0.04, item: 'SPLASH_POTION'),
	array(chance: 0.04, item: 'MILK_BUCKET'),
	array(chance: 0.01, item: 'ENDER_PEARL'),
	array(chance: 0.01, item: 'ENCHANTED_BOOK'),
	array(chance: 0.01, item: 'WOLF_SPAWN_EGG'),
)) {
	@inv = array();
	foreach(@weightedLoot in @loot){
		if(srand(@random) < @weightedLoot['chance'] + @bonus / 100 + @bonus * @floor * 0.01) {
			@item = array(name: @weightedLoot['item']);
			if(array_index_exists(@weightedLoot, 'qty') && is_array(@weightedLoot['qty'])) {
				@item['qty'] = integer(srand(@random) * (@weightedLoot['qty'][1] - @weightedLoot['qty'][0]) + @weightedLoot['qty'][0]);
			}
			if(array_index_exists(@weightedLoot, 'damage')) {
				@item['meta'] = array(damage: max(0, @weightedLoot['damage'] - 1 - integer(srand(@random) * @weightedLoot['damage'] * (@floor + @bonus) * 0.1)));
				if(@bonus > 1.0) {
					@rarity = array_get(array(color('yellow').'Uncommon ', color('aqua').'Rare ', color('light_purple').'Epic '), min(2, integer(@floor / 3)));
					@item['meta']['display'] = @rarity._to_upper_camel_case(@item['name']);
					@item['meta']['modifiers'] = array();
					@attributes = array('GENERIC_ARMOR_TOUGHNESS', 'GENERIC_ATTACK_DAMAGE', 'GENERIC_ATTACK_SPEED',
										'GENERIC_KNOCKBACK_RESISTANCE', 'GENERIC_MAX_HEALTH', 'GENERIC_MOVEMENT_SPEED');
					@operations = array('ADD_NUMBER', 'ADD_SCALAR');
					@slot = 'WEAPON';
					if(string_ends_with(@item['name'], 'LEGGINGS')) {
						@slot = 'LEGGINGS';
					} else if(string_ends_with(@item['name'], 'BOOTS')) {
						@slot = 'BOOTS';
					} else if(string_ends_with(@item['name'], 'HELMET')) {
						@slot = 'HELMET';
					} else if(string_ends_with(@item['name'], 'CHESTPLATE')) {
						@slot = 'CHESTPLATE';
					} else if(@item['name'] == 'SHIELD') {
						@slot = 'OFF_HAND';
					}
					if(@slot == 'WEAPON') {
						if(!string_ends_with(@item['name'], 'BOW')) {
							@item['meta']['modifiers'][] = array(
								attribute: 'GENERIC_ATTACK_DAMAGE',
								operation: 'ADD_NUMBER',
								amount: integer(srand(@random) * min(@floor + 1, 8)) + ceil(min(@floor + 1, 8) / 2),
								slot: @slot,
							);
							@item['meta']['modifiers'][] = array(
								attribute: 'GENERIC_ATTACK_SPEED',
								operation: 'ADD_NUMBER',
								amount: 0.5 + integer(srand(@random) * 2),
								slot: @slot,
							);
						}
					} else if(@slot != 'OFF_HAND') {
						@item['meta']['modifiers'][] = array(
							attribute: 'GENERIC_ARMOR',
							operation: 'ADD_NUMBER',
							amount: integer(srand(@random) * min(@floor + 1, 8)) + ceil(min(@floor + 1, 9) / 3),
							slot: @slot,
						);
					}
					@attribute = @attributes[integer(srand(@random) * array_size(@attributes))];
					@operation = @operations[integer(srand(@random) * array_size(@operations))];
					@amount = 0;
					if(@operation == 'ADD_NUMBER') {
						@amount = integer(srand(@random) * (@floor + 1)) + 1;
					} else if(@attribute == 'GENERIC_MOVEMENT_SPEED') {
						@amount = srand(@random) * (@floor + 1) * 0.05;
					} else {
						@amount = srand(@random) * (@floor + 1) * 0.1;
					}
					@item['meta']['modifiers'][] = array(
						attribute: @attribute,
						operation: @operation,
						amount: @amount,
						slot: @slot,
					);
				} else if(srand(@random) < 0.2) {
					if(srand(@random) < 0.5
					&& (string_ends_with(@item['name'], 'LEGGINGS') 
					|| string_ends_with(@item['name'], 'HELMET') 
					|| string_ends_with(@item['name'], 'BOOTS')
					|| string_ends_with(@item['name'], 'CHESTPLATE'))) {
						@item['meta']['enchants'] = array(curse_of_binding: 1);
					} else {
						@item['meta']['enchants'] = array(curse_of_vanishing: 1);
					}
				}
			} else if(@item['name'] == 'ENCHANTED_BOOK') {
				@enchants = array(
					'POWER', 'FLAME', 'INFINITY', 'PUNCH', 'SHARPNESS', 'BANE_OF_ARTHROPODS', 'SMITE',
					'UNBREAKING', 'FIRE_ASPECT', 'KNOCKBACK', 'LOOTING', 'RESPIRATION', 'PROTECTION',
					'BLAST_PROTECTION', 'FEATHER_FALLING', 'FIRE_PROTECTION', 'PROJECTILE_PROTECTION',
					'THORNS', 'DEPTH_STRIDER', 'MENDING', 'SWEEPING_EDGE', 'IMPALING', 'RIPTIDE', 'LOYALTY',
					'SWIFT_SNEAK', 'PIERCING', 'MULTISHOT', 'QUICK_CHARGE'
				);
				@meta = array(stored: associative_array());
				@id = integer(srand(@random) * array_size(@enchants));
				@enchant = @enchants[@id];
				@meta['stored'][@enchant] = array(elevel: 1);
				@item['meta'] = @meta;
			} else if(string_ends_with(@item['name'], 'POTION')) {
				@meta = associative_array();
				if(srand(@random) > 0.5) {
					@state = integer(srand(@random) * 3);
					@potionTypes = array('SPEED', 'SLOWNESS', 'STRENGTH', 'INSTANT_HEAL', 'INSTANT_DAMAGE', 'JUMP',
					'REGEN', 'FIRE_RESISTANCE', 'WATER_BREATHING', 'INVISIBILITY', 'NIGHT_VISION', 'WEAKNESS',
					'POISON', 'LUCK');
					@id = integer(srand(@random) * array_size(@potionTypes));
					@meta['base'] = array(
						extended: (@state == 1), 
						upgraded: (@state == 2), 
						type: @potionTypes[@id],
					);
				} else {
					@meta['potions'] = associative_array();
					@effects = reflect_pull('enum', 'PotionEffectType');
					do {
						@id = integer(srand(@random) * array_size(@effects));
						@effect = @effects[@id];
						@meta['potions'][@effect] = array(
							seconds: rand(1, 480),
							strength: rand(3)
						);
					} while(srand(@random) > 0.6);
					@meta['display'] = 'Mystery Potion';
					@meta['flags'] = array('HIDE_POTION_EFFECTS');
				}
				@item['meta'] = @meta;
			}
			@inv[] = @item;
		}
	}
	return(@inv);
}
