switch(@action) {
case 'load':
	bind(player_death, array('id': @player.'death'), array('player': @player), @event) {
		@horse = get_entity_vehicle(pinfo(player(), 13))
		if(@horse) {
			damage_entity(@horse, 20)
		}
	}

case 'unload':
	unbind(@player.'death')
	
}