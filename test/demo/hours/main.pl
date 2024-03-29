#!perl.exe
## ctk: description Register monthly work time, main  script
## ctk: title work time
## ctk: application 'Hours' 'c:/Dokumente und Einstellungen/marco/Utilities/ClickTk/test/demo/hours'
## ctk: strict  0
## ctk: code  1
## ctk: subroutineName thisDialog
## ctk: autoExtractVariables  1
## ctk: autoExtract2Local  1
## ctk: modal 0
## ctk: isolGeom 0
## ctk: version 3.095
## ctk: onDeleteWindow  sub { 1}
## ctk: Toplevel  1
## ctk: 2006 12 03 - 18:49:19

## ctk: uselib start

use lib 'c:/Dokumente und Einstellungen/marco/Utilities/ClickTk/test/demo/hours';

## ctk: uselib end

use Tk;
use Tk::Frame;
use Tk::Label;
use Tk::Menu;
use Tk::Menubutton;
 $mw=MainWindow->new(-title=>'work time');
## ctk: Globalvars

use vars qw/ $activity1 $activity2 $debug $fName $from1 $from2 $jan1 $month $now $project $send $sheet $statusbar $to1 $to2 $typ $url $year/;

## ctk: Globalvars end
&main::init();



## ctk: code generated by ctk_w version '3.095' 
## ctk: instantiate and display widgets 

$w_Frame_001 = $mw -> Frame ( -background , '#fbfbfb' , -relief , 'raised'  ) -> pack(-side=>'top', -anchor=>'nw', -fill=>'x', -expand=>1);


$w_Menubutton_004 = $w_Frame_001 -> Menubutton ( -background , '#ffffff' , -foreground , '#000000' , -state , 'normal' , -justify , 'left' , -relief , 'raised' , -text , 'File'  ) -> pack(-side=>'left', -anchor=>'nw');


$wr_016 = $w_Frame_001 -> Menubutton ( -background , '#ffffff' , -state , 'normal' , -justify , 'left' , -text , 'Options' , -relief , 'raised'  ) -> pack(-side=>'left', -anchor=>'nw');


$wr_017 = $wr_016 -> Menu (  ); $wr_016->configure(-menu=>$wr_017);


$wr_018 = $wr_017 -> command ( -label , 'Options' , -command , \&do_options  );


$w_Menubutton_007 = $w_Frame_001 -> Menubutton ( -background , '#ffffff' , -foreground , '#000000' , -state , 'normal' , -justify , 'left' , -relief , 'raised' , -text , 'Help'  ) -> pack(-side=>'right', -anchor=>'ne');


$w_Menu_008 = $w_Menubutton_007 -> Menu ( -background , '#ffffff' , -tearoff , 0 , -relief , 'raised' , -foreground , '#000000'  ); $w_Menubutton_007->configure(-menu=>$w_Menu_008);


$w_command_009 = $w_Menu_008 -> command ( -label , 'help' , -command , \&do_help  );


$w_Menu_005 = $w_Menubutton_004 -> Menu ( -background , '#ffffff' , -foreground , '#000000' , -tearoff , 0 , -relief , 'raised'  ); $w_Menubutton_004->configure(-menu=>$w_Menu_005);


$wr_013 = $w_Menu_005 -> command ( -label , 'New sheet' , -command , \&do_newSheet  );


$wr_014 = $w_Menu_005 -> command ( -label , 'Enter hours' , -command , \&do_enterHours  );


$wr_015 = $w_Menu_005 -> command ( -label , 'save sheet' , -command , \&do_saveSheet  );


$wr_019 = $w_Menu_005 -> separator (  );


$w_command_006 = $w_Menu_005 -> command ( -label , 'Exit' , -command , \&do_exit  );


$w_Frame_003 = $mw -> Frame ( -background , '#f3f3f3' , -relief , 'flat'  ) -> pack();


$wr_020 = $w_Frame_003 -> Label ( -background , '#0000ff' , -foreground , '#ffff00' , -justify , 'left' , -text , 'Test And Demo Application ' , -relief , 'flat' , -font , [-family,Vivaldi,-size,20,-weight,bold,-slant,roman,-underline,0 ,-overstrike,0]  ) -> pack(-side=>'top', -anchor=>'nw', -pady=>10, -fill=>'both', -expand=>1, -padx=>10);


$w_Frame_002 = $mw -> Frame ( -background , '#f7f7f7' , -relief , 'ridge'  ) -> pack(-side=>'bottom', -anchor=>'sw', -fill=>'x', -expand=>1);


$w_Label_010 = $w_Frame_002 -> Label ( -anchor , 'nw' , -background , '#0080ff' , -foreground , '#ffff00' , -justify , 'left' , -relief , 'flat' , -textvariable , \$statusbar  ) -> pack(-side=>'left', -anchor=>'nw', -fill=>'x', -expand=>1);


## ctk: end of gened Tk-code


MainLoop;

## ctk: callbacks
sub init { 
	use spreadsheet;
	use csv;
	use hours;
	use cal;
	use Time::localtime;
	require "main_logic.pl";
	$year = $cal::year;
	$jan1 = $cal::jan1;
	$month = 'Januar';
	$typ ='EXCEL';
	$fName ="$month$year";
	$from1 = 9; $from2 = 13;
	$to1 = 12; $to2 = 17;
	$activity1 = 'act I';
	$activity2 ='act II';
	$statusbar = &getDateAndTime . ' ready';
	$project = 'clickTk';
	$url = 'project.accounting@eds.com';
	$send = 1;
	return 1
}
sub do_exit {
	## TODO: check if spreadsheet has been changed, and 
	##       ask user whether to save
	exit
}
sub do_help {
}
sub do_newSheet {
	print "\nnewSheet";
	return undef if defined $sheet;
	require "dlg_New.pl";
	my $ans = &newSheet($mw);
	if ($ans eq 'OK') {
		$sheet = hours->new(year => $year, month => $month);
		$sheet->generate();
	}
}
sub do_saveSheet {
	print "\nsaveSheet";
	$sheet->writeCsv(undef,$fName) if defined $sheet;
}
sub do_enterHours {
	print "\nenterHours";
	require "dlg_hours.pl";
	&enterHours($mw) if defined $sheet;
}
sub do_options {
	print "\noptions";
	require "dlg_options.pl";
	&options($mw);
}
## ctk: other code
## ctk: eof 2006 12 03 - 18:49:19
1;	## make perl compiler happy...

