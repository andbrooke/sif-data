#!/usr/bin/perl
use strict;
use warnings;
use perl5i::2;
use Data::Dumper;
use YAML;
use DBI;
use Data::UUID;
use Data::RandomPerson;
use Text::CSV;
use Data::Random qw/:all/;


# XXX 
#	- Add missing data to existing entries

my $config = YAML::LoadFile($ENV{HOME} . "/.nsip_sif_data");
my $dbh = DBI->connect(
	$config->{mysql_dsn}, 
	$config->{mysql_user}, 
	$config->{mysql_password},
	{RaiseError => 1, AutoCommit => 1}
);

my @sex = (qw/Male Female Male Female Male Female Male Female Unknown/);	# XXX no Unkonwn - problem with RAND ?
my @salutation = (qw/Mr Mrs Dr Ms Miss/);
# my @kla = qw/English Mathematics Arts Technology Humanities Sports/;
my @kla = (
	"The Arts",
	"The Arts",
	"Humanities & Social Sciences",
	"Humanities & Social Sciences",
	"Science",
	"Science",
	"History",
	"Geography",
	"Religious Education"
);
my @yearlevel = (qw/P K K3 K4 PS UG 1 2 3 4 5 6 7 8 9 10 11 12/);
my @indigenous = (
	'Aboriginal but not Torres Strait Islander Origin',
	'Torres Strait Islander but Not Aboriginal Origin',
	'Both Torres Strait and Aboriginal Origin',
	'Neither Aboriginal or Torres Strait Origin',
	'Neither Aboriginal or Torres Strait Origin',
	'Neither Aboriginal or Torres Strait Origin',
	'Neither Aboriginal or Torres Strait Origin',
	'Neither Aboriginal or Torres Strait Origin',
	'Neither Aboriginal or Torres Strait Origin',
	'Neither Aboriginal or Torres Strait Origin',
	'Neither Aboriginal or Torres Strait Origin',
	'Neither Aboriginal or Torres Strait Origin',
	'Not Stated/Unknown'
);

my @campus = (
	'Camp',
	'Commty',
	'EarlyCh',
	'JunPri',
	'Kgarten',
	'Kind',
	'Lang',
	'MCH',
	'Middle',
	'Other',
	'PreSch',
	'Pri/Sec',
	'Prim',
	'Sec',
	'Senior',
	'Special',
	'Specif',
	'Supp',
	'Unknown',
);

# Helper functions - Put in library?
my @postcodes;
my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
  or die "Cannot use CSV: ".Text::CSV->error_diag ();

open my $fh, "<:encoding(utf8)", "../data/postcodes.csv" or die "../data/postcodes.csv: $!";
while ( my $row = $csv->getline( $fh ) ) {
	push @postcodes, $row;
}
$csv->eof or $csv->error_diag();
close $fh;

sub create_address {
	my $r = Data::RandomPerson->new();
	my $p = $r->create();
	my @roads = ("Road","Street","Court","Crescent","Drive","Avenue","Boulevard", "Lane","Way","Walk","Square");
	my $stnumber = int(rand(300))+1;
	my $index = rand @roads;
	my $road = $roads[$index];
	$index = rand @postcodes;
	my @postbox = $postcodes[$index];
	my $address = "$stnumber $p->{firstname} $road, $postbox[0][1], $postbox[0][2], $postbox[0][0]";
	return $address;
}

# TODO - see alos @yearlevel
sub create_yearlevel {
	return int(rand(12)) + 1;
}

sub create_birthdate {
	my ($min, $max) = @_;
	return rand_date( min => $min, max => $max ) . '';
}

my @domains = qw/mail.edu.au/;
sub create_email {
	# Random address ?
	# Random domain ?
	# NO duplicates !

	my @part1 = qw/red green orange blue yellow purple orange banana apple mellon/;
	my @domain = qw/mail.vic.edu.au people.vic.edu.au vic.edu.au dashboard.vic.edu.au/;
	return ''
		. $part1[int rand($#part1 + 1)]
		. int(rand(999))
		. '@'
		. $domain[int rand($#domain + 1)]
}

sub update {
	my ($table, $fields, $match, $id) = @_;
	my $SQL = ''
		. qq{UPDATE $table SET }
		. join(", ", map { "$_ = ?" } sort keys %$fields)
		. " WHERE $match = ?"
	;
	print $SQL . ", " . join(", ", ( map { $fields->{$_} } sort keys %$fields) , $id) . "\n";
	my $sth = $dbh->prepare($SQL);
	$sth->execute( (map { $fields->{$_} } sort keys %$fields), $id);
}

# ==============================================================================
# SchoolInfo
# ==============================================================================
my $sth = $dbh->prepare("SELECT * FROM SchoolInfo");
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
	my $change = {};
	
	if (! $row->{CampusSchoolCampusId}) {
		$change->{CampusSchoolCampusId} = int(rand(4))+1;
	}
	if (! $row->{CampusAdminStatus}) {
		$change->{CampusAdminStatus} = rand(10) > 8 ? 'N' : 'Y';
	}
	if (! $row->{CampusCampusType}) {
		$change->{CampusCampusType} = $campus[int rand($#campus + 1)]
	}
	if (keys %$change) {
		print Dumper($change);
		update('SchoolInfo', $change, 'RefId', $row->{RefId});
	}
}


# ==============================================================================
# StaffPersonal
# ==============================================================================
$sth = $dbh->prepare("SELECT * FROM StaffPersonal");
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
	my $change = {};
	if (! $row->{Sex}) {
		$change->{Sex} = $sex[int rand($#sex + 1)]; 
	}
	if (! $row->{Email}) {
		$change->{Email} = create_email();
	}
	if (! $row->{Salutation}) {
		$change->{Salutation} = $salutation[int rand($#salutation + 1)]; 
	}
	
	if (keys %$change) {
		print Dumper($change);
		update('StaffPersonal', $change, 'RefId', $row->{RefId});
	}
}


# ==============================================================================
# TeachingGroup
# ==============================================================================
$sth = $dbh->prepare("SELECT * FROM TeachingGroup");
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
	my $change = {};
	if (! $row->{KLA}) {
		$change->{KLA} = $kla[int rand($#kla + 1)]; 
	}
	
	if (keys %$change) {
		print Dumper($change);
		update('TeachingGroup', $change, 'RefId', $row->{RefId});
	}
}

# ==============================================================================
# StudentPersonal
# ==============================================================================
$sth = $dbh->prepare("SELECT * FROM StudentPersonal");
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
	my $change = {};
	if (! $row->{Sex}) {
		$change->{Sex} = $sex[int rand($#sex + 1)]; 
	}
	if (! $row->{Email}) {
		$change->{Email} = create_email();
	}
	if (! $row->{YearLevel}) {
		$change->{YearLevel} = $yearlevel[int rand($#yearlevel + 1)]; 
	}
	if (! $row->{IndigenousStatus}) {
		$change->{IndigenousStatus} = $indigenous[int rand($#indigenous + 1)]; 
	}
	if (! $row->{BirthDate}) {
		$change->{BirthDate} = create_birthdate('1994-01-01', '2009-01-01');
	}
	
	if (keys %$change) {
		print Dumper($change);
		update('StudentPersonal', $change, 'RefId', $row->{RefId});
	}
}

