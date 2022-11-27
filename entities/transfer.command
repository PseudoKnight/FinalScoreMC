register_command('transfer', array(
	description: 'Transfers the ownership of a tamed mob to another player.',
	usage: '/transfer <player>',
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = null;
		if(@args[0] != 'null') {
			@player = _find_player(@args[0]);
		}
		bind('player_interact_entity', array('id': 'transfer'.player().@player), null, @e, @player, @commandsender = player()) {
			if(player() != @commandsender) {
				die();
			}
			cancel();
			unbind();
			@owner = get_mob_owner(@e['id']);
			if(!@owner) {
				die(color('gold').'This mob has no owner or cannot be tamed!');
			}
			if(@owner != player() && !has_permission('group.moderator')) {
				die(color('gold').'This '.entity_type(@e['id']).' belongs to '.@owner.'.');
			}
			set_mob_owner(@e['id'], @player);
			msg(color('green').'This '.entity_type(@e['id']).' now belongs to '.@player.'.');
			if(ponline(@player)) {
				tmsg(@player, color('green').player().' gave a '.entity_type(@e['id']).' to you.');
			}
		}
		msg(color('yellow').'Right-click the tamed mob you wish to give to '.@player.'.');
	}
));
