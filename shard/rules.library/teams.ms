@numTeams = @value;
@teams = array('Blue', 'Yellow', 'Green', 'Red');
for(@i = 0, @i < @numTeams, @i++) {
	create_team(@teams[@i], 'shard');
	set_team_display(@teams[@i], array('prefix': color(@teams[@i])), 'shard');
	set_team_options(@teams[@i], array('friendlyinvisibles': true, 'friendlyfire': false), 'shard');
}

@binds[] = 'shard-teams1';
bind(world_changed, array('id': 'shard-teams1', 'priority': 'LOW'), array('to': 'shard'), @event, @numTeams, @teams) {
	queue_push(closure(){
		for(@i = 0, @i < @numTeams, @i++) {
			pgive_item(array('name': 'WOOL', 'data': @i + 3, 'meta': array('display': color(@teams[@i]).@teams[@i])));
		}
	}, 'shard');
}

@binds[] = 'shard-teams2';
bind(player_interact, array('id': 'shard-teams2'), array('item': 35, 'button': 'right'), @event, @numTeams, @teams) {
	if(pworld() == 'shard') {
		@team = integer(split(':', @event['item'])[1]) - 3;
		if(@team > -1 && @team < @numTeams) {
			@count = 0;
			@otherCount = 0;
			foreach(@t in get_teams('shard')) {
				if(@t['name'] == @teams[@team]) {
					@count = array_size(@t['players']);
				} else {
					@otherCount = max(@otherCount, array_size(@t['players']));
				}
			}
			if(@otherCount >= @count) {
				_worldmsg('shard', player().' joined team '.color(@teams[@team]).@teams[@team]);
				team_add_player(@teams[@team], player(), 'shard');
				foreach(@c in array(3, 4, 5, 6)) {
					ptake_item(array('name': 'WOOL', 'data': @c));
				}
			} else {
				msg('Too many players on that team. Please wait or join another team.');
			}
		}
	}
}
