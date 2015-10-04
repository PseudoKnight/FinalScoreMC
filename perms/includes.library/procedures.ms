proc _perm_player(@player) {
	unperm_player(@player);
	@pdata = _pdata(@player);
	_add_group_perms(@player, array_get(@pdata, 'group', 'default'));
}

proc _add_group_perms(@player, @group) {
	@perms = import('perms');
	# Add inherited perms first
	if(array_index_exists(@perms[@group], 'inheritance')) {
		_add_group_perms(@player, @perms[@group]['inheritance']);
	}
	foreach(@perm: @value in @perms[@group]['permissions']) {
		set_permission(@player, @perm, @value);
	}
	if(array_index_exists(@perms[@group], 'worlds')
	&& array_index_exists(@perms[@group]['worlds'], pworld(@player))) {
		foreach(@perm: @value in @perms[@group]['worlds'][pworld(@player)]) {
			set_permission(@player, @perm, @value);
		}
	}
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