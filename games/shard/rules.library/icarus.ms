proc _rule_load(@binds, @value) {
	@binds[] = bind('world_changed', array(priority: 'LOW'), array(to: 'shard'), @event) {
		queue_push(closure(){
			ptake_item(player(), array(name: 'ELYTRA')); // just in case they have one already
			pgive_item(player(), array(name: 'ELYTRA'));
			pgive_item(player(), array(name: 'FIREWORK', qty: 64));
		}, 'shard');
	}
}