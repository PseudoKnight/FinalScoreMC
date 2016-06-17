proc _pgive_item(@item, @amount) {
    @item = split(':', @item);
	if(!is_numeric(@item[0])) {
        @item[0] = data_values(@item[0]);
    }
	if(is_null(@item[0])) {
        die('Unknown item name');
    }
	if(array_size(@item) == 1) {
        @item[1] = 0;
    }
	if(!is_integral(@amount) || @amount < 1) {
        die('Amount must be a positive integer.');
    }
	try {
		pgive_item(@item[0].':'.@item[1], @amount);
		msg(color('yellow').'You\'ve been given '.@amount.' '.data_name(@item[0].':'.@item[1]).'.');
	} catch(Exception @ex) {
		msg(color('red').'The item '.@item.' doesn\'t appear to exist.');
	}
}

proc _enchant_item(@type, @level) {
    # enchantment aliases
    @enchants = associative_array(
        'power': 'ARROW_DAMAGE',
        'flame': 'ARROW_FIRE',
        'infinity': 'ARROW_INFINITE',
        'punch': 'ARROW_KNOCKBACK',
        'sharpness': 'DAMAGE_ALL',
        'baneofarthropods': 'DAMAGE_ARTHROPODS',
        'smite': 'DAMAGE_UNDEAD',
        'efficiency': 'DIG_SPEED',
        'unbreaking': 'DURABILITY',
        'fireaspect': 'FIRE_ASPECT',
        'knockback': 'KNOCKBACK',
        'fortune': 'LOOT_BONUS_BLOCKS',
        'looting': 'LOOT_BONUS_MOBS',
        'respiration': 'OXYGEN',
        'protection': 'PROTECTION_ENVIRONMENTAL',
        'blastprotection': 'PROTECTION_EXPLOSIONS',
        'featherfalling': 'PROTECTION_FALL',
        'fireprotection': 'PROTECTION_FIRE',
        'projectileprotection': 'PROTECTION_PROJECTILE',
        'silktouch': 'SILK_TOUCH',
        'thorns': 'THORNS',
        'aquaaffinity': 'WATER_WORKER',
        'depthstrider': 'DEPTH_STRIDER',
    );
    if(!is_integral(@level)) {
        die('Enchantment level must be an integer.');
    }
    if(array_index_exists(@enchants, to_lower(@type))) {
        enchant_inv_unsafe(null, @enchants[to_lower(@type)], @level);
    } else {
        msg(color('red').'Available enchantments: '.array_keys(@enchants));
    }
}

proc _pset_potion(@type, @id, @seconds, @strength){
    @type = to_upper(@type);
    if(@type != 'POTION' && @type != 'SPLASH_POTION' && @type != 'LINGERING_POTION') {
        die(color('gold').'First argument must be a potion type: potion, splash_potion, or lingering_potion.');
    }

    @effects = _get_effects();
	if(!is_numeric(@id)) {
		if(!array_index_exists(@effects, @id)) {
			die('Available potion effects: '.@effects);
		}
		@id = @effects[@id];
	}

	@item = pinv(player(), null);
	if(@item && @item['name'] == @type) { # add potion effecs to potion
		if(is_null(@item['meta'])) {
			@item['meta'] = associative_array();
		}
		if(!array_index_exists(@item['meta'], 'potions')) {
			@item['meta']['potions'] = array();
		}
		@item['meta']['potions'][] = associative_array('id': @id, 'strength': @strength - 1, 'seconds': @seconds);
		set_pinv(array(null: @item));

	} else { # create new potion
        @extended = @seconds;
        @upgraded = @strength;
        @item = associative_array('name': @type, 'meta': associative_array());
        @potionTypes = array(
            '',
            'SPEED',
            'SLOWNESS',
            '',
            '',
            'STRENGTH',
            'INSTANT_HEAL',
            'INSTANT_DAMAGE',
            'JUMP',
            '',
            'REGEN',
            '',
            'FIRE_RESISTANCE',
            'WATER_BREATHING',
            'INVISIBILITY',
            '',
            'NIGHT_VISION',
            '',
            'WEAKNESS',
            'POISON',
            '',
            '',
            '',
            '',
            '',
            '',
            'LUCK',
            ''
        );
        if(@potionTypes[@id]) {
            @item['meta']['base'] = associative_array(
                'type': @potionTypes[@id],
            );
            // verify valid regular potion
            if((@extended == 'true' || @extended == 'false')
            && (@upgraded == 'true' || @upgraded == 'false')) {
                @item['meta']['base']['extended'] = (@extended == 'true');
                @item['meta']['base']['upgraded'] = (@upgraded == 'true');
            }
            try {
                set_pinv(array(null: @item));
                return();
            } catch(FormatException @ex) {
                // fall back to custom potions
                array_remove(@item['meta']['base'], 'extended');
                array_remove(@item['meta']['base'], 'upgraded');
            }
        }
        @item['meta']['potions'] = array(array('id': @id, 'strength': @strength - 1, 'seconds': @seconds));
        set_pinv(array(null: @item));
	}
}

