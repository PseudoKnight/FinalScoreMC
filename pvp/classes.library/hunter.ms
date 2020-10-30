switch(@action) {
case 'load':
	bind('projectile_launch', array(id: @player.'huntershoot'), array(type: 'ARROW', shootertype: 'PLAYER'), @event, @player) {
		if(@event['player'] == @player) {
			set_arrow_damage(@event['id'], 0.7);
			set_timeout(800, closure() {
				if(entity_exists(@event['id'])) {
					set_pcooldown(@player, 'CROSSBOW', 20);
					play_sound(ploc(@player), array('sound': 'ENTITY_ITEM_BREAK'));
				}
			})
		}
	}

	bind('item_swap', array(id: @player.'hunterswap', priority: 'HIGHEST'), array(off_hand: 'FIREWORK_ROCKET', player: @player), @event) {
		consume();
	}

	bind('entity_damage', array(id: @player.'hunterblast', priority: 'HIGHEST'), array(cause: 'ENTITY_EXPLOSION'), @event, @player, @pvp) {
		if(entity_type(@event['damager']) == 'FIREWORK' && get_firework_shooter(@event['damager']) == puuid(@player)) {
			consume();
			if(array_index_exists(@event, 'player')) {
				_stats_damage(@player, @event['player'], @event['amount'], @pvp);
			}
		}
	}

case 'unload':
	unbind(@player.'huntershoot');
	unbind(@player.'hunterswap');
	unbind(@player.'hunterblast');

}
