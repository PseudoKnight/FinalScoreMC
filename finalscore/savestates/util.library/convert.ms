proc _inv_convert($player){
	if($player) {
		@endpoint = '';
		if(!$world) {
			@endpoint = 'groups/default/'.$player.'.yml';
		} else {
			@endpoint = 'worlds/'.$world.'/'.$player.'.yml';
		}
		@original = yml_decode(read('../../../../Multiverse-Inventories/'.@endpoint))['SURVIVAL'];
		try {
			@inv = array();
			if(array_index_exists(@original, 'inventoryContents')) {
				@inv = _json_to_array(json_decode(@original['inventoryContents']));
			}
			if(array_index_exists(@original, 'armorContents')) {
				@armor = _json_to_array(json_decode(@original['armorContents']));
				foreach(@key: @value in @armor) {
					@inv[@key + 36] = @value
				}
			}
			deserialize_pinv(yml_encode(@inv));
			@inv = array();
			if(array_index_exists(@original, 'enderChestContents')) {
				@inv = _json_to_array(json_decode(@original['enderChestContents']));
				deserialize_penderchest(yml_encode(@inv));
			}
		} catch(Exception @json) {
			try {
				@inv = array();

				if(array_index_exists(@original, 'inventoryContents')) {
					@inv = _custom_to_array(@original['inventoryContents']);
				}
				if(array_index_exists(@original, 'armorContents') && @original['armorContents']) {
					@armor = _custom_to_array(@original['armorContents']);
					foreach(@key: @value in @armor) {
						@inv[@key + 36] = @value
					}
				}
				deserialize_pinv(yml_encode(@inv));
				@inv = array();
				if(array_index_exists(@original, 'enderChestContents')) {
					@inv = _custom_to_array(@original['enderChestContents']);
					deserialize_penderchest(yml_encode(@inv));
				}
			} catch(Exception @custom) {
				msg('Failed to process '.$player);
				msg(@json['message']);
				msg(@json['stackTrace']);
				msg(@custom['message']);
				msg(@custom['stackTrace']);
			}
		}
	} else {
		@processed = 0;
		@total = 0;
		foreach(@key: @pdata in get_values('uuids')) {

			if(!array_index_exists(@pdata, 'name')) {
				# possibly whitelisted, but not joined, skip
				continue();
			}
			@original = '';
			@name = @pdata['name'];
			@endpoint = 'groups/default/'.@pdata['name'].'.yml';
			try {
				@original = yml_decode(read('../../../../Multiverse-Inventories/'.@endpoint))['SURVIVAL'];
			} catch(Exception @e) {
				# no valid data... check for files with aliases
				if(array_index_exists(@pdata, 'names')) {
					foreach(@name in @pdata['names']) {
						@endpoint = 'groups/default/'.@name.'.yml';
						try {
							@original = yml_decode(read('../../../../Multiverse-Inventories/'.@endpoint))['SURVIVAL'];
							# found one, but keep looking for the latest
						} catch(Exception @e) {
							continue();
						}
					}
					if(!is_array(@original)) {
						# no files for aliases found
						continue();
					}
				} else {
					# no aliases to work with, skip
					continue();
				}
			}
			@total++;
			@world = '';
			try {
				@world = yml_decode(read('../../../../Multiverse-Inventories/players/'.@name.'.yml'))['playerData']['lastWorld'];
				if(_is_survival_world(@world)) {
					continue();
				}
			} catch(IOException @ex) {
				# no world
			}
			@pinv = associative_array();
			@ender = associative_array();
			@stats = associative_array();
			@effects = associative_array();
			@bed = array();
			try {
				if(array_index_exists(@original, 'inventoryContents')) {
					@pinv = _json_to_array(json_decode(@original['inventoryContents']));
				}
				if(array_index_exists(@original, 'armorContents')) {
					@armor = _json_to_array(json_decode(@original['armorContents']));
					foreach(@k: @value in @armor) {
						@pinv[@k + 36] = @value
					}
				}

				if(array_index_exists(@original, 'enderChestContents')) {
					@ender = _json_to_array(json_decode(@original['enderChestContents']));
				}

				if(array_index_exists(@original, 'stats') && length(@original['stats']) > 4) {
					@stats = _parse_json_stats(json_decode(@original['stats']));
				}

				if(array_index_exists(@original, 'potions') && length(@original['potions']) > 4) {
					@effects = _parse_json_potions(json_decode(@original['potions']));
				}

				if(array_index_exists(@original, 'bedSpawnLocation') && length(@original['bedSpawnLocation']) > 4) {
					@bed = _parse_json_bed(json_decode(@original['bedSpawnLocation']));
				}

			} catch(Exception @json) {
				try {
					if(array_index_exists(@original, 'inventoryContents')) {
						@pinv = _custom_to_array(@original['inventoryContents']);
					}
					if(array_index_exists(@original, 'armorContents') && @original['armorContents']) {
						@armor = _custom_to_array(@original['armorContents']);
						foreach(@k: @value in @armor) {
							@pinv[@k + 36] = @value
						}
					}

					if(array_index_exists(@original, 'enderChestContents')) {
						@ender = _custom_to_array(@original['enderChestContents']);
					}

					if(array_index_exists(@original, 'stats') && length(@original['stats']) > 4) {
						@stats = _parse_custom_stats(@original['stats']);
					}

					if(array_index_exists(@original, 'potions') && length(@original['potions']) > 4) {
						@effects = _parse_custom_potions(@original['potions']);
					}

					if(array_index_exists(@original, 'bedSpawnLocation') && length(@original['bedSpawnLocation']) > 4) {
						@bed = _parse_custom_bed(@original['bedSpawnLocation']);
					}

				} catch(Exception @custom) {
					msg('Failed to process '.@pdata['name']);
					msg(@json['message']);
					msg(@json['stackTrace']);
					msg(@custom['message']);
					msg(@custom['stackTrace']);
					continue();
				}
			}

			@pdata['survival'] = @stats;
			if(@pinv) {
				@pdata['survival']['inv'] = yml_encode(@pinv);
				@processed++;
			}
			if(@ender) {
				@pdata['survival']['ender'] = yml_encode(@ender);
			}
			if(@effects) {
				@pdata['survival']['effects'] = @effects;
			}
			if(@bed) {
				@pdata['survival']['bed'] = @bed;
			}
			if(@world) {
				@pdata['world'] = @world;
			}
			/*
			if(array_index_exists(@pdata, 'lastloc')) {
				if(array_index_exists(@pdata['lastloc'], 'survival')) {
					@pdata['survival']['loc'] = @pdata['lastloc']['survival'];
				}
				if(array_index_exists(@pdata['lastloc'], 'custom')) {
					@pdata['adventure']['loc'] = @pdata['lastloc']['custom'];
				}
				if(array_index_exists(@pdata['lastloc'], 'dev')) {
					@pdata['creative']['loc'] = @pdata['lastloc']['dev'];
				}
				array_remove(@pdata, 'lastloc');
			}
			*/
			store_value(@key, @pdata);
			action_msg(@pdata['name']);
		}
		msg('Found and converted '.@processed.' inventories of '.@total.'!');
	}
}

