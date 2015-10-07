proc _perm_player(@player, @clear = true) {
	@pdata = _pdata(@player);
	_add_group_perms(@player, array_get(@pdata, 'group', 'default'), false);
}

proc _add_group_perms(@player, @group, @return = true) {
	@perms = import('perms');
	@toAdd = array();
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

proc _set_group(@player, @group) {
	@group = to_lower(@group);
	@perms = import('perms');
	if(!array_index_exists(@perms, @group)) {
		msg('No group by that name.');
		return(false);
	}
	@pdata = _pdata(@player);
	@oldgroup = @pdata['group'];
	@pdata['group'] = @group;
	_store_pdata(@player, @pdata);
	if(ponline(@player)) {
		_perm_player(@player);
	}
	return(@oldgroup);
}