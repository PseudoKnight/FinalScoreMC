/*
	Every five minutes log a general server status update.
	Used memory is probably inaccurate, but it's useful information.
 */
set_cron('*/5 * * * *', iclosure(){
	@activities = _get_activities_string();
	@allocMem = get_server_info(15);
	@freeMem = get_server_info(16);
	console('---[ TPS: '.round(tps()[0], 1).' ]'
		.'---[ MEM: '.floor((@allocMem - @freeMem) / 1000000).' MB ]'
		.'---[ PLAYERS: '.array_size(all_players()).' ]'
		.'---'.if(@activities, '[ Activities: '.@activities.' ]---'), false);
});

/*
	This is the output for the multiplayer server list.
 */
bind('server_ping', null, null, @event) {
	@currently = _get_activities_string();
	@motd = colorize('&6&l\u1260&d&l\u1260&b&l\u1260&4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &f\u25AA \u25AA \u25AA');
	modify_event('motd', @motd.if(@currently, colorize('\n&aActivities&f: ').@currently));
}

/*
	Format all exception messages according to the sender and receiver.
	Only displays technical details to console/log, not to player.
*/
set_uncaught_exception_handler(iclosure(@ex){
	if(@loc = get_command_block()) {
		console('Exception occurred in CommandBlock at '.array_normalize(@loc)[0..3], false);
	} else if(ponline(player())) {
		msg(color('red').@ex['message']);
	}
	console(split('.', @ex['classType'])[-1].': '.@ex['message'], false);
	foreach(@trace in @ex['stackTrace']) {
		console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id'], false);
	}
	return(true);
});