proc _json_to_array(@oinv) {
	@inv = associative_array();
	if(!is_array(@oinv)) {
		throw('CastException', 'Not JSON, moving on...');
	}
	foreach(@index: @item in @oinv) {
		if(array_index_exists(@item, 'is')) {
			@inv[@index] = @item['is'];
			@inv[@index]['=='] = 'org.bukkit.inventory.ItemStack';
			if(array_index_exists(@item['is'], 'meta')) {
				@inv[@index]['meta']['=='] = 'ItemMeta';
				if(array_index_exists(@item['is']['meta'], 'patterns')) {
					array_remove(@inv[@index]['meta'], 'patterns');
				}
				if(array_index_exists(@item['is']['meta'], 'color')) {
					array_remove(@inv[@index]['meta'], 'color');
				}
			}
			if(@item['is']['type'] == 'POTION' && array_index_exists(@item['is'], 'damage')) {
				@potion = _convert_potion(@item['is']['damage'], true);
				@inv[@index]['type'] = @potion[0];
				@inv[@index]['meta'] = associative_array(
					'==': 'ItemMeta',
					'meta-type': 'POTION',
					'potion-type': @potion[1],
				);
				array_remove(@inv[@index], 'damage');
			} else if(@item['is']['type'] == 'MONSTER_EGG' && array_index_exists(@item['is'], 'damage')) {
				@inv[@index] = _convert_monster_egg(@item['is']['damage']);
				if(array_index_exists(@item['is'], 'amount')) {
					@inv[@index]['amount'] = @item['is']['amount'];
				}
			}
		} else {
			@inv[@index] = associative_array(
				'==': 'org.bukkit.inventory.ItemStack';
			);
			foreach(@m: @v in @item) {
				switch(@m) {
					case 't':
						set_pinv(array(0: array('type': @v)));
						@inv[@index]['type'] = pinv(player(), 0)['name'];
					case 'd':
						@inv[@index]['damage'] = integer(@v);
					case '#':
						@inv[@index]['amount'] = integer(@v);
					case 'e':
						@inv[@index]['meta'] = associative_array(
							'==': 'ItemMeta',
							'meta-type': 'UNSPECIFIC',
							'enchants': @v,
						);
					case 'n':
						# ignore
						break();
					default:
						msg('Warning: unhandled custom json data: '.@m);
				}
			}
		}
	}
	return(@inv);
}

