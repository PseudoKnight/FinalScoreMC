proc _spl_reward(@player) {
	_acc_add(@player, 1)
	tmsg(@player, color('gold').'+1 Coin')
}

proc _spl_clear_pinv(@player) {
	set_pinv(@player, array(
		null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null,
		100: null, 101: null, 102: null, 103: null
	))
}

proc _spl_get_tool(@floorblock) {
	switch(@floorblock[0]
	#shovel
	, array(1, 3, 12, 13, 60, 78, 80, 82, 88, 110),
		return(array(
			'type': 277,
			'data': 0,
			'enchants': array(array('elevel': 4, 'etype': 'DIG_SPEED'), array('elevel': 3, 'etype': 'DURABILITY')),
			'meta': array('display': 'SUPER SHOVEL')
		))
	
	# axe
	, array(5, 17, 25, 47, 53, 58, 84, 85, 86, 91, 99, 100, 107, 125, 126, 134, 135, 136, 151, 162, 163, 164), 
		return(array(
			'type': 279,
			'data': 0,
			'enchants': array(array('elevel': 9, 'etype': 'DIG_SPEED'), array('elevel': 3, 'etype': 'DURABILITY')),
			'meta': array('display': 'SUPER AXE')
		))
	
	# else pick axe
	, 
		return(array(
			'type': 278,
			'data': 0,
			'enchants': array(array('elevel': 39, 'etype': 'DIG_SPEED'), array('elevel': 3, 'etype': 'DURABILITY')),
			'meta': array('display': 'SUPER AXE')
		))
		
	)
}