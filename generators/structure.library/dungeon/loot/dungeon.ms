proc _get_chest_loot(@floor, @random, @bonus = 1.0, @loot = array(
	array(chance: 0.3, item: 'TORCH', qty: array(1, 12)),
	array(chance: 0.1, item: 'ARROW', qty: array(1, 7)),
	array(chance: 0.05, item: 'GOLD_NUGGET', qty: array(1, 9)),
	array(chance: 0.05, item: 'GOLD_INGOT'),
	array(chance: 0.05, item: 'COBWEB'),
	array(chance: 0.04, item: 'IRON_NUGGET', qty: array(1, 9)),
	array(chance: 0.04, item: 'IRON_INGOT'),
	array(chance: 0.03, item: 'COAL'),
	array(chance: 0.03, item: 'BONE'),
	array(chance: 0.03, item: 'STICK'),
	array(chance: 0.03, item: 'LAPIS_LAZULI'),
	array(chance: 0.03, item: 'DIAMOND'),
	array(chance: 0.02, item: 'EMERALD', array(1, 9)),
	array(chance: 0.01, item: 'ENDER_PEARL'),
	array(chance: 0.01, item: 'ENCHANTED_BOOK'),
	array(chance: 0.01, item: 'WOLF_SPAWN_EGG'),
	array(chance: 0.01, item: 'BUNDLE'),
	array(chance: -0.06, item: 'TOTEM_OF_UNDYING'),
	array(chance: 0.08, item: 'WOODEN_SWORD'),
	array(chance: 0.06, item: 'STONE_SWORD'),
	array(chance: 0.04, item: 'GOLDEN_SWORD'),
	array(chance: 0.00, item: 'IRON_SWORD'),
	array(chance: -0.03, item: 'DIAMOND_SWORD'),
	array(chance: -0.06, item: 'NETHERITE_SWORD'),
	array(chance: 0.08, item: 'WOODEN_AXE'),
	array(chance: 0.06, item: 'STONE_AXE'),
	array(chance: 0.00, item: 'IRON_AXE'),
	array(chance: -0.03, item: 'DIAMOND_AXE'),
	array(chance: -0.06, item: 'NETHERITE_AXE'),
	array(chance: -0.03, item: 'TRIDENT'),
	array(chance: -0.03, item: 'MACE'),
	array(chance: 0.01, item: 'SHIELD'),
	array(chance: 0.03, item: 'BOW'),
	array(chance: 0.03, item: 'CROSSBOW'),
	array(chance: 0.08, item: 'LEATHER_HELMET'),
	array(chance: 0.08, item: 'LEATHER_CHESTPLATE'),
	array(chance: 0.08, item: 'LEATHER_LEGGINGS'),
	array(chance: 0.08, item: 'LEATHER_BOOTS'),
	array(chance: 0.04, item: 'GOLDEN_HELMET'),
	array(chance: 0.04, item: 'GOLDEN_CHESTPLATE'),
	array(chance: 0.04, item: 'GOLDEN_LEGGINGS'),
	array(chance: 0.04, item: 'GOLDEN_BOOTS'),
	array(chance: 0.01, item: 'CHAINMAIL_HELMET'),
	array(chance: 0.01, item: 'CHAINMAIL_CHESTPLATE'),
	array(chance: 0.01, item: 'CHAINMAIL_LEGGINGS'),
	array(chance: 0.01, item: 'CHAINMAIL_BOOTS'),
	array(chance: -0.02, item: 'IRON_HELMET'),
	array(chance: -0.02, item: 'IRON_CHESTPLATE'),
	array(chance: -0.02, item: 'IRON_LEGGINGS'),
	array(chance: -0.02, item: 'IRON_BOOTS'),
	array(chance: -0.04, item: 'TURTLE_HELMET'),
	array(chance: -0.05, item: 'DIAMOND_HELMET'),
	array(chance: -0.05, item: 'DIAMOND_CHESTPLATE'),
	array(chance: -0.05, item: 'DIAMOND_LEGGINGS'),
	array(chance: -0.05, item: 'DIAMOND_BOOTS'),
	array(chance: -0.06, item: 'NETHERITE_HELMET'),
	array(chance: -0.06, item: 'NETHERITE_CHESTPLATE'),
	array(chance: -0.06, item: 'NETHERITE_LEGGINGS'),
	array(chance: -0.06, item: 'NETHERITE_BOOTS'),
)) {
	@inv = associative_array();
	@count = integer(@bonus + srand(@random) * @bonus * 8);
	while(@count > 0) {
		@weightedLoot = _array_get_srand(@random, @loot);
		@calculatedChance = @weightedLoot['chance'] + @bonus * @floor * 0.01;
		@maxDurability = material_info(@weightedLoot['item'], 'maxDurability');
		if(srand(@random) < @calculatedChance && (@maxDurability == 0 || @weightedLoot['chance'] + @floor * 0.01 < 0.09)) {
			@item = array(name: @weightedLoot['item']);
			if(array_index_exists(@weightedLoot, 'qty') && is_array(@weightedLoot['qty'])) {
				@item['qty'] = integer(srand(@random) * @bonus * (@weightedLoot['qty'][1] - @weightedLoot['qty'][0]) + @weightedLoot['qty'][0]);
			}
			if(@maxDurability > 0) {
				@item['meta'] = array(damage: max(0, integer(srand(@random) * @maxDurability)));
				if(@bonus > 1.0) {
					@rarityIndex = min(2, integer(@floor / 3));
					@rarity = array_get(array(
						color('yellow').'Uncommon ',
						color('aqua').'Rare ', 
						color('light_purple').'Epic '
					), @rarityIndex);
					@item['meta']['display'] = @rarity._to_upper_camel_case(@item['name']);
					@item['meta']['modifiers'] = array();
					@slot = 'WEAPON';
					if(string_ends_with(@item['name'], 'LEGGINGS')) {
						@slot = 'LEGGINGS';
					} else if(string_ends_with(@item['name'], 'BOOTS')) {
						@slot = 'BOOTS';
					} else if(string_ends_with(@item['name'], 'HELMET')) {
						@slot = 'HELMET';
					} else if(string_ends_with(@item['name'], 'CHESTPLATE')) {
						@slot = 'CHESTPLATE';
					} else if(@item['name'] === 'SHIELD') {
						@slot = 'OFF_HAND';
					}
					if(string_starts_with(@item['name'], 'CHAINMAIL')) {
						@item['meta']['modifiers'][] = array(
							attribute: 'GENERIC_ATTACK_SPEED',
							operation: 'ADD_NUMBER',
							amount: 0.5,
							slot: @slot,
						);
						@item['meta']['modifiers'][] = array(
							attribute: 'GENERIC_MOVEMENT_SPEED',
							operation: 'ADD_NUMBER',
							amount: 0.05,
							slot: @slot,
						);
					} else if(string_starts_with(@item['name'], 'GOLDEN') 
					|| string_starts_with(@item['name'], 'IRON') 
					|| string_starts_with(@item['name'], 'DIAMOND')
					|| string_starts_with(@item['name'], 'NETHERITE')) {
						if(string_starts_with(@item['name'], 'GOLDEN')) {
							@rarityIndex++;
						} else if(string_starts_with(@item['name'], 'DIAMOND') || string_starts_with(@item['name'], 'NETHERITE')) {
							@rarityIndex--;
						}
						if(@slot === 'WEAPON') {
							@weaponEnchants = array(
								'SHARPNESS', 'BANE_OF_ARTHROPODS', 'SMITE', 'UNBREAKING', 'FIRE_ASPECT', 'KNOCKBACK', 'LOOTING', 'MENDING'
							);
							if(string_ends_with(@item['name'], 'SWORD')) {
								@weaponEnchants[] = 'SWEEPING_EDGE';
							}
							@item['meta']['enchants'] = associative_array();
							while(@rarityIndex-- >= 0) {
								@enchant = _array_get_srand(@random, @weaponEnchants);
								if(array_index_exists(@item['meta']['enchants'], @enchant)) {
									@item['meta']['enchants'][@enchant]++;
								} else {
									@item['meta']['enchants'][@enchant] = 1;
								}
							}
						} else if(@slot != 'OFF_HAND') {
							@armorEnchants = array(
								'UNBREAKING', 'PROTECTION', 'BLAST_PROTECTION', 'FIRE_PROTECTION', 'PROJECTILE_PROTECTION', 'THORNS', 'MENDING'
							);
							if(@slot === 'HELMET') {
								@armorEnchants[] = 'RESPIRATION';
							} else if(@slot === 'LEGGINGS') {
								@armorEnchants[] = 'SWIFT_SNEAK';
							} else if(@slot === 'BOOTS') {
								@armorEnchants[] = 'DEPTH_STRIDER';
							}
							@item['meta']['enchants'] = associative_array();
							while(@rarityIndex-- >= 0) {
								@enchant = _array_get_srand(@random, @armorEnchants);
								if(array_index_exists(@item['meta']['enchants'], @enchant)) {
									@item['meta']['enchants'][@enchant]++;
								} else {
									@item['meta']['enchants'][@enchant] = 1;
								}
							}
						}
					} else if(@item['name'] === 'CROSSBOW') {
						if(srand(@random) < 0.5) {
							@item['meta'] = array(projectiles: array(array(name: 'FIREWORK_ROCKET', meta: array(firework: array(
								strength: 1, 
								effects: array(array(type: 'LARGE_BALL'), array(type: 'LARGE_BALL'), array(type: 'LARGE_BALL'),
										array(type: 'LARGE_BALL'), array(type: 'LARGE_BALL'), array(type: 'LARGE_BALL'))
							)))));
						} else {
							@crossbowEnchants = array(
								'PIERCING', 'MULTISHOT', 'QUICK_CHARGE', 'UNBREAKING', 'MENDING'
							);
							@item['meta']['enchants'] = associative_array();
							while(@rarityIndex-- >= 0) {
								@enchant = _array_get_srand(@random, @crossbowEnchants);
								if(array_index_exists(@item['meta']['enchants'], @enchant)) {
									@item['meta']['enchants'][@enchant]++;
								} else {
									@item['meta']['enchants'][@enchant] = 1;
								}
							}
						}
					} else if(@item['name'] === 'BOW') {
						@bowEnchants = array(
							'POWER', 'FLAME', 'INFINITY', 'PUNCH', 'UNBREAKING', 'MENDING'
						);
						@item['meta']['enchants'] = associative_array();
						while(@rarityIndex-- >= 0) {
							@enchant = _array_get_srand(@random, @bowEnchants);
							if(array_index_exists(@item['meta']['enchants'], @enchant)) {
								@item['meta']['enchants'][@enchant]++;
							} else {
								@item['meta']['enchants'][@enchant] = 1;
							}
						}
					} else if(@item['name'] === 'TRIDENT') {
						@tridentEnchants = array(
							'IMPALING', 'RIPTIDE', 'LOYALTY', 'UNBREAKING', 'MENDING'
						);
						@item['meta']['enchants'] = associative_array();
						while(@rarityIndex-- >= 0) {
							@enchant = _array_get_srand(@random, @tridentEnchants);
							if(array_index_exists(@item['meta']['enchants'], @enchant)) {
								@item['meta']['enchants'][@enchant]++;
							} else {
								@item['meta']['enchants'][@enchant] = 1;
							}
						}
					}
				}
				if(srand(@random) < 0.5) {
					if(!array_index_exists(@item['meta'], 'enchants')) {
						@item['meta']['enchants'] = associative_array();
					}
					if(srand(@random) < 0.5
					&& (string_ends_with(@item['name'], 'LEGGINGS') 
					|| string_ends_with(@item['name'], 'HELMET') 
					|| string_ends_with(@item['name'], 'BOOTS')
					|| string_ends_with(@item['name'], 'CHESTPLATE'))) {
						@item['meta']['enchants']['binding_curse'] = 1;
					} else {
						@item['meta']['enchants']['vanishing_curse'] = 1;
					}
				}
			} else if(@item['name'] === 'ENCHANTED_BOOK') {
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
			} else if(@item['name'] === 'BUNDLE') {
				@item['meta'] = array(items: if(srand(@random) > 0.5, _get_chest_loot(@floor, @random), _get_barrel_loot(@floor, @random)));
			}
			@inv[integer(srand(@random) * 27)] = @item;
			@count--;
		}
	}
	return(@inv);
}

