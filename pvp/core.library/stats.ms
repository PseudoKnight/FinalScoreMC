proc _stats_damage(@damager, @player, @amount, @pvp) {
	if(array_index_exists(@pvp, 'stats')
	&& array_index_exists(@pvp['stats'], @damager)
	&& @damager != @player) {
		@pvp['stats'][@damager]['damage'] += @amount;
		
		if(@pvp['stats'][@player]['damager'] != ''
		&& @pvp['stats'][@player]['damager'] != @damager) {
			@pvp['stats'][@player]['lastdamager'] = @pvp['stats'][@player]['damager'];
			@pvp['stats'][@player]['lastdamaged'] = @pvp['stats'][@player]['damaged'];
		}
		@pvp['stats'][@player]['damager'] = @damager;
		@pvp['stats'][@player]['damaged'] = time();
	}
}

proc _pad_stat(@amount, @length) {
	@length -= length(@amount);
	if(@length <= 0, return(@amount));
	@pad = '';
	while(@length > 0) {
		@pad .= '0';
		@length--;
	}
	return(color(8).@pad.color('r').@amount);
}