proc _json_to_inv(@oinv, @armor) {
	@inv = array();
	if(@armor) {
		@inv[99] = null;
	}
	if(!is_array(@oinv)) {
		throw('CastException', 'Not JSON, moving on...');
	}
	foreach(@item in @oinv) {
		@i = associative_array();
		if(array_index_exists(@item, 'is')) {
			@i['name'] = @item['is']['type'];
			if(array_index_exists(@item['is'], 'amount')) {
				@i['qty'] = @item['is']['amount'];
			}
			if(array_index_exists(@item['is'], 'damage')) {
				@i['data'] = @item['is']['damage'];
			}
			if(array_index_exists(@item['is'], 'meta')) {
				@i['meta'] = associative_array();
				foreach(@m: @v in @item['is']['meta']) {
					switch(@m) {
						case 'enchants':
							@i['meta']['enchants'] = array();
							foreach(@enchant: @level in @v) {
								@i['meta']['enchants'][] = array('etype': @enchant, 'elevel': @level);
							}

						case 'stored-enchants':
							@i['meta']['stored'] = array();
							foreach(@enchant: @level in @v) {
								@i['meta']['stored'][] = array('etype': @enchant, 'elevel': @level);
							}

						case 'repair-cost':
							@i['meta']['repair'] = @v;

						case 'skull-owner':
							@i['meta']['owner'] = @v;

						case 'display-name':
							@i['meta']['display'] = @v;

						case 'base-color':
							@i['meta']['basecolor'] = @v;

						case 'title':
						case 'author':
						case 'pages':
							@i['meta'][@m] = @v;

						case 'color':
						case 'generation':
						case 'internal':
						case 'meta-type':
						case 'patterns':
						case 'scaling':
							# ignore
							break();

						default:
							throw(NotFoundException, 'Warning: unhandled json meta: '.@m);

					}
				}
			}
		} else {
			foreach(@m: @v in @item) {
				switch(@m) {
					case 't':
						@i['type'] = integer(@v);
					case 'd':
						@i['data'] = integer(@v);
					case '#':
						@i['qty'] = integer(@v);
					case 'e':
						@i['enchants'] = array();
						foreach(@enchant: @level in @v) {
							@i['enchants'][] = associative_array('elevel': @level, 'etype': @enchant);
						}
					case 'n':
						# ignore
						break();
					default:
						msg('Warning: unhandled custom json data: '.@m);
				}
			}
		}
		@inv[] = @i;
	}
	return(@inv);
}

