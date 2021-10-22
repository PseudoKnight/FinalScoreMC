/*
	Clips vines so that they stop growing. (1.18 feature backported)
 */
 bind('player_interact', null, array(itemname: 'SHEARS', button: 'right'), @event) {
	 @applicable = array('CAVE_VINES', 'TWISTING_VINES', 'WEEPING_VINES', 'KELP');
	 if(array_contains(@applicable, @event['block'])) {
		 @vine = get_blockdata(@event['location']);
		 if(@vine['age'] < 25) {
			@vine['age'] = 25;
			set_blockdata(@event['location'], @vine);
			pswing_hand(@event['hand']);
			play_sound(@event['location'], array(sound: 'ENTITY_SHEEP_SHEAR'));
			spawn_particle(@event['location'], array(particle: 'BLOCK_CRACK', block: @event['block']));
		 }
	 }
 }