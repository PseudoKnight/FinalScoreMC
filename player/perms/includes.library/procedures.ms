proc _perm_player(@player, @force = true) {
	@pdata = _pdata(@player);
	@group = 'default';
	if(array_index_exists(@pdata, 'group')) {
		@group = @pdata['group'];
	}
	if(@force || !has_permission(@player, 'group.'.@group)) {
		_add_group_perms(@player, @group, true);
	}
	if(pisop(@player) && @group != 'admin') {
		psetop(@player, false);
	}
}

proc _add_group_perms(@player, @group, @primaryGroup = false) {
	@groupPerms = import('perms')[@group];
	@perms = associative_array();
	# Add inherited perms first
	if(array_index_exists(@groupPerms, 'inheritance')) {
		@perms = _add_group_perms(@player, @groupPerms['inheritance']);
	}
	@perms = array_merge(@perms, @groupPerms['permissions']);
	# Add world overrides
	if(array_index_exists(@groupPerms, 'worlds', pworld(@player))) {
		@perms = array_merge(@perms, @groupPerms['worlds'][pworld(@player)]);
	}
	if(@primaryGroup) {
		set_permissions(@player, @perms);
	}
	return(@perms);
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
		set_display_name(@player, _colorname(@player).@player);
		set_list_name(@player, display_name(@player));
	}
	return(@oldGroup);
}
