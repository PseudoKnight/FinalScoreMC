// Button commands
bind('player_interact', null, array(block: 'STONE_BUTTON', button: 'right'), @event) {
	@signLoc = location_shift(@event['location'], 'up');
	if(is_sign_at(@signLoc)) {
		@line = get_sign_text(@signLoc);
		if(@type = reg_match('\u00A7[0-9a-f]{1}\\[(.+)\\]', @line[1])) {
			run_cmd('/'.to_lower(trim(@type[1])).' '.to_lower(strip_colors(@line[2])).' '.to_lower(strip_colors(@line[3])));
		}
	}
}