proc _generator_create(@type, @config, @region, @world, @seed, @callback) {
	proc _generate(@dungeonType, @region, @world, @seed, @callback) {}
	include('generator.library/'.@type.'.ms');
	_generate(@config, @region, @world, @seed, @callback);
}
