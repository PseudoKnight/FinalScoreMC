register_command('warps', array(
	'description': 'Lists and manage warp locations.',
	'usage': '/warps <list|delete|resetmarkers> [warp_id]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('list', 'delete', 'resetmarkers'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
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
				@worlds = get_worlds();
				@warplist = associative_array();
				foreach(@world in @worlds) {
					@warplist[@world] = '';
				}
				foreach(@warpkey: @warpdata in @warps) {
					@warplist[@warpdata[3]] .= split('.', @warpkey)[1].' ';
				}
				msg(color('bold').'AVAILABLE WARPS:');
				foreach(@worldname: @worldwarps in @warplist) {
					if(@worldwarps) {
						msg(color(7).'['.to_upper(_worldname(@worldname)).'] '.color(15).@worldwarps);
					}
				}
			case 'resetmarkers':
				if(!has_permission('group.admin')) {
					die(color('gold').'You do not have permission to use this command.');
				}
				if(!function_exists('dm_all_markersets')) {
					die(color('gold').'Uneditable at this time.')
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
						dm_create_marker('warps', array('id': @name, 'label': to_upper(@name), 'location': @warp, 'world': @warp[3], 'icon': 'star', 'persistent': true));
					}
				}
		
				msg(color('green').'Done.');
		
			default:
				return(false);
		}
	}
));
