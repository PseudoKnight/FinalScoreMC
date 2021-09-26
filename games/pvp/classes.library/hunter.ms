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

case 'powerup':
	@newDog = true;
	@wolves = entities_in_radius(ploc(@player), 24, 'WOLF');
	foreach(@wolf in @wolves) {
		if(get_mob_owner(@wolf) == @player) {
			@newDog = false;
			break();
		}
	}
	if(@newDog) {
		spawn_entity('WOLF', 1, entity_loc(puuid(@player)), closure(@wolf) {
			set_mob_owner(@wolf, @player);
			set_entity_spec(@wolf, array(color: array_get_rand(reflect_pull('enum', 'DyeColor'))));
		});
	}

case 'unload':
	unbind(@player.'huntershoot');
	unbind(@player.'hunterswap');
	foreach(@wolf in entities_in_radius(ploc(@player), 64, 'WOLF')) {
		if(get_mob_owner(@wolf) == @player) {
			entity_remove(@wolf);
		}
	}

}
