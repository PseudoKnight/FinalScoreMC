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

/*
	Makes a call to the ban manager to store the player's UUID
	@endpoint - String - The action to take in the ban manager.
	@player - String - The player name making the call to the ban manager, or the UUID of the player.
	This player must be an admin or moderator.
	@params - Associative Array - The parameters to post to the ban manager.
	@callback - Closure (Optional) - Executes on success of request
	@error - Closure (Optional) - Closure to execute when the request returns an error.
	The closure is passed the error message. Defaults to printing the error message to the user.\
*/
proc _bm_request(@endpoint, @player, @params, @callback, @error) {

	# Add the authentication parameters
	@params['accessor_token'] = 'final-score-minecraft-server';
	@params['timestamp'] = simple_date('yyyy-MM-dd HH:mm:ss Z');
	@params['nonce'] = rand();
	@params['uuid'] = @player;

	# Generate the HMAC
	@hmac_key = comp_read('key.txt');
	@msg = '';
	foreach(@key in array_keys(@params)) {
		@msg .= @key . @params[@key];
	}
	@params['hmac'] = hmac_sha1(@hmac_key, @msg);

	try {
		http_request('http://finalscoremc.com/fsmcbm/ban-manager.php?action='.@endpoint, array(
			'method': 'POST',
			'params': @params,
			'success': closure(@response){
				@result = @response['body'];
				if(@result) {
					@result = json_decode(@result);
					if(!is_array(@result)) {
						// result was a single value for some reason
					} else if(array_index_exists(@result, 'error') && @result['error'] !== 'Nothing found.') {
						if(is_closure(@error)) {
							execute(@result['error'], @error);
						} else {
							execute(@result['error'], closure(@error_msg) {
								console('Error in remote Ban Manager: '.@error_msg, false);
							});
						}
					} else if(is_closure(@callback)) {
						execute(@result, @callback ||| closure());
					}
				}
			}
		));
	} catch(IOException @ex) {} // website might be down.
}
