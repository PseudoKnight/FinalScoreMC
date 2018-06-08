/*
	This finds all files ending with *.command within two directory levels, compiles and run them.
	If this occurs during a recompile, it defers this per file by using a queue.
	The primary purpose of this is to limit blocking recompile time on a live server.
	Commands that cannot be deferred should not use *.command suffixes.
*/
@recompile = import('recompile');
foreach(@directory in list_files('.')) {
	if(is_dir(@directory)) {
		foreach(@file in list_files(@directory)) {
			if(string_ends_with(@file, '.command')) {
				if(@recompile) {
					queue_push(closure(){
						include(@directory.'/'.@file);
					});
				} else {
					include(@directory.'/'.@file);
				}
			} else if(is_dir(@subdir = @directory.'/'.@file)) {
				foreach(@f in list_files(@subdir)) {
					if(string_ends_with(@f, '.command')) {
						if(@recompile) {
							queue_push(closure(){
								include(@subdir.'/'.@f);
							});
						} else {
							include(@subdir.'/'.@f);
						}
					}
				}
			}
		}
	}
}
