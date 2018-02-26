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