proc _popen_skullmenu(){
    if(extension_exists('CHVirtualChests')) {
    	if(!array_contains(all_virtualchests(), 'skulls')) {
    		@skulls = array(
    			'id': 'skulls',
    			'title': 'Choose a Skull',
    			'size': 45,
    			0: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Burger',
    					'owner': 'glorycraft'
    				),
    			),
    			1: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Globe',
    					'owner': 'Mapparere'
    				),
    			),
    			2: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'TV',
    					'owner': 'uioz'
    				),
    			),
    			3: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Cake',
    					'owner': 'MHF_Cake'
    				),
    			),
    			4: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Exclamation Box',
    					'owner': 'MHF_Exclamation'
    				),
    			),
    			5: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Question Box',
    					'owner': 'MHF_Question'
    				),
    			),
    			6: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Chest',
    					'owner': 'MHF_Chest'
    				),
    			),
    			7: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Jukebox',
    					'owner': 'C418'
    				),
    			),
    			8: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Old Fashioned Camera',
    					'owner': '3i5g00d'
    				),
    			),
    			9: array(
    				'type': 397, 'data': 3,	'meta': array(
    					'display': 'Jack O\' Lantern',
    					'owner': 'Koebasti'
    				),
    			),
    			10: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Cactus',
    					'owner': 'LaxPride'
    				),
    			),
    			11: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Leaves',
    					'owner': 'rsfx'
    				),
    			),
    			12: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Fish181',
    					'owner': 'Aquarium'
    				),
    			),
    			13: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Clock',
    					'owner': 'Olaf_C'
    				),
    			),
    			14: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Stone',
    					'owner': 'robbydeezle'
    				),
    			),
    			15: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'TNT',
    					'owner': 'HCTNT'
    				),
    			),
    			16: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Dispenser',
    					'owner': 'scemm'
    				),
    			),
    			17: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Piston',
    					'owner': 'JL2579'
    				),
    			),
    			18: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Diamond Ore',
    					'owner': 'akaBruce'
    				),
    			),
    			19: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Redstone Ore',
    					'owner': 'annayirb'
    				),
    			),
    			20: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Emerald Ore',
    					'owner': 'Tereneckla'
    				),
    			),
    			21: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Sponge',
    					'owner': 'pomi44'
    				),
    			),
    			22: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Haybale',
    					'owner': 'Bendablob'
    				),
    			),
    			23: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Camera',
    					'owner': 'jorgenskar95'
    				),
    			),
    			24: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Computer',
    					'owner': 'Addelburgh'
    				),
    			),
    			25: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Gold Block',
    					'owner': 'teachdaire'
    				),
    			),
    			26: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Iron Block',
    					'owner': 'metalhedd'
    				),
    			),
    			27: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Obsidian',
    					'owner': 'loiwiol'
    				),
    			),
    			28: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Books',
    					'owner': 'CS001'
    				),
    			),
    			29: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Sand',
    					'owner': 'rugofluk'
    				),
    			),
    			30: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Toilet Paper Roll',
    					'owner': 'OrtyBortorty'
    				),
    			),
    			31: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Popcorn',
    					'owner': 'ZachWarnerHD'
    				),
    			),
    			32: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Cupcake',
    					'owner': 'ChoclateMuffin'
    				),
    			),
    			33: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Hamburger',
    					'owner': 'food'
    				),
    			),
    			34: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Netherrack',
    					'owner': 'Numba_one_Stunna'
    				),
    			),
    			35: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Computer',
    					'owner': 'CoderPuppy'
    				),
    			),
    			36: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'TV',
    					'owner': 'sysfailure'
    				),
    			),
    			37: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Ender Eye',
    					'owner': 'Edna_I'
    				),
    			),
    			38: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Apple',
    					'owner': 'KylexDavis'
    				),
    			),
    			39: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Toaster',
    					'owner': 'zEl3M3nTz'
    				),
    			),
    			40: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Green Gift',
    					'owner': 'SeerPotion'
    				),
    			),
    			41: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Red Gift',
    					'owner': 'CruXXx'
    				),
    			),
    			42: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Dice',
    					'owner': 'SquareHD'
    				),
    			),
    			43: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Snowman',
    					'owner': 'Snowman_7'
    				),
    			),
    			44: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'Chimney Top',
    					'owner': 'The_Wither_Boss'
    				),
    			),
    			45: array(
    				'type': 397, 'data': 3, 'meta': array(
    					'display': 'GameCube',
    					'owner': 'Eien15'
    				),
    			),
    		);
    		create_virtualchest(@skulls);
    	}
    	popen_virtualchest('skulls');
    	msg('Please do not rely too heavily upon these, as many are subject to change.');
    	if(!has_bind(player().'-skulls-click')) {
    		bind('inventory_click', array('id': player().'-skulls-click'), array('slottype': 'CONTAINER', 'player': player()), @e) {
    			if(pget_virtualchest() === 'skulls' && pmode() === 'CREATIVE') {
    				if(@e['slotitem']) {
    					pgive_item(player(), '397:3', 1, @e['slotitem']['meta']);
    				}
    			}
    		}
    		bind('inventory_close', null, array('player': player()), @e) {
    			unbind(player().'-skulls-click');
    			unbind();
    		}
    	}
    }
}
