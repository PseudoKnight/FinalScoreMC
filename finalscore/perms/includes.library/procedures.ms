proc _perm_player(@player, @clear = true) {
	@pdata = _pdata(@player);
	@group = 'default';
	if(array_index_exists(@pdata, 'group')) {
		@group = @pdata['group'];
	}
	_add_group_perms(@player, @group, false);
}

proc _add_group_perms(@player, @group, @return = true) {
	@perms = import('perms');
	@toAdd = associative_array();
	# Add inherited perms first
	if(array_index_exists(@perms[@group], 'inheritance')) {
		@toAdd = _add_group_perms(@player, @perms[@group]['inheritance']);
	}
	@toAdd = array_merge(@toAdd, @perms[@group]['permissions']);
	if(array_index_exists(@perms[@group], 'worlds')
	&& array_index_exists(@perms[@group]['worlds'], pworld(@player))) {
		@toAdd = array_merge(@toAdd, @perms[@group]['worlds'][pworld(@player)]);
	}
	if(@return) {
		return(@toAdd);
	}
	set_permissions(@player, @toAdd);
}

proc _set_group(@player, @group, @checkInheritance = false) {
	@group = to_lower(@group);
	@perms = import('perms');
	if(!array_index_exists(@perms, @group)) {
		msg(color('gold').'No group by that name.');
		return(false);
	}
	@pdata = _pdata(@player);
	@oldGroup = 'default';
	if(array_index_exists(@pdata, 'group')) {
		@oldGroup = @pdata['group'];
	}
	if(@oldGroup == @group) {
		msg(color('gold').'Already in group "'.@group.'"');
		return(false);
	}
	if(@checkInheritance) {
		@checkGroup = @oldGroup;
		while(array_index_exists(@perms[@checkGroup], 'inheritance')) {
			@checkGroup = @perms[@checkGroup]['inheritance'];
			if(@checkGroup == @group) {
				msg(color('gold').'Already in group that inherits "'.@group.'"');
				return(false);
			}
		}
	}
	@pdata['group'] = @group;
	_store_pdata(@player, @pdata);
	if(ponline(@player)) {
		_perm_player(@player);
	}
	return(@oldGroup);
}

proc _players_in_group(@group) {
	@list = '';
	foreach(@pdata in get_values('uuids')) {
		if(array_index_exists(@pdata, 'group') && @pdata['group'] == @group) {
			@list .= @pdata['name'].' ';
		}
	}
	if(length(@list) > 480) {
		return(substr(@list, 0, 480).'...');
	}
	return(@list);
}

proc _players_have_group(@group) {
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
		return(substr(@list, 0, 480).'...');
	}
	return(@list);
}
