proc _rule_load(@binds, @value) {
	@numTeams = @value;
	@teams = array('Blue', 'Yellow', 'Green', 'Red')[cslice(0, @numTeams - 1)];
	for(@i = 0, @i < @numTeams, @i++) {
		create_team(@teams[@i], 'shard');
		set_team_display(@teams[@i], array('color': @teams[@i]), 'shard');
		set_team_options(@teams[@i], array('friendlyinvisibles': true, 'friendlyfire': false), 'shard');
	}

	@binds[] = 'shard-teams1';
	bind('world_changed', array('id': 'shard-teams1', 'priority': 'LOW'), array('to': 'shard'), @event, @numTeams, @teams) {
		queue_push(closure(){
			for(@i = 0, @i < @numTeams, @i++) {
				pgive_item(array('name': to_upper(@teams[@i]).'_WOOL', 'meta': array('display': color(@teams[@i]).@teams[@i])));
			}
		}, 'shard');
	}

	@binds[] = 'shard-teams2';
	bind('player_interact', array('id': 'shard-teams2'), array('button': 'right'), @event, @numTeams, @teams) {
		if(pworld() == 'shard' && @event['item'] && string_ends_with(@event['item']['name'], '_WOOL')) {
			@team = replace(@event['item']['name'], '_WOOL', '');
			if(array_contains_ic(@teams, @team)) {
				@count = 0;
				@otherCount = 0;
				foreach(@t in get_teams('shard')) {
					if(equals_ic(@t['name'], @team)) {
						@team = @t['name'];
						@count = array_size(@t['players']);
					} else {
						@otherCount = max(@otherCount, array_size(@t['players']));
					}
				}
				if(@otherCount >= @count) {
					_worldmsg('shard', player().' joined team '.color(@team).@team);
					team_add_player(@team, player(), 'shard');
					foreach(@item in array('BLUE_WOOL', 'YELLOW_WOOL', 'GREEN_WOOL', 'RED_WOOL')) {
						ptake_item(array('name': @item));
					}
				} else {
					msg('Too many players on that team. Please wait or join another team.');
				}
			}
		}
	}
}
