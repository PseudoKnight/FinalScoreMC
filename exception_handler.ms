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