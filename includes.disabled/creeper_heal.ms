
// Example script of healing creeper block damage.
// I abandoned this approach.
bind('entity_explode', array(priority: 'LOWEST'), array(type: 'CREEPER'), @event) {
	if(!is_cancelled()) {
		@blocks = array();
		@minY = 320;
		foreach(@blockLocation in @event['blocks']) {
			@blocks[] = array(
				data: get_blockdata_string(@blockLocation),
				location: @blockLocation);
			if(@blockLocation['y'] < @minY) {
				@minY = integer(@blockLocation['y']);
			}
		}
		@creeperDamage = import('creeper.damage', array());
		@creeperDamage[] = array(
			location: @event['location'],
			minY: @minY,
			time: time(),
			blocks: @blocks);
		export('creeper.damage', @creeperDamage);
		modify_event('yield', 0);
	}
}

set_interval(1000, closure(){
	@creeperDamage = import('creeper.damage');
	if(@creeperDamage) {
		@twentySecondsAgo = time() - 20000;
		foreach(@index: @entry in @creeperDamage) {
			if(@twentySecondsAgo > @entry['time'] && !players_in_radius(@entry['location'], 16)) {
				foreach(@blockIndex: @block in @entry['blocks']) {
					// restore blocks from the bottom up
					if(@block['location']['y'] <= @entry['minY']) {
						set_blockdata_string(@block['location'], @block['data']);
						array_remove(@entry['blocks'], @blockIndex);
					}
				}
				if(@entry['blocks']) {
					@entry['minY']++;
				} else {
					array_remove(@creeperDamage, @index);
				}
			}
		}
	}
});