switch(@action) {
case 'load':
	bind('projectile_launch', array(id: @player.'huntershoot'), array(type: 'ARROW', shootertype: 'PLAYER'), @event, @player) {
		if(@event['player'] == @player) {
			set_entity_spec(@event['id'], array(damage: 0.7));
		}
	}

	bind('item_swap', array(id: @player.'hunterswap', priority: 'HIGHEST'), array(off_hand: 'FIREWORK_ROCKET', player: @player), @event) {
		consume();
	}

case 'unload':
	unbind(@player.'huntershoot');
	unbind(@player.'hunterswap');

}