proc _custom_to_array(@oinv, @armor) {
	@inv = associative_array();
	foreach(@item in split('/', @oinv)) {
		@index = split(':', @item, 1)[0]
		@item = split(':', @item, 1)[1];

		@i = associative_array();
		@i['=='] = 'org.bukkit.inventory.ItemStack';

		foreach(@tag in split(';', @item)) {
			@data = split(':', @tag, 1);
			switch(@data[0]) {
				case 't':
					set_pinv(array(0: array('type': @data[1])));
					@i['type'] = pinv(player(), 0)['name'];
				case 'd':
					@i['damage'] = integer(@data[1]);
				case '#':
					@i['amount'] = integer(@data[1]);
				case 'e':
					@i['meta'] = associative_array(
						'==': 'ItemMeta',
						'meta-type': 'UNSPECIFIC',
						'enchants': associative_array(),
					);
					foreach(@enchant in split(',', @data[1])) {
						@enchant = split(':', @enchant);
						@i['meta']['enchants'][@enchant[0]] = @enchant[1];
					}
				case 'n':
					# ignore
					break();
				default:
					msg('Warning: unhandled custom data: '.@data[0]);
			}
		}

		@inv[@index] = @i;
	}
	return(@inv);
}

proc _custom_to_inv(@oinv, @armor) {
	@inv = array();
	if(@armor) {
		@inv[99] = null;
	}
	foreach(@item in split('/', @oinv)) {
		@item = split(':', @item, 1)[1];

		@i = associative_array();
		@i['qty'] = 1;
		@i['data'] = 0;

		foreach(@tag in split(';', @item)) {
			@data = split(':', @tag, 1);
			switch(@data[0]) {
				case 't':
					@i['type'] = integer(@data[1]);
				case 'd':
					@i['data'] = integer(@data[1]);
				case '#':
					@i['qty'] = integer(@data[1]);
				case 'e':
					@i['enchants'] = array();
					foreach(@enchant in split(',', @data[1])) {
						@enchant = split(':', @enchant);
						@i['enchants'][] = associative_array(
							'etype': @enchant[0],
							'elevel': integer(@enchant[1]),
						);
					}
				case 'n':
					# ignore
					break();
				default:
					msg('Warning: unhandled custom data: '.@data[0]);
			}
		}

		@inv[] = @i;
	}
	return(@inv);
}

proc _parse_json_stats(@ostats) {
	@stats = associative_array(
		'hp': array_get(@ostats, 'hp', 20),
		'texp': array_get(@ostats, 'txp', 0),
		'hunger': array_get(@ostats, 'fl', 20),
		'fire': array_get(@ostats, 'ft', 0),
		'sat': array_get(@ostats, 'sa', 5),
	);
	return(@stats);
}

proc _parse_custom_stats(@ostats) {
	@ostats = split(';', @ostats);
	@stats = associative_array();
	foreach(@data in @ostats) {
		@data = split(':', @data);
		@stats[@data[0]] = @data[1];
	}
	return(_parse_json_stats(@stats));
}

proc _parse_json_potions(@opotions) {
	@effects = array();
	foreach(@effect in @opotions) {
		@effects[] = associative_array(
			'id': @effect['pt'],
			'strength': @effect['pa'],
			'seconds': ceil(@effect['pd'] / 20),
		);
	}
	return(@effects);
}

proc _parse_custom_potions(@opotions) {
	@opotions = split(';', @opotions);
	@effects = array();
	foreach(@effect in @opotions) {
		@effect = split(',', @effect);
		@effects[] = array(
			'id': split(':', @effect[0])[1],
			'strength': split(':', @effect[2])[1],
			'seconds': ceil(split(':', @effect[1])[1] / 20),
		)
	}
	return(@effects);
}

proc _parse_json_bed(@obed) {
	@bed = array(
		@obed['x'],
		@obed['y'],
		@obed['z'],
		@obed['wo'],
	);
	return(@bed);
}

proc _parse_custom_bed(@obed) {
	@obed = split(';', @obed);
	@bed = associative_array();
	foreach(@data in @obed) {
		@data = split(':', @data);
		@bed[@data[0]] = @data[1];
	}
	return(_parse_json_bed(@bed));
}

