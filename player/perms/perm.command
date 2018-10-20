register_command('perm', array(
	'description': 'Manages permission groups.',
	'usage': '/perm <reload|setgroup|ingroup|havegroup> [player] <group>',
	'permission': 'command.perm',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('reload', 'setgroup', 'ingroup', 'havegroup'), @args[-1]));
		} else if(array_size(@args) == 3) {
			@groups = array_keys(import('perms'));
			if(array_index_exists(@groups, 'limitedworldedit')) {
				array_remove(@groups, 'limitedworldedit');
			}
			return(_strings_start_with_ic(@groups, @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		switch(@args[0]) {
			case 'reload':
				msg(color('e').'Reloading permissions...');
				include('includes.library/procedures.ms');
				@perms = yml_decode(read('config.yml'));
				export('perms', @perms);
				foreach(@p in all_players()) {
					_perm_player(@p);
				}
				msg(color('a').'Config reloaded and new permissions applied to players.');

			case 'setgroup':
				if(array_size(@args) < 3) {
					return(false);
				}
				include('includes.library/procedures.ms');
				if(@oldgroup = _set_group(@args[1], @args[2])) {
					msg('Changed group from '.@oldgroup.' to '.@args[2]);
				} else {
					msg('Could not set player\'s group to '.@args[2]);
				}

			case 'ingroup':
				if(array_size(@args) < 2) {
					return(false);
				}
				@group = to_lower(@args[1]);
				x_new_thread('players_in_group', closure(){
					@list = '';
					foreach(@pdata in get_values('uuids')) {
						if(array_index_exists(@pdata, 'group') && @pdata['group'] == @group) {
							@list .= @pdata['name'].' ';
						}
					}
					if(length(@list) > 480) {
						@list = substr(@list, 0, 480).'...';
					}
					msg('Players in "'.@group.'" group: '.@list);
				});

			case 'havegroup':
				if(array_size(@args) < 2) {
					return(false);
				}
				@group = to_lower(@args[1]);
				x_new_thread('players_have_group', closure(){
					@groups = array(@group);
				
					// get groups that inherit this group
					@perms = import('perms');
					@allgroups = array_keys(@perms);
					for(@i = 0, @i < array_size(@perms), @i++) {
						@thisGroup = @perms[@allgroups[@i]];
						if(array_index_exists(@thisGroup, 'inheritance') && @groups[-1] == @thisGroup['inheritance']) {
							@groups[] = @allgroups[@i];
							@i = -1;
						}
					}
				
					// populate list of players that are in or inherit this group
					@list = '';
					foreach(@pdata in get_values('uuids')) {
						if(array_index_exists(@pdata, 'group') && array_contains(@groups, @pdata['group'])) {
							@list .= @pdata['name'].' ';
						}
					}
					if(length(@list) > 480) {
						@list = substr(@list, 0, 480).'...';
					}
					msg('Players that have "'.@group.'" perms: '.@list);
				});

			default:
				msg(colorize(
					'&7/perm reload &rReload configuration and reassign permissions\n'
					.'&7/perm setgroup <p> <g> &rAssign this group to a player\n'
					.'&7/perm ingroup <g> &rLists all players assigned to this group\n'
					.'&7/perm havegroup <g> &rLists all players that have this group'
				));
		}
	}
));
