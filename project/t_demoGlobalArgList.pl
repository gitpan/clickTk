#!C:\Perl\bin\perl.exe
## ctk: description Demo global Args
## ctk: title Demo subroutine arg list
## ctk: application '' ''
## ctk: strict  0
## ctk: code  0
## ctk: subroutineName useglobalArgList
## ctk: argList ''
## ctk: autoExtractVariables  1
## ctk: autoExtract2Local  0
## ctk: modal 1
## ctk: isolGeom 0
## ctk: version 3.096
## ctk: onDeleteWindow  sub{1}
## ctk: Toplevel  1
## ctk: argList 
## ctk: 2006 12 18 - 22:08:02

## ctk: uselib start

## ctk: uselib end

use Tk;
use Tk::Label;
 $mw=MainWindow->new(-title=>'Demo subroutine arg list');
## ctk: Globalvars

use vars qw/%args/;

## ctk: Globalvars end
&main::init();
my $answer = &main::useglobalArgList($mw);
print "\nanswer = '$answer'";
MainLoop;

sub useglobalArgList {
my $hwnd = shift;
my $rv;
##
## ctk: Localvars
## ctk: Localvars end
##
my $mw = $hwnd->DialogBox(
	-title=> (exists $args{-title})? $args{-title}:'Demo subroutine arg list',
	 -buttons=> (exists $args{-buttons}) ? $args{-buttons} : ['OK','Cancel']);
$mw->protocol('WM_DELETE_WINDOW',sub{1});


## ctk: code generated by ctk_w version '3.096' 
## ctk: instantiate and display widgets 

$wr_001 = $mw -> Label ( -anchor , 'nw' , -justify , 'left' , -relief , 'flat' , -text , $args{-labeltext} , -font , $args{-font}  ) -> pack();


## ctk: end of gened Tk-code

$rv =  $mw->Show();

 return $rv;

} ## end of useglobalArgList 

## ctk: end of dialog code
## ctk: callbacks
sub init { 
%args = (-title , 'Demo global argList',
 -labeltext => 'demo ArgList',
 -font => [-family,'Bradley Hand ITC',-size,16,-weight,'bold',-slant,'roman',-underline,0 ,-overstrike,0])
 }
## ctk: other code
## ctk: eof 2006 12 18 - 22:08:02
1;	## make perl compiler happy...

