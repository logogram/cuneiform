#!/usr/bin/perl -w
use strict;
use CGI qw(:all *table *Tr *td);
use Data::Dumper;
use XML::Twig;
use XML::Simple;
use utf8;
#this fixes the wide warnings and the numbers not being sub script
binmode STDOUT, ":utf8";

#http://perlmeme.org/tutorials/cgi_script.html
#charts with http://www.highcharts.com/

# with logograms:
# ? plural markers (-MESZ, -ME, -DIDLI), dual (-MIN, .2), and ditto signs distinguished somehow in Oracc? not really
# ? how about numbers? n

my $projname = "SAA 1";
my $projdir = "../dataout/";
my $ogslfile = "../resources/ogsl.xml";

my @vowels = ("a", "e", "i", "u");
my @consonants = ("\x{02BE}", "b", "d", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "\x{1E63}", "\x{0161}", "t", "\x{1E6D}", "z");
my @finalconsonants = ("\x{02BE}", "b/p", "d/t/\x{1E6D}", "g/k/q", "h", "l", "m", "n", "r", "\x{0161}", "z/s/\x{1E63}");
my @tableheaders = ("V", "CV", "VC", "CVC");

my %restdata = ();
my %totals = ();

&tables($projdir.'SYLLABIC');

print   header({-charset => 'utf-8'}),
        start_html(
                       -title => 'Cuneiform literacy',
                       -script => [ {-language=>'javascript',
                                   -src=>"http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js"},
				    {-language=>'javascript',
                                   -src=>"../www/js/highcharts.js"},
				    {-language=>'javascript',
                                   -src=>"../www/js/genericchart.js"}
				    ]
                       ),
                
        h1('Syllabic sign use '.$projname);

my $h2count = 0;
foreach my $i (@tableheaders) {
    $h2count++;
    my @test = split("",$i);
    my @alldata = ();
    my @lastone = ();
    my @lastbutone = ();
    my $cnt = 0;
    my $numcvc = scalar @test; 
    my $lastone = "";
    my $string = "";
    foreach my $j (@test){
	$string .= $j;
	$lastone = $j;
	my @tempdata = ();
	@lastbutone = ();
	if($cnt ==0){#this is the first time around
	    if($j eq 'C'){
		foreach my $c (@consonants){
		    push(@tempdata,$c);
		    push(@alldata,$c);
		}
	    }
	    elsif($j eq 'V'){
		foreach my $v (@vowels){
		    push(@tempdata,$v);
		    push(@alldata,$v);
		}
	    }
	}
	else{
	    foreach my $key (@alldata){
		if($j eq 'C'){
		    foreach my $c (@consonants){
			push(@tempdata,$key.$c);
		    }
		}
		elsif($j eq 'V'){
		    foreach my $v (@vowels){
			push(@tempdata,$key.$v);
		    }
		}
	    }
	}
	
	$cnt++;
	if($cnt == $numcvc){#this is the last but one
	    @lastbutone = @alldata;
	}
	@alldata = @tempdata;
    }
    
    $string =~ s|C|Consonant|gsi;
    $string =~ s|V|Vowel|gsi;
    print h2($h2count.". ".$string);
    print h3($i), start_table({-border=>1, -cellpadding=>3}), start_Tr, th([$i]);
    if($numcvc ==1){
	print end_Tr;
	if($lastone eq 'V'){
	    foreach my $v (@vowels) {
		print start_Tr;
		print td($v);
		my $string = ref($restdata{$i}{$v}) eq 'ARRAY' ?join(", ",@{$restdata{$i}{$v}}):" ";
		print td([$string]);
	    }
	}
	else {
	foreach (keys %{$restdata{$i}}){   # this shouldn't happen
	    print start_Tr;
	    print td($_);
	    my $string = ref($restdata{$i}{$_}) eq 'ARRAY' ?join(", ",@{$restdata{$i}{$_}}):" ";
	    print td([$string]);
	}
	print end_Tr;
	}
    }
    else{
	if($lastone eq 'C'){
	    foreach my $c (@finalconsonants){
		print th([$c]);   # still have to get rid of aleph in CVC
	    }
	}
	elsif($lastone eq 'V'){
	    foreach my $v (@vowels){
		print th([$v]);
	    }
	}
	print end_Tr;
    
	foreach my $key (@lastbutone){
	    if($lastone eq 'C'){
		# check if there are values beginning with $key when checking CVCs, otherwise no use to print them
		my $thereis = 0;
		foreach my $c (@consonants){  # must be possible to do this easier
		    if (exists($restdata{$i}{$key.$c})) {
			$thereis++;
		    }
		}
		if ($thereis != 0) {
		    print start_Tr, td([$key]);
		    foreach my $c (@finalconsonants){
			if (length($c) == 1) {
			    my $string = ref($restdata{$i}{$key.$c}) eq 'ARRAY' ?join(", ",@{$restdata{$i}{$key.$c}}):" ";
			    print td([$string]);
			}
			else {
			    my @letter = split("/",$c);
			    my $string = "";
			    foreach my $j (@letter){
				my $temp = ref($restdata{$i}{$key.$j}) eq 'ARRAY' ?join(", ",@{$restdata{$i}{$key.$j}}):" ";
				if ($temp ne " ") {
				    if ($string eq "") {
				    $string = $temp;
				    }
				    else {
				    $string = $string."; ".$temp;
				    }   
				}
				
			    }
			    print td([$string]);
			}
		    }
		}
	    }
	    elsif($lastone eq 'V'){
		print start_Tr, td([$key]);
		foreach my $v (@vowels){
		    my $string = ref($restdata{$i}{$key.$v}) eq 'ARRAY' ?join(", ",@{$restdata{$i}{$key.$v}}):" ";
		    print td([$string]);
		}
	    }
	    print end_Tr;
	}
    }
    print end_table;
}

