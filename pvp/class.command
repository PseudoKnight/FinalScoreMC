register_command('class', array(
	description: 'Manages pvp class configurations.',
	usage: '/class <set|load|delete|info|list|rename> <arena_id:class_id> <setting> <value(s)>',
	permission: 'command.class',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('set', 'load', 'delete', 'info', 'list', 'rename'), @args[-1]));
		} else if(array_size(@args) == 3) {
			@action = @args[0];
			if(@action == 'set' || @action == 'delete') {
				@completions = array('selector', 'kit', 'ammo', 'stacklimit', 'speed', 'hunger', 'effect', 'script',
						'team', 'xp', 'limit', 'disabled');
			} else if(@action == 'load') {
				@completions = array('kit', 'selector', 'ammo');
			}
			return(_strings_start_with_ic(@completions, @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@action = @args[0];
		@id = @args[1];
		switch(@action) {
			case 'set':
				if(array_size(@args) < 3) {
					return(false);
				}
				@setting = @args[2];
				@arenaid = null;
				@classid = null;
				try {
					@arenaid = split(':', @id)[0];
					@classid = split(':', @id)[1];
				} catch(IndexOverflowException @ex) {
					die(color('gold').'You need to specify an arena and class.');
				}
				@arena = get_value('arena', @arenaid);
				if(!@arena) {
					die(color('gold').'No arena by that name: '.@arenaid);
				}
				if(!array_index_exists(@arena, 'classes')) {
					@arena['classes'] = associative_array();
				}
				if(!array_index_exists(@arena['classes'], @classid)) {
					@arena['classes'][@classid] = associative_array();
				}
				switch(@setting) {
					case 'selector':
						@item = pinv(player(), null);
						if(!@item) {
							die(color('gold').'You must select an item on your hotbar.');
						}
						@arena['classes'][@classid]['selector'] = _minify_inv(@item);
						msg(color('green').'Class selector set to this item.');

					case 'kit':
						@arena['classes'][@classid]['kit'] = _minify_inv(pinv());
						msg(color('green').'Set kit to current inventory.');

					case 'ammo':
						@arena['classes'][@classid]['ammo'] = _minify_inv(pinv());
						msg(color('green').'Set ammo to current inventory.');

					case 'stacklimit':
						if(array_size(@args) < 5) {
							die(color('gold').'Stacklimit needs two values: item name and stack size limit.');
						}
						if(@args[4] < 1) {
							array_remove(@arena['classes'][@classid]['stacklimit'], @args[3]);
						} else {
							@arena['classes'][@classid]['stacklimit'][@args[3]] = integer(@args[4]);
						}
						msg(color('green').'Set stack size limit to '.@args[4].' for item '.@args[3].'.');

					case 'speed':
						if(array_size(@args) < 4 || @args[3] < 0 || @args[3] > 1) {
							die(color('gold').'Must be betwee 0 and 1');
						}
						@arena['classes'][@classid]['speed'] = @args[3];
						msg(color('green').'Set class speed to '.@args[3].' (default 0.2)');

					case 'hunger':
						if(array_size(@args) < 4 || @args[3] < 0 || @args[3] > 20) {
							die(color('gold').'Requires hunger between 0 and 20.');
						}
						@saturation = 5;
						if(array_size(@args) > 4) {
							@saturation = @args[4];
							if(@saturation !== '~' && (@saturation < 0 || @saturation > 20)) {
								die(color('gold').'Saturation must be within 0 and 20.');
							}
						}
						@arena['classes'][@classid]['hunger'] =	array(@args[3], @saturation);
						msg(color('green').'Set hunger to '.@args[3].' hunger '
								.if(@saturation === '~', 'statically.', 'and '.@saturation.' saturation.'));

					case 'effect':
						if(array_size(@args) < 6) {
							die(color('gold').'Requies a potion effect, strength, and seconds.');
						}
						@effect = to_upper(@args[3]);
						@strength = @args[4];
						@seconds = @args[5];
						if(!array_contains(reflect_pull('enum', 'PotionEffectType'), @effect)) {
							die(color('gold').'Unknown potion effect. '.reflect_pull('enum', 'PotionEffectType'));
						}
						if(!array_index_exists(@arena['classes'][@classid], 'effect')) {
							@arena['classes'][@classid]['effect'] = associative_array();
						}
						if(@strength == 0 || @seconds == 0) {
							array_remove(@arena['classes'][@classid]['effect'], @effect);
							if(array_size(@arena['classes'][@classid]['effect']) == 0) {
								array_remove(@arena['classes'][@classid], 'effect');
							}
							msg(color('green').'Removed potion effect '.@effect.'.');
						} else {
							@arena['classes'][@classid]['effect'][@effect] = array(strength: @strength - 1, length: @seconds);
							msg(color('green').'Set potion effect for class: '.@effect.' '.@strength.' for '.@seconds.' seconds.');
						}

					case 'script':
						if(array_size(@args) < 4) {
							return(false);
						}
						if(@args[3] === 'true') {
							@arena['classes'][@classid]['script'] = true;
							msg(color('green').'Turned ON special script loading for this class.');
						} else if(@args[3] === 'false' && array_index_exists(@arena['classes'][@classid], 'script')) {
							array_remove(@arena['classes'][@classid], 'script');
							msg(color('green').'Turned OFF special script loading for this class.');
						}

					case 'team':
						if(array_size(@args) < 4) {
							return(false);
						}
						@arena['classes'][@classid]['team'] = @args[3];
						msg(color('green').'Set team to '.@args[3]);

					case 'xp':
						if(array_size(@args) < 4) {
							return(false);
						}
						if(is_numeric(@args[3]) && @args[3] <= 100 && @args[3] >= 0) {
							@arena['classes'][@classid]['xp'] = @args[3]
							msg(color('green').'Set class to start with '.@args[3].'% of their experience bar.');
						} else {
							die(color('gold').'It needs to be a number from 0 to 100');
						}
					
					case 'limit':
						if(array_size(@args) < 4) {
							return(false);
						}
						@arena['classes'][@classid]['limit'] = integer(@args[3]);
						msg(color('green').'Set limit to '.@args[3]);

					case 'disabled':
						if(array_size(@args) < 4) {
							return(false);
						}
						@disabled = (@args[3] == 'true' || @args[3] == 'on');
						if(@disabled) {
							@arena['classes'][@classid]['disabled'] = @disabled;
							msg(color('green').'Disabled class');
						} else {
							array_remove(@arena['classes'][@classid], 'disabled');
							msg(color('green').'Enabled class');
						}

					default:
						return(false);
				}
				store_value('arena', @arenaid, @arena);

			case 'delete':
				@arenaid = null;
				@classid = null;
				try {
					@arenaid = split(':', @id)[0];
					@classid = split(':', @id)[1];
				} catch(IndexOverflowException @ex) {
					die(color('gold').'You need to specify an arena and class.');
				}
				@arena = get_value('arena', @arenaid);
				if(!@arena) {
					die(color('gold').'No arena by that name: '.@arenaid);
				}
				if(!array_index_exists(@arena['classes'], @classid)) {
					die(color('gold').'No class by that name.');
				}
				if(array_size(@args) == 3) {
					array_remove(@arena['classes'][@classid], @args[2]);
					msg(color('green').@args[2].' deleted from '.@classid);
				} else {
					array_remove(@arena['classes'], @classid);
					msg(color('green').'Class deleted.');
				}
				store_value('arena', @arenaid, @arena);

			case 'info':
				@arenaid = null;
				@classid = null;
				try {
					@arenaid = split(':', @id)[0];
					@classid = split(':', @id)[1];
				} catch(IndexOverflowException @ex) {
					die(color('gold').'You need to specify an arena and class.');
				}
				@arena = get_value('arena', @arenaid);
				if(!@arena) {
					die(color('gold').'No arena by that name: '.@arenaid);
				}
				if(!array_index_exists(@arena['classes'], @classid)) {
					die(color('gold').'No class by that name.');
				}
				foreach(@setting: @value in @arena['classes'][@classid]) {
					msg(color('gray').@setting.' '.color('r').@value);
				}

			case 'rename':
				if(array_size(@args) < 3) {
					die(color('gold').'You must specify a new name.');
				}
				@arenaid = null;
				@classid = null;
				try {
					@arenaid = split(':', @id)[0];
					@classid = split(':', @id)[1];
				} catch(IndexOverflowException @ex) {
					die(color('gold').'You need to specify an arena and class.');
				}
				@arena = get_value('arena', @arenaid);
				if(!@arena) {
					die(color('gold').'No arena by that name: '.@arenaid);
				}
				if(!array_index_exists(@arena['classes'], @classid)) {
					die(color('gold').'No class by that name.');
				}
				@new = @args[2];
				@arena['classes'][@new] = @arena['classes'][@classid];
				if(array_index_exists(@arena['classes'][@new], 'selector')) {
					@arena['classes'][@new]['selector']['meta']['display'] = to_upper(@new);
				}
				array_remove(@arena['classes'], @classid);
				store_value('arena', @arenaid, @arena);
				msg(color('green').'Changed '.@classid.' class name to '.to_lower(@new));

			case 'load':
				if(array_size(@args) < 3) {
					die(color('gold').'You must specify a setting.');
				}
				@arenaid = null;
				@classid = null;
				try {
					@arenaid = split(':', @id)[0];
					@classid = split(':', @id)[1];
				} catch(IndexOverflowException @ex) {
					die(color('gold').'You need to specify an arena and class.');
				}
				@arena = get_value('arena', @arenaid);
				if(!@arena) {
					die(color('gold').'No arena by that name: '.@arenaid);
				}
				switch(@args[2]) {
					case 'kit':
						@pvp = associative_array();
						@pvp['arena'] = @arena;
						include('core.library/classes.ms');
						_class('equip', player(), @classid, @pvp);
						
					case 'selector':
						set_pinv(player(), null, @arena['classes'][@classid]['selector']);
						
					case 'ammo':
						set_pinv(player(), @arena['classes'][@classid]['ammo']);
						
					default:
						die(color('gold').'Unsupported setting to load.');
				}

			case 'list':
				@arena = get_value('arena', @id);
				if(!@arena) {
					die(color('gold').'No arena by that name: '.@id);
				}
				@list = '';
				foreach(@class in array_keys(@arena['classes'])) {
					@list .= @class.' ';
				}
				msg(color('gray').'CLASSES IN '.to_upper(@id).': '.color('r').@list);

			default:
				return(false);
		}
	}
));
