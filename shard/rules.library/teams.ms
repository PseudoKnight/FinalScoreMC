@teams = array('Blue', 'Yellow', 'Green', 'Red');
for(@i = 0, @i < @rule['value'], @i++) {
	create_team(@teams[@i], 'shard');
	set_team_display(@teams[@i], array('prefix': color(@teams[@i])), 'shard');
	set_team_options(@teams[@i], array('friendlyinvisibles': true, 'friendlyfire': false), 'shard');
}

proc _get_team(@player) {
	foreach(@team in get_teams('shard')) {
		if(array_contains(@team['players'], @player)) {
			return(@team['name']);
		}
	}
	return(null);
}

@binds[] = 'shard-teams1';
bind(world_changed, array('id': 'shard-teams1', 'priority': 'LOW'), array('to': 'shard'), @event, @rule, @teams) {
	queue_push(closure(){
		for(@i = 0, @i < @rule['value'], @i++) {
			pgive_item(player(), '35:'.(@i + 3), 1, array('display': color(@teams[@i]).@teams[@i]));
		}
	}, 'shard');
}

@binds[] = 'shard-teams2';
bind(player_interact, array('id': 'shard-teams2'), array('item': 35, 'button': 'right'), @event, @rule, @teams) {
	if(pworld() == 'shard') {
		@team = integer(split(':', @event['item'])[1]) - 3;
		if(@team > -1 && @team < @rule['value']) {
			_worldmsg('shard', player().' joined team '.color(@teams[@team]).@teams[@team]);
			team_add_player(@teams[@team], player(), 'shard');
			foreach(@c in array(3, 4, 5, 6)) {
				ptake_item('35:'.@c, @rule['value']);
			}
		}
	}
}
