register_command('hazard', array(
	description: 'Starts a half-hazard game.',
	usage: '/hazard',
	permission: 'command.hazard',
	tabcompleter:  _create_tabcompleter(
		array('command.hazard.edit': array('set', 'clear', 'delete')),
		array('command.hazard.edit': array('<levelName>')),
		array('command.hazard.edit': array('start', 'end', 'warp', 'schematic', 'item')),
	),
	executor: closure(@alias, @sender, @args, @info) {
		if(@args && @args[0] === 'set') {
			if(!has_permission('command.hazard.edit')) {
				die(color('red').'No permission to edit hazard levels.');
			}
			if(array_size(@args) < 2) {
				die('Expected a level name.');
			}
			@name = @args[1];
			@level = get_value('hazard', @name);
			if(!@level) {
				@level = associative_array();
			}
			@setting = array_get(@args, 2, null);
			switch(@setting) {
				case 'start':
				case 'end':
					try {
						@pos1 = array_normalize(sk_pos1())[0..2];
						@pos2 = array_normalize(sk_pos2())[0..2];
						@level[@setting] = array(@pos1, @pos2);
						msg("Set @setting to: ".@level[@setting]);
					} catch(Exception @ex) {
						die('Must set a worldedit selection for the start/end.');
					}
				case 'warp':
					@level[@setting] = array_normalize(ploc())[0..3];
					msg("Set @setting to: ".@level[@setting]);
				case 'schematic':
					@coords = sk_region_info('hazard', pworld(), 0);
					sk_pos1(player(), @coords[0][0..2]);
					sk_pos2(player(), @coords[1][0..2]);
					skcb_copy(player());
					skcb_save('hazard_'.@name, player());
					skcb_clear(player());
					sk_pos1(player(), null);
					sk_pos2(player(), null);
					msg("Saved schematic for hazard level.");
				case 'item':
					@item = pinv(player(), null);
					if(!@item) {
						die('Must hold an item.');
					}
					if(!@item['meta']) {
						@item['meta'] = array(
							display: to_upper(@name[0]).@name[1..],
							lore: array(),
						);
					}
					@level[@setting] = @item;
					msg("Saved item for hazard menu.");
				default:
					die('Expected a setting: start, end, warp, item, schematic.');
			}
			store_value('hazard', @name, @level);
			return(true);
		}
		if(@args && @args[0] === 'clear') {
			if(!has_permission('command.hazard.edit')) {
				die(color('red').'No permission to edit hazard levels.');
			}
			@coords = sk_region_info('hazard', pworld(), 0);
			sk_pos1(null, @coords[0]);
			sk_pos2(null, @coords[1]);
			sk_setblock(null, 'air');
			sk_pos1(null, null);
			sk_pos2(null, null);
			return(true);
		}
		if(@args && @args[0] === 'delete') {
			if(!has_permission('command.hazard.edit')) {
				die(color('red').'No permission to edit hazard levels.');
			}
			if(array_size(@args) < 2) {
				die('Expected a level name.');
			}
			@name = @args[1];
			if(array_size(@args) > 2) {
				die('Cannot delete a setting.');
			}
			clear_value('hazard', @name);
			msg('Deleted '.@name);
			return(true);
		}
		if(import('hazard')) {
			die(color('gold').'Already running!');
		}
		include_dir('core.library');
		if(@args) {
			@game = _hazard_create(@args[0]);
			_hazard_start(@game);
		} else {
			@menu = array(array(
				name: 'GLASS',
				meta: array(
					display: color('white').'Empty',
					lore: array(color('gray').'An empty level with random start/end platforms.',
					color('dark_gray').'Run: /hazard empty'))
			));
			foreach(@key: @value in get_values('hazard')) {
				if(!array_index_exists(@value, 'item')) {
					continue();
				}
				if(is_null(@value['item']['meta']['lore'])) {
					@value['item']['meta']['lore'] = array();
				}
				@value['item']['meta']['lore'][] = color('dark_gray').'Run: /hazard '.split('.', @key)[1];
				@menu[] = @value['item'];
			}
			if(array_size(@menu) <= 5) {
				create_virtual_inventory(player(), 'HOPPER', 'Pick a Level', @menu);
			} else {
				create_virtual_inventory(player(), ceil(array_size(@menu) / 9) * 9, 'Pick a Level', @menu);
			}
			popen_inventory(player());
			bind('inventory_close', null, null, @event, @player = player()) {
				if(player() === @player) {
					unbind();
					delete_virtual_inventory(player());
				}
			}
		}
	},
));
