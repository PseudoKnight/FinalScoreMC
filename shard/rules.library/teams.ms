@teams = array(1: 'Blue', 2: 'Yellow', 3: 'Green', 4: 'Red');
for(@i = 1, @i <= @rule['value'], @i++) {
    create_team(@teams[@i], 'shard');
    set_team_display(@teams[@i], array('prefix': color(@teams[@i])), 'shard');
    set_team_options(@teams[@i], array('friendlyinvisibles': true), 'shard');
}

@binds[] = 'shard-teams1';
bind(world_changed, array('id': 'shard-teams1', 'priority': 'LOW'), array('to': 'shard'), @event, @rule) {
    queue_push(closure(){
        for(@i = 0, @i < @rule['value'], @i++) {
            pgive_item('35:'.(@i + 3), 1);
        }
    }, 'shard');
}

@binds[] = 'shard-teams2';
bind(player_interact, array('id': 'shard-teams2'), array('item': 35, 'button': 'right'), @event, @rule, @teams) {
    if(pworld() == 'shard') {
        @team = integer(split(':', @event['item'])[1]) - 2;
        if(@team > 0 && @team <= @rule['value']) {
            _worldmsg('shard', player().' joined team '.color(@teams[@team]).@teams[@team]);
            team_add_player(@teams[@team], player(), 'shard');
            foreach(@c in array(3, 4, 5, 6)) {
                ptake_item('35:'.@c, @rule['value']);
            }
        }
    }
}
