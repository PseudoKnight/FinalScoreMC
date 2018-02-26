if(!has_permission('command.resettimes')) {
	die('You do not have permission to reset stats for this course.')
}
if(!@player) {
	die('This requires a player.');
}
@puuid = _get_uuid(to_lower(@player));
@courses = get_values('times'.if(@id !== 'all', '.'.@id))
if(is_null(@courses)) {
	die('Unknown arena.');
}
@count = 0;
foreach(@key: @time in @courses) {
	if(is_array(@time) && @key != 'times') {
		foreach(@i: @t in @time) {
			if(@t[0] == @puuid) {
				msg('Removing '.@player.' from top ten in '.split('.', @key)[1]);
				array_remove(@time, @i);
				store_value(@key, @time);
				break();
			}
		}
	} else {
		try {
			@uuid = split('.', @key)[2];
		} catch(IndexOverflowException @ex) {
			// not a player time
			continue();
		}
		if(@uuid == @puuid) {
			msg('Removing '.@player.'\'s time in '.split('.', @key)[1]);
			clear_value(@key);
			@count += 1;
		}
	}
}
msg('Finished resetting '.@player.'\'s times in '.@count.' courses.');
