switch(@action) {
case 'powerup':
	set_phunger(@player, 0)
	set_phealth(@player, min(20, pinfo(player(), 5) + 2));
	set_peffect(@player, 22, 0, 30);
}
