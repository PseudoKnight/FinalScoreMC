switch(@action) {
case 'load':
	bind('entity_damage_player', array('id': @player.'robotdmg'), array('damager': 'PLAYER'), @event, @player = @player) {
		if(@event['player'] == @player
		&& pinv(@event['player'], 103)['type'] == 158) {
			set_pinv(@event['player'], array(103: array('type': 23)))
			set_timeout(500, closure(){
				if(pinv(@event['player'], 103)['type'] == 23) {
					set_pinv(@event['player'], array(103: array('type': 103)))
				}
			})
		}
	}
	
case 'unload':
	unbind(@player.'robotdmg')
}