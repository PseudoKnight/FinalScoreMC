switch(@action) {
case 'load':
	bind('projectile_launch', array(id: @player.'huntershoot'), array(type: 'ARROW', shootertype: 'PLAYER'), @event, @player) {
		if(@event['player'] == @player) {
			set_arrow_damage(@event['id'], 0.7);
		}
	}

	bind('projectile_hit', array('id': @player.'hunterhit'), array(type: 'ARROW', hittype: 'ENTITY'), @event, @pvp, @uuid = puuid(@player), @player) {
		if(@uuid == @event['shooter']) {
			@crossbow = pinv(@player, 0);
			if(!@crossbow['meta']['projectiles']) {
				@crossbow['meta']['projectiles'] = array(array(name: 'ARROW'));
				set_pinv(@player, 0, @crossbow);
				play_sound(ploc(@player), array(sound: 'ITEM_CROSSBOW_LOADING_END'));
			}
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
	unbind(@player.'hunterhit');
	unbind(@player.'hunterswap');
	unbind(@player.'hunterblast');

}
