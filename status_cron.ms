/*
	Every five minutes log a general server status update.
	Used memory is probably inaccurate, but it's useful information.
 */
set_cron('*/5 * * * *', iclosure(){
	@activities = array_keys(import('activities', associative_array()));
	@allocMem = get_server_info(15);
	@freeMem = get_server_info(16);
	console('---[ TPS: '.round(tps()[0], 1).' ]'
		.'---[ MEM: '.floor((@allocMem - @freeMem) / 1000000).' MB ]'
		.'---[ PLAYERS: '.array_size(all_players()).' ]'
		.'---'.if(@activities, '[ Activities: '.@activities.' ]---'), false);
});