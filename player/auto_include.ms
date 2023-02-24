/*
	Gets online player from truncated name in user input.
	Supports names in the player's account name history. (stored locally)
*/
proc _find_player(@player) {
	try {
		// this is the cheapest way to autocomplete an online player name
		// however, the exception is not cheap
		return(player(@player));
	} catch(PlayerOfflineException @ex) {
		// also support old player names, which are loaded in when a player joins
		@players = import('players', array());
		@player = to_lower(@player);
		foreach(@name: @current in @players) {
			if(string_starts_with(@name, @player)) {
				return(@current);
			}
		}
		die(color('yellow').'Could not find player starting with "'.@player.'"');
	}
}
