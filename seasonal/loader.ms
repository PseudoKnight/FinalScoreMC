@month = simple_date('MMM');
@day = integer(simple_date('d'));
if(@month == 'Feb' && @day > 9 && @day < 15) {
    include('seasons.library/valentines.ms');
} else if(@month == 'Mar' && @day > 21 || @month == 'Apr' && @day < 26) {
    include('seasons.library/easter.ms');
} else if(@month == 'Oct' && @day > 7) {
    include('seasons.library/halloween.ms');
}
