register_command('skipper', array(
	'description': 'Toggles gliding with skipping.',
	'usage': '/skipper',
	'permission': 'command.skipper',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(has_bind(player().'skipperglide')) {
			unbind(player().'skipperglide');
			unbind(player().'skipperchanged');
			msg(color('green').'Disabled skipper mode.');
		} else {
			bind(entity_toggle_glide, array('id': player().'skipperglide'), array('type': 'PLAYER', 'player': player()), @event) {
				if(!@event['gliding'] && !psneaking()) {
					cancel();
				}
			}
			bind(world_changed, array('id': player().'skipperchanged'), array('player': player()), @event) {
				unbind(player().'skipperglide');
				unbind();
			}
			if(!pinv(player(), 103)) {
				set_pinv(player(), 102, array('name': 'ELYTRA'));
			}
			msg(color('green').'Enabled skipper mode.');
		}
	}
));
