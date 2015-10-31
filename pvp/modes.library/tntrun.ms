array_push(@pvp['binds'], @id.'nodrops')
bind(item_spawn, array('id': @id.'nodrops'), array('item': 70), @e, @region = @pvp['arena']['region']) {
	if(array_contains(sk_regions_at(@e['location']), @region)) {
		cancel()
	}
}

array_push(@pvp['binds'], @id.'limitentities')
bind(entity_change_block, array('id': @id.'limitentities'), array('from': 12), @e, @region = @pvp['arena']['region']) {
	if(array_contains(sk_regions_at(@e['location']), @region)) {
		entity_remove(@e['entity'])
	}
}