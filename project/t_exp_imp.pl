#!C:\Perl\bin\perl.exe
## ctk: description 
## ctk: title 
## ctk: application 'test_import_export' 'c:/Dokumente und Einstellungen/marco/Projekte/ClickTk/test'
## ctk: strict  1
## ctk: code  0
## ctk: subroutineName thisDialog
## ctk: autoExtractVariables  1
## ctk: autoExtract2Local  1
## ctk: modal 0
## ctk: isolGeom 0
## ctk: version 3.098
## ctk: onDeleteWindow  sub{1}
## ctk: Toplevel  1
## ctk: argList -title , '???'                  
## ctk: 2007 02 19 - 01:54:41

## ctk: uselib start

use lib 'c:/Dokumente und Einstellungen/marco/Projekte/ClickTk/test';

## ctk: uselib end

use strict;
use Tk;
use Tk::Frame;
use Tk::LabEntry;
use Tk::Label;
use Tk::Listbox;
use Tk::Menu;
use Tk::Menubutton;
use Tk::Pane;
use Tk::TextEdit;
my  $mw=MainWindow->new(-title=>'');
## ctk: Globalvars
## ctk: Globalvars end
&main::init();
&main::thisDialog($mw,-title , '???'                 );
MainLoop;

sub thisDialog {
my $hwnd = shift;
my (%args) = @_;
my $rv;
##
## ctk: Localvars

my ($test);

## ctk: Localvars end
##
my $mw = $hwnd->Toplevel();
$mw->configure(-title=> (exists $args{-title})? $args{-title}:'');
$mw->protocol('WM_DELETE_WINDOW',sub{1});


## ctk: code generated by ctk_w version '3.098' 
## ctk: lexically scoped variables for widgets 

my ($wr_001,$wr_002,$wr_004,$wr_005,$wr_006,$wr_008,$wr_009,$wr_011,$wr_016,$wr_017,$wr_018 );
## ctk: instantiate and display widgets 

$wr_011 = $mw -> Pane ( -gridded , 'xy' , -sticky , 'n'  ) -> pack(-side=>'top', -anchor=>'nw');


$wr_001 = $mw -> Frame ( -relief , 'solid' , -borderwidth , 2  ) -> pack (-side=>'left', -anchor=>'nw', -fill=>'both', -expand=>1);


$wr_002 = $mw -> Frame ( -relief , 'solid' , -borderwidth , 2  ) -> pack (-side=>'left', -anchor=>'nw', -fill=>'both', -expand=>1);


$wr_004 = $wr_001 -> Listbox ( -background , '#ffffff' , -selectmode , 'single' , -relief , 'sunken'  ) -> pack(-anchor=>'nw', -side=>'top', -pady=>5, -fill=>'both', -expand=>1, -padx=>5);


$wr_009 = $wr_001 -> LabEntry ( -background , '#ffffff' , -justify , 'left' , -label , 'Options list' , -relief , 'sunken' , -labelPack , [-side , 'left' , -anchor , 'n' ] , -textvariable , \$test , -state , 'normal'  ) -> pack(-anchor=>'nw', -side=>'top', -pady=>5, -fill=>'both', -expand=>1, -padx=>5);


$wr_008 = $wr_001 -> Label ( -anchor , 'nw' , -background , '#80ffff' , -justify , 'left' , -text , 'Selection' , -relief , 'flat'  ) -> pack(-anchor=>'sw', -side=>'bottom', -pady=>5, -fill=>'x', -expand=>1, -padx=>5);


$wr_005 = $wr_002 -> TextEdit ( -wrap , 'none' , -bg , '#ffffff' , -state , 'normal'  ) -> pack(-anchor=>'nw', -side=>'top', -pady=>5, -fill=>'both', -expand=>1, -padx=>5);
$wr_005->SetGUICallbacks([]);

$wr_006 = $wr_002 -> Label ( -anchor , 'nw' , -background , '#0080ff' , -justify , 'left' , -text , 'Object name' , -relief , 'flat'  ) -> pack(-anchor=>'sw', -side=>'bottom', -fill=>'x', -expand=>1);


$wr_016 = $wr_011 -> Menubutton ( -anchor , 'nw' , -background , '#ffffff' , -state , 'normal' , -justify , 'left' , -relief , 'raised' , -text , 'File'  ) -> pack(-side=>'top', -anchor=>'nw');


$wr_017 = $wr_016 -> Menu (  ); $wr_016->configure(-menu=>$wr_017);


$wr_018 = $wr_017 -> command ( -background , '#ffffff' , -label , 'Exit' , -command , sub{exit}  );


## ctk: end of gened Tk-code


 return $rv;

} ## end of thisDialog 

## ctk: end of dialog code
## ctk: callbacks
sub init { 1 }
## ctk: other code
## ctk: eof 2007 02 19 - 01:54:41
1;	## make perl compiler happy...

