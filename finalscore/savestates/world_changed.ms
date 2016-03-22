bind(world_changed, null, null, @event) {
    @to = @event['to'];
    @from = @event['from'];
    @worlds = _worlds_config();
    if(@worlds[@from]['mode'] != @worlds[@to]['mode']) {
        # let's swap inventory
        close_pinv();
		set_pmode(@worlds[@to]['mode']);
        include('util.library/storage.ms');
        if(@worlds[@from]['mode'] == 'survival') {
            _store_pstate(@event['player'], 'survival');
            _clear_pstate(@event['player']);
        } else if(@worlds[@to]['mode'] == 'survival') {
            console('Loading survival inventory for '.@event['player'].' coming from '.@from.'.');
            _get_pstate(@event['player'], 'survival');
        } else {
            _clear_pstate(@event['player']);
        }
        if(@worlds[@to]['mode'] == 'adventure') {
            _equip_park();
        }
    }
}
