switch(@action) {
case 'load':
	bind('entity_damage_player', array('id': @player.'robotdmg'), array('damager': 'PLAYER'), @event, @player = @player) {
		if(@event['player'] == @player) {
			@item = pinv(@event['player'], 103)
			if(!is_null(@item) && @item['type'] == 158) {
				set_pinv(@event['player'], array(103: array('type': 23)))
				set_timeout(1000, closure(){
					@item = pinv(@event['player'], 103)
					if(!is_null(@item) && @item['type'] == 23) {
						set_pinv(@event['player'], array(103: array('type': 158)))
					}
				})
			}
		}
	}
	
	bind('player_consume', array('id': @player.'robotconsume'), null, @event, @player = @player) {
		if(@event['player'] == @player) {
			cancel()
		}
	}

case 'powerup': 
	set_phunger(@player, 4)
	set_psaturation(@player, 16)
	
case 'unload':
	unbind(@player.'robotdmg')
	unbind(@player.'robotconsume')
}