# print Others
print h2($h2count++.". Others");
print start_table({-border=>1, -cellpadding=>3});
foreach my $i (sort keys %restdata){
    if (grep {$_ eq $i} @tableheaders) {
  	# already done, just don't know how to negate the grep
    }
    else {
	my $string = "";
	foreach my $element (sort keys $restdata{$i}) {
	    if ($string eq "") {
		$string = $element;
	    }
	    else {
		$string = $string.', '.$element;
	    }
	}
	print start_Tr, td([$i]), td([$string]), end_Tr;
    }
}
print end_table;

my $pietotals="<div id='container' style='min-width: 400px; height: 400px; margin: 0 auto'></div><script>";
$pietotals .= " var currentdata= [";
my $others = 0;
my $VVtotal = $totals{"VV"}{"total"};
foreach my $d (sort keys %totals){
    if (grep {$_ eq $d} @tableheaders) {
	my $sum = $totals{$d}{"total"};
	if ($d eq "CV") { $sum = $sum + $VVtotal; }
	$pietotals .= " ['".$d." (".$sum.")"."',   ".$sum."],";
    }
    elsif (($d ne "VV") && ($d ne "C")) {
	# VVs are counted together with CVs while Cs are determinatives and do not belong here.
	$others = $others + $totals{$d}{"total"};
	}    
}
if ($others > 0) {
    $pietotals .= " ['Others (".$others.")',   ".$others."],";
}

$pietotals = substr($pietotals,0,length($pietotals)-1);
$pietotals .= " ]";

$pietotals .= "; \$(document).ready(function() {";
$pietotals .= "   var alldata = pieoptions;";
$pietotals .= "   alldata.title.text = 'Distribution across corpus';";
$pietotals .= "   alldata.series[0].data = currentdata;";
$pietotals .= "	chart = new Highcharts.Chart(alldata);";
$pietotals .= "});</script>";

print $pietotals;

my $piediffvalues="<div id='container2' style='min-width: 400px; height: 400px; margin: 0 auto'></div><script>";
$piediffvalues .= " var currentdata2= [";
my $othercat = 0;
my $VVdiff = $totals{"VV"}{"diff_values"};
foreach my $d (sort keys %totals){
    if (grep {$_ eq $d} @tableheaders) {
	my $sum = $totals{$d}{"diff_values"};
	if ($d eq "CV") { $sum = $sum + $VVdiff; }
	$piediffvalues .= " ['".$d." (".$sum.")"."',   ".$sum."],";
    }
    elsif (($d ne "VV") && ($d ne "C")) {
	# VVs are counted together with CVs while Cs are determinatives and do not belong here.
	$othercat = $othercat + $totals{$d}{"diff_values"};
	}    
}
if ($othercat > 0) {
    $piediffvalues .= " ['Others (".$others.")',   ".$othercat."],";
}

$piediffvalues = substr($piediffvalues,0,length($piediffvalues)-1);
$piediffvalues .= " ]";

$piediffvalues .= "; \$(document).ready(function() {";
$piediffvalues .= "   var alldata2 = pieoptions;";
$piediffvalues .= "   alldata2.chart.renderTo = 'container2';"; 
$piediffvalues .= "   alldata2.title.text = 'Different values per category';";
$piediffvalues .= "   alldata2.series[0].data = currentdata2;";
$piediffvalues .= "	chart2 = new Highcharts.Chart(alldata2);";
$piediffvalues .= "});</script>";

print $piediffvalues;


print end_html;

sub tables{
    my $filename = shift;
    my $twigObj = XML::Twig->new();
    
    $twigObj->parsefile($filename);
    my $root = $twigObj->root;
    $twigObj->purge;

    my $counter = 0;
    my @data = $root->get_xpath('type');
    my %alldata;
    
    my $twigObjCun = XML::Twig->new();
    $twigObjCun->parsefile($ogslfile);
    my $rootCun = $twigObjCun->root;
    $twigObjCun->purge;
    
    
    foreach my $i (@data){
	my $value = $i->{att}->{'name'};  # type name, e.g., CV, CV, etc.
	my $count = $i->{att}->{'num'};
	my @forms = $i->get_xpath('form');
	
	# still problem with letter o, because system takes it as word instead of "possibly nothing to restore"
	$totals{$value}{"total"} = $count;
	$totals{$value}{"diff_values"} = scalar @forms;
	
	foreach my $j (@forms){
	    my $formname = $j->{att}->{'name'};
	    push(@{$alldata{$value}},$formname);
	    
	    my $first = substr($formname, 0, 1);
	    
	    my $second = "";
	    if(length($value) >= 2){   # length of $value, not of $formname!
		$second = substr($formname, 1, 1);
	    }
	    my $third = "";
	    if(length($value) >= 3){   # length of $value, not of $formname!
		$third = substr($formname, 2, 1);
	    }
	    
	    my $fourth = "";
	    if(length($value) >= 4){   # length of $value, not of $formname!
		$fourth = substr($formname, 3, 2);
	    }
	    
	    if($value eq "VV"){
		$value ="CV";
		if ($first eq "i") {
		    $first = "j";
		}
	    }

# I would like to add the cuneiform code, but no luck so far.
	    my $cunhex = "";
	#    my $expr = "q{v[\@n='".$formname."']}";
	#    foreach my $cuntemp ($rootCun->findnodes($expr)) {
	#	my $parent = $cuntemp->parent();
	#	$cunhex = $parent->{'utf8'}->{att}->{hex};
	#	print Dumper($cunhex."\n");
	#    }
	    
	    
	    push(@{$restdata{$value}{$first.$second.$third.$fourth}},$formname);
	}
    }
}

