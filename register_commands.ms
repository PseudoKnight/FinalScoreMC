/*
	This does a recursive depth first search for all files ending with *.command, compiles and run them.
	If this occurs during a recompile, it defers this in a queue per directory.
	The primary purpose of this is to limit blocking recompile time on a live server.
	This approach is not recommended for modern CommandHelper projects,
	as it is not very compatible with Static Analysis and VSCode without modification of CH.
	Instead, consider static includes of ms files with include_dir() of .library paths.
*/
int proc _register_commands(string @parent = '.', boolean @recompile = import('recompile')) {
	int @count = 0;
	array @commandFiles = array();
	foreach(string @file in list_files(@parent)) {
		@path = @parent.'/'.@file;
		if(is_dir(@path)) {
			if(string_position(@file, '.disabled') < 0 && string_position(@file, '.library') < 0) {
				@count += _register_commands(@path);
			}
		} else if(string_ends_with(@file, '.command')) {
			@commandFiles[] = @file;
			@count++;
		}
	}
	@registerCommands = iclosure(@commandFiles) {
		foreach(@file in @commandFiles) {
			try {
				include(@file);
			} catch(IncludeException @ex) {
				console(@ex['message'], false);
			}
		}
	}
	if(@recompile) {
		queue_push(@registerCommands);
	} else {
		@registerCommands();
	}
	return(@count);
}

queue_push(iclosure(int @count = _register_commands()) {
	msg(@count.' command files processed.');
});