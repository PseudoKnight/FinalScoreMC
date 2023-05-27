register_command('warps', array(
	description: 'Lists and manage warp locations.',
	usage: '/warps <list|delete|resetmarkers> [warp_id]',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('list', 'delete', 'resetmarkers'), @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		switch(@args[0]) {
			case 'del':
			case 'delete':
				if(!has_permission('command.setwarp')) {
					die(color('gold').'You do not have permission to use this command.');
				}
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				if(!@id) {
					die(color('gold').'This requires a warp name.');
				}
				if(!has_value('warp.'.@id)) {
					die(color('gold').'There is no warp by that name.');
				}
				clear_value('warp.'.@id);
				try {
					if(function_exists('dm_delete_marker')) {
						dm_delete_marker('warps', 'warp.'.@id);
					}
				} catch(Exception @ex) {
					// ignore
				}
				msg(color('green').'Deleted warp.');

			case 'list':
				@warps = get_values('warp');
				@worldGroup = _world_group(pworld());
				@worlds = get_worlds();
				@warplist = array();
				foreach(@world in @worlds) {
					if(_world_allows_teleports(@world)) {
						@warplist[] = replace(_world_name(@world), ' ', '');
					}
				}
				msg(color('green').color('bold').'Available Worlds:');
				msg(array_implode(@warplist));
				@warplist = array();
				foreach(@warpkey: @warpdata in @warps) {
					if(_world_group(@warpdata[3]) == @worldGroup) {
						@warplist[] = split('.', @warpkey)[1];
					}
				}
				if(@warplist) {
					msg(color('green').color('bold').'Available Warps for '.to_upper(@worldGroup).':');
					msg(array_implode(@warplist));
				}

			case 'resetmarkers':
				if(!has_permission('group.admin')) {
					die(color('gold').'You do not have permission to use this command.');
				}
				if(!function_exists('dm_all_markersets')) {
					msg(color('gold').'Uneditable at this time.');
				}
				@markersets = array();
				if(function_exists('dm_all_markersets')) {
					@markersets = dm_all_markersets();
				}
				if(array_contains(@markersets, 'warps')) {
					if(function_exists('dm_delete_markerset')) {
						dm_delete_markerset('warps');
					}
				}
		
				if(function_exists('dm_create_markerset')) {
					dm_create_markerset('warps', array('label': 'Warps', 'persistent': true));
				}
				if(function_exists('dm_set_markerset_hide_by_default')) {
					dm_set_markerset_hide_by_default('warps', true);
				}

				@warps = get_values('warp');

				foreach(@name: @warp in @warps) {
					if(function_exists('dm_create_marker')) {
						dm_create_marker('warps', array(
							'id': @name,
							'label': to_upper(@name),
							'location': @warp,
							'world': @warp[3],
							'icon': 'star',
							'persistent': true
						));
					}
				}

				msg(color('green').'Done.');

			default:
				return(false);
		}
	}
));
