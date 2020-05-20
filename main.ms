set_cron('*/5 * * * *', iclosure(){
	@activities = _get_activities_string();
	@allocMem = get_server_info(15);
	@freeMem = get_server_info(16);
	console('---[ TPS: '.round(tps()[0], 1).' ]'
		.'---[ MEM: '.floor((@allocMem - @freeMem) / 1000000).'MB ]'
		.'---[ PLAYERS: '.array_size(all_players()).' ]'
		.'---'.if(@activities, '[ Activities: '.@activities.' ]---'), false);
});

bind('server_ping', null, null, @event) {
	@currently = _get_activities_string();
	@motd = colorize('&6&l\u1260&d&l\u1260&b&l\u1260&4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &f\u25AA \u25AA \u25AA  &7[1.15.2]');
	modify_event('motd', @motd.if(@currently, colorize('\n&aActivities&f: ').@currently));
}
