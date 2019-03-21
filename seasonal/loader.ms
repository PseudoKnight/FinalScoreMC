@month = simple_date('MMM');
@day = integer(simple_date('d'));
if(@month == 'Dec' && @day == 31 || @month == 'Jan' && @day == 1) {
	include('seasons.library/newyears.ms');
} else if(@month == 'Feb' && @day > 9 && @day < 15) {
	include('seasons.library/valentines.ms');
} else if(@month == 'Mar' && @day > 14 && @day < 20) {
	include('seasons.library/stpatricks.ms');
} else if(@month == 'Mar' && @day > 21 || @month == 'Apr' && @day < 26) {
	include('seasons.library/easter.ms');
} else if(@month == 'Oct' && @day > 10) { // three weeks
	include('seasons.library/halloween.ms');
}
