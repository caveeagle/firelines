#!/usr/bin/perl

use strict;
use DBI;
use SDB::cgi;
use SDB::common;
use SDB::hash2template;
use Data::Dumper;
use HTML::TagFilter;
use Crypt::CBC;

use cave::_common qw($DB $HOST $USER $PASSWORD $SCRIPT_URL_SID $cryptkey $LINEFILE_DIR $TRAVFILE_DIR);

my $main_template = "../html/form.htm";

my $err_url = "error.png";

my $query_string =  get_query_string();
my %cgi = parse_query_string( $query_string);

my $step = $cgi{'step'} ? $cgi{'step'} : 0 ;

$step++;

my %template;
tie %template, 'SDB::hash2template', $main_template;

my $dbi = DBI->connect( "DBI:mysql:database=$DB;host=$HOST",$USER,$PASSWORD);

###################################################

my $step_form;
my $linefile = $cgi{'linefile'} ? $cgi{'linefile'} : "-" ;
my $travfile = $cgi{'travfile'} ? $cgi{'travfile'} : "-" ;

my $proj = $cgi{'proj'} ? $cgi{'proj'} : "firelines" ; # default proj = firelines

my $sid;

if($step==1)
{
	$step_form =  $template{step_1};
}
elsif($step==2)
{
    ###################################################
    
    $linefile = $cgi{'linelist'} ? $cgi{'linelist'} : "-" ;
    
    if($linefile eq "manual")
    {
		$linefile = $cgi{'line_code'}.".png";
	}	
   
    ###################################################
    
	$step_form =  $template{step_2};
	
}
elsif($step==3)
{
    ###################################################
    
    $travfile = $cgi{'travlist'} ? $cgi{'travlist'} : "-" ;

    if($travfile eq "manual")
    {
		$travfile = $cgi{'trav_code'}.".png";
	}	
    
    ###################################################

	my $drows = "";
	for(my $i=1;$i<32;$i++)
	{
	 $drows =  $drows.substitute( $template{step_3_row}, {i => $i });
    }

	my $yrows = "";
	for(my $i=2020;$i>=1950;$i--)
	{
	 $yrows =  $yrows.substitute( $template{step_3_row}, {i => $i });
    }

	$step_form =  substitute( $template{step_3}, {
	      	day_rows => $drows,
	      	year_rows => $yrows,
	    });
}
elsif($step==4)
{
    #######  Add into DB
    
	my $linefile = $LINEFILE_DIR."/".$cgi{linefile};
	my $travfile = $TRAVFILE_DIR."/".$cgi{travfile};
    
    if( (not(-e $linefile))||(not(-e $linefile)) )
    {
    	print STDERR "Not found file $cgi{linefile} or $cgi{travfile}\n";
    	$sid = -1;
    }
    else
    {
    	$sid = add_into_db();
    }	
}

#################################################

my $page;
if($step<4)
{
	$page =  substitute( $template{form}, {
	      	step_form => $step_form,
	      	step => $step,
	      	linefile => $linefile,
	      	travfile => $travfile,
	      	proj => $proj,
	    });
}
else
{
	if($sid>0)
	{
		my $HOME_LINK = "http://cave.infospace.ru/firelines/";
		
		my $img_url = substitute($SCRIPT_URL_SID,{sid=>$sid, homelink => $HOME_LINK,});
		
		my $code = "&lt;a href=$HOME_LINK&gt;&lt;img src=$img_url"."?lines.png"." &gt;&lt;/a&gt;";
	
		#my $pp_code = "\[url=$HOME_LINK\]\[img\]$img_url\[/img\]\[/url\]";
		my $pp_code = "\[url=$HOME_LINK\]\[img\]$img_url"."?lines.png"."\[/img\]\[/url\]";
	
		
		$page =  substitute( $template{result}, {
		      	img_url => $img_url."&force=1",
		      	code => $code,
		      	pp_code => $pp_code,
		    });
	}
	else
	{
		$page =  substitute( $template{error_result}, {
		      	img_url => $err_url,
		    });
	}	    
}


################################################

print_content_type;

print substitute( $template{body}, { page => $page, step => $step, } );

exit(0);

#############################################################################
#############################################################################
#############################################################################





sub add_into_db()
{
    #print STDERR Dumper (\%cgi);
    
	my $filter = new HTML::TagFilter(skip_mailto_entification => 1,);
	$filter->deny_tags({ img => { all => [] }});
    
    my $userstring = $cgi{'userstring'};

	$userstring =~ s/\\/\\\\/g ; 
	$userstring =~ s/\'/\"/g ; 
	$userstring = $filter->filter($userstring);

    my $userlogin = $cgi{'userlogin'};

	$userlogin =~ s/\\/\\\\/g ; 
	$userlogin =~ s/\'/\"/g ; 
	$userlogin = $filter->filter($userlogin);
    
    my $ltype = $cgi{'linetype'};
    
    my $insert_command = "INSERT sliders SET user='$userlogin', userstring='$userstring', project='$proj', ";
    $insert_command = $insert_command."slider_type='$ltype', ";
    
    if($ltype==0)
    {
     my $date_end = "".($cgi{'year'})."-".($cgi{'month'})."-".($cgi{'day'});
     $insert_command = $insert_command."date_end='$date_end', date_begin=NOW(), ";
    }
    elsif($ltype==1)
    {
     my $date_begin = "".($cgi{'year'})."-".($cgi{'month'})."-".($cgi{'day'});
     $insert_command = $insert_command."date_begin='$date_begin', ";
    }
    elsif($ltype==2)
    {
     my $date = "".($cgi{'month'})."-".($cgi{'day'});
     $insert_command = $insert_command."date_day='$date', ";
    }
    else
    {
    	print STDERR "Error in slider type: type=$ltype\n";
    	exit;
	}	
    
    $insert_command = $insert_command."day_night='$cgi{day_night}', string_color='$cgi{color}', back_color='$cgi{back_color}', ";
    $insert_command = $insert_command."travellerfile='$cgi{travfile}', linefile='$cgi{linefile}', ";
    $insert_command = $insert_command."create_time=NOW() ";
     
	###print STDERR "$insert_command\n";

	eval { $dbi->do($insert_command) };
	if($@)
	{
	   print STDERR "Command failed: $@\n";
	   exit;
	}
	my $insertid = $dbi->{'mysql_insertid'};
	
    ### Encrypt ID ###
	
	my $cipher = new Crypt::CBC($cryptkey,'Blowfish');
	my $crypted_block = $cipher->encrypt_hex($insertid);
	$cipher->finish();

	print STDERR "Insert ID=$insertid  key=$crypted_block \n";
	
	return $crypted_block;
}
	