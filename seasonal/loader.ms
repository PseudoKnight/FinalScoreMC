@month = simple_date('MMM');
@day = integer(simple_date('d'));
if(@month == 'Dec' && @day > 29 || @month == 'Jan' && @day == 1) {
	export('event', color('yellow').'Happy New Years!');
	include('seasons.library/newyears.ms');
} else if(@month == 'Feb' && @day > 9 && @day < 15) {
	export('event', color('dark_red').'\u2764');
	include('seasons.library/valentines.ms');
} else if(@month == 'Mar' && @day > 14 && @day < 20) {
	export('event', color('green').'Good Luck!');
	include('seasons.library/stpatricks.ms');
} else if(@month == 'Mar' && @day > 21 || @month == 'Apr' && @day < 26) {
	export('event', color('light_purple').'Easter Egg Hunt');
	include('seasons.library/easter.ms');
} else if(@month == 'Oct') {
	export('event', color('gold').'Haunted');
	include('seasons.library/halloween.ms');
}