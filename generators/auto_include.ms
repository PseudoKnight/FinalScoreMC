proc _generator_create(@type, @config, @region, @world, @seed, @callback, @debug = false) {
	proc _generate(@config, @region, @world, @seed, @callback, @debug) {}
	include("shared.library/util.ms");
	include("structure.library/@type/generator.ms");
	_generate(@config, @region, @world, @seed, @callback, @debug);
}