/*
	Convert data values to custom potion effects
*/
proc _convert_potion(@olditem, @toyml = false) {
	@data = @olditem;
	@item = associative_array();
	if(is_array(@data)) {
		@data = @olditem['data'];
		@item = @olditem[];
		array_remove(@item, 'data');
		if(array_index_exists(@item, 'type')) {
			array_remove(@item, 'type');
		}
	}
	@item['name'] = 'POTION';
	if(!array_index_exists(@item, 'meta') || !@item['meta']) {
		@item['meta'] = associative_array();
	}
	if(!array_index_exists(@item['meta'], 'potions')) {
		@item['meta']['potions'] = array();
	}
	@id = 0;
	@strength = 0;
	@seconds = 180;
	@extended = false;
	if(@data >= 16385) {
		@data -= 16385;
		@item['name'] = 'SPLASH_POTION';
	} else {
		@data -= 8193;
	}
	if(@data >= 64) {
		@data -= 64;
		@extended = true;
	} else if(@data >= 32) {
		@data -= 32;
		@strength = 1;
	}
	if(!@toyml) {
		@ids = array(10, 1, 12, 19, 6, 16, 0, 18, 5, 2, 8, 7, 13, 14);
		@id = 0;
		try {
			@id = @ids[@data];
		} catch(IndexOverflowException @ex) {
			return(@item);
		}
		if(@data == 0) {
			if(@extended) {
				@seconds = 120;
			} else if(@strength) {
				@seconds = 23;
			} else {
				@seconds = 45;
			}
		} else if(@extended) {
			@seconds = 480;
		} else if(@strength) {
			@seconds = 90;
		}
		@item['meta']['potions'][] = associative_array(
			'id': @id,
			'strength': @strength,
			'seconds': @seconds,
		);
		return(@item);
	} else {
		@potion_names = array(
			'regeneration',
			'swiftness',
			'fire_resistance',
			'poison',
			'healing',
			'night_vision',
			'unknown',
			'weakness',
			'strength',
			'slowness',
			'leaping',
			'harming',
			'water_breathing',
			'invisibility',
		);
		@potion_name = 'minecraft:awkward';
		try {
			@potion_name = @potion_names[@data];
		} catch(IndexOverflowException @ex) {
			return(array(@item['name'], @potion_name));
		}
		if(@strength) {
			@potion_name = 'minecraft:strong_'.@potion_name;
		} else if(@extended) {
			@potion_name = 'minecraft:long_'.@potion_name;
		} else {
			@potion_name = 'minecraft:'.@potion_name;
		}
		return(array(@item['name'], @potion_name));
	}
}

proc _convert_monster_egg(@data) {
	@item = associative_array(
		'==': 'org.bukkit.inventory.ItemStack',
	    'type': 'MONSTER_EGG',
	    'meta': associative_array(
			'==': 'ItemMeta',
			'meta-type': 'UNSPECIFIC',
		),
	);
	@mobs = associative_array(
		100: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYeCG8D3yi4pTGRgA104FmCMAAAA=',
		120: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYeAIy8zJSUxPLWJgAADlEwUxIAAAAA==',
		98: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYWDzr0rNyS9hYAAA3vuJER4AAAA=',
		96: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYeD2LS3OKMrPz3XOL2dgAADFQ0VuIwAAAA==',
		95: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYWAJz89JY2AAAIves4gcAAAA',
		92: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYWB2zi9nYAAAtJxfHxsAAAA=',
		94: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYWANLiwFUgwAxMeU0x0AAAA=',
		65: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYWB2SixhYAAAbnymwBsAAAA=',
		91: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYWANzkhNLWBgAAABt1TGHQAAAA==',
		57: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYeAMyEyPys9NykxlYAAAHOM0OiEAAAA=',
		51: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYeAIzk7NSS3Jz2NgAAA4/sUgIAAAAA==',
		55: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYWANzsnMTWVgAABiUWxHHQAAAA==',
		52: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYeByTixLDS7ITEktYmAAAAPjG5IiAAAA',
		62: 'H4sIAAAAAAAAAONiYOBi4HTNK8ksqQxJTOdgYMpMYeD0SSxLDM7JzE1lYAAAOFY+siEAAAA=',
	);
	@item['meta']['internal'] = array_get(@mobs, @data, @mobs[100]);
	return(@item);
}
