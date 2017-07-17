foreach(@directory in list_files('.')) {
	if(is_dir(@directory)) {
		foreach(@library in list_files(@directory)) {
			if(@library == 'command.library') {
				@base = @directory.'/command.library';
				queue_push(closure(){
					foreach(@file in list_files(@base)) {
						include(@base.'/'.@file);
					}
				});
			}
		}
	}
}
