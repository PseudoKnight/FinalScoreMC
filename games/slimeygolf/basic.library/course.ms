proc _get_course(@loc) {
	foreach(@region in sk_regions_at(@loc)) {
		if(reg_match('^slimeygolf', @region)) {
			return(@region);
		}
	}
	return(null);
}
