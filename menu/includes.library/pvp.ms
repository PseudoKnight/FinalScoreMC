proc _refresh_menu() {
	@menu = import('menu.pvp');
	@count = array_size(all_players('custom'));
	if(@count == @menu['lastCount']) {
		return();
	}
	@menu['lastCount'] = @count;
	@menu = @menu[];
	@i = 0;
	foreach(@item in @menu['inv']) {
		if(@item['qty'] <= @count) {
			@menu[@i] = @item;
			@i++;
		}
	}
	array_remove(@menu, 'inv');
	create_virtualchest(@menu);
}
