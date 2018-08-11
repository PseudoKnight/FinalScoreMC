/*
	This finds all files ending with *.command within two directory levels, compiles and run them.
	If this occurs during a recompile, it defers this per file by using a queue.
	The primary purpose of this is to limit blocking recompile time on a live server.
	Commands that cannot be deferred should not use *.command suffixes.
*/
@recompile = import('recompile');
foreach(@directory in list_files('.')) {
	if(is_dir(@directory) && string_position(@directory, '.disabled') < 0) {
		foreach(@file in list_files(@directory)) {
			if(string_ends_with(@file, '.command')) {
				@closure = closure() {
					try {
						include(@directory.'/'.@file);
					} catch(IncludeException @ex) {
						console(@ex['message'], false);
					}
				}
				if(@recompile) {
					queue_push(@closure);
				} else {
					execute(@closure);
				}
			} else if(is_dir(@subdir = @directory.'/'.@file)) {
				foreach(@f in list_files(@subdir)) {
					if(string_ends_with(@f, '.command')) {
						@closure = closure() {
							try {
								include(@subdir.'/'.@f);
							} catch(IncludeException @ex) {
								console(@ex['message'], false);
							}
						}
						if(@recompile) {
							queue_push(@closure);
						} else {
							execute(@closure);
						}
					}
				}
			}
		}
	}
}
