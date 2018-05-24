register_command('ride', array(
	'description': 'Ride on another player\'s shoulders',
	'usage': '/ride <player>',
	'permission': 'command.ride',
	'executor': closure(@alias, @sender, @args, @info) {
		@player = _find_player(@args[0]);
		tmsg(@player, color('yellow').player().' wants you to pick them up!');
		msg(color('yellow').'Asked '.@player.' to pick you up!');
		@id = bind('player_interact_entity', null, array('clicked': 'PLAYER', 'hand': 'main_hand'), @event, @player) {
			if(player() == @player) {
				set_entity_rider(puuid(), @event['id']);
				play_sound(ploc(), array('sound': 'ITEM_ARMOR_EQUIP_LEATHER'));
				unbind();
			}
		}
		set_timeout(10000, closure(){
			if(has_bind(@id)) {
				unbind(@id);
			}
		});
	}
));