proc _get_barrel_loot(@floor, @random, @bonus = 1.0, @loot = array(
	array(chance: 0.20, item: 'GOLDEN_APPLE'),
	array(chance: 0.08, item: 'APPLE', qty: array(1, 9)),
	array(chance: 0.08, item: 'POTATO', qty: array(1, 9)),
	array(chance: 0.08, item: 'POISONOUS_POTATO', qty: array(1, 9)),
	array(chance: 0.04, item: 'BREAD', qty: array(1, 9)),
	array(chance: 0.04, item: 'SPLASH_POTION'),
	array(chance: 0.04, item: 'POTION'),
	array(chance: 0.04, item: 'MILK_BUCKET'),
	array(chance: 0.03, item: 'ROTTEN_FLESH'),
	array(chance: 0.03, item: 'GLASS_BOTTLE'),
	array(chance: 0.02, item: 'PORKCHOP', qty: array(1, 9)),
	array(chance: 0.00, item: 'GOLDEN_CARROT', qty: array(1, 9)),
)) {
	@inv = associative_array();
	@count = integer(@bonus + srand(@random) * @bonus * 3);
	while(@count > 0) {
		@weightedLoot = _array_get_srand(@random, @loot);
		@calculatedChance = @weightedLoot['chance'] + @bonus * @floor * 0.01;
		if(srand(@random) < @calculatedChance) {
			@item = array(name: @weightedLoot['item']);
			if(array_index_exists(@weightedLoot, 'qty') && is_array(@weightedLoot['qty'])) {
				@item['qty'] = integer(srand(@random) * @bonus * (@weightedLoot['qty'][1] - @weightedLoot['qty'][0]) + @weightedLoot['qty'][0]);
			}
			if(string_ends_with(@item['name'], 'POTION')) {
				@meta = associative_array();
				if(srand(@random) > 0.5) {
					@potionTypes = array(
						'SPEED': 3,
						'STRENGTH': 3,
						'INSTANT_HEAL': 2,
						'INSTANT_DAMAGE': 2,
						'JUMP': 3,
						'REGEN': 3,
						'FIRE_RESISTANCE': 2,
						'WATER_BREATHING': 2,
						'INVISIBILITY': 2,
						'NIGHT_VISION': 2,
						'LUCK': 1
					);
					if(@item['name'] === 'SPLASH_POTION') {
						@potionTypes = array_merge(@potionTypes, array(
							'SLOWNESS': 3,
							'WEAKNESS': 2,
							'POISON': 3,
						));
					}
					@id = _array_get_srand(@random, array_keys(@potionTypes));
					@state = integer(srand(@random) * @potionTypes[@id]);
					if(@state == 1 && string_starts_with(@id, 'INSTANT')) {
						@state = 2;
					}
					@meta['base'] = array(
						extended: (@state == 1), 
						upgraded: (@state == 2), 
						type: @id,
					);
				} else {
					@meta['potions'] = associative_array();
					@effects = reflect_pull('enum', 'PotionEffectType');
					do {
						@id = integer(srand(@random) * array_size(@effects));
						@effect = @effects[@id];
						@meta['potions'][@effect] = array(
							seconds: srand(@random) * 480,
							strength: integer(srand(@random) * 3)
						);
					} while(srand(@random) > 0.6)
					@meta['display'] = 'Suspicious Potion';
					@meta['flags'] = array('HIDE_POTION_EFFECTS');
				}
				@item['meta'] = @meta;
			}
			@inv[integer(srand(@random) * 27)] = @item;
			@count--;
		}
	}
	return(@inv);
}