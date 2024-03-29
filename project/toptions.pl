## ctk: description Options
## ctk: title Edit Options
## ctk: application '' ''
## ctk: strict  0
## ctk: code  3
## ctk: testCode  1
## ctk: subroutineName thisDialog
## ctk: autoExtractVariables  1
## ctk: autoExtract2Local  1
## ctk: modal 0
## ctk: baseClass  Tk::Frame
## ctk: isolGeom 0
## ctk: version 4.012
## ctk: onDeleteWindow  sub{1}
## ctk: Toplevel  0
## ctk: argList
## ctk: 2008 06 02 - 16:02:51

## ctk: uselib start

## ctk: uselib end

use Tk;
 $mw=MainWindow->new(-title=>'Edit Options');


package toptions;
use vars qw($VERSION);
$VERSION = '1.01';
require Tk::Frame;
require Tk::Derived;
@toptions::ISA = qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'toptions';
## ctk: Globalvars

my ($accesMode,$delete,$exec,$http,$login,$new,$password,$pi,$priority,$read,$status,$userName,$write,@accessModes);

## ctk: Globalvars end
sub ClassInit {
	my $self = shift;
##
## 	init class
##
	$self->SUPER::ClassInit(@_);

}
sub Populate {
	my ($self,$args) = @_;
##
## ctk: Localvars
## ctk: Localvars end
## 	move args to local variables)
##
	$self->SUPER::Populate($args);
##
##
my $mw = $self;
## ctk: code generated by ctk_w version '4.012'
## ctk: instantiate and display widgets

$wr_001 = $mw -> NoteBook (  ) -> pack(-side=>'top', -anchor=>'nw', -fill=>'both', -expand=>1);


$wr_013 = $mw -> Frame ( -borderwidth , 1 , -relief , 'sunken'  ) -> pack(-side=>'top', -anchor=>'sw', -ipadx=>2, -ipady=>2, -fill=>'x', -expand=>1);


$wr_029 = $mw -> Frame ( -relief , 'solid'  ) -> pack(-side=>'bottom', -anchor=>'nw', -fill=>'both', -expand=>1);


$wr_030 = $wr_029 -> Label ( -relief , 'sunken' , -textvariable , \$status , -anchor , 'nw' , -background , '#c0c0c0' , -justify , 'left'  ) -> pack(-side=>'top', -anchor=>'nw', -fill=>'x');


$wr_002 = $wr_001 -> add ( 'wr_002', -raisecmd , sub{$status = General} , -label , 'General' , -justify , 'left' , -state , 'normal'  );


$wr_026 = $wr_001 -> add ( 'wr_026', -raisecmd , sub{$status = Communication} , -label , 'Communication' , -justify , 'left' , -state , 'normal'  );


$wr_003 = $wr_001 -> add ( 'wr_003', -raisecmd , sub{$status = Permissions} , -justify , 'left' , -label , 'Permissions' , -state , 'normal'  );


$wr_004 = $wr_001 -> add ( 'wr_004', -raisecmd , sub{$status = Operation} , -label , 'Operation' , -justify , 'left' , -state , 'normal'  );


$wr_008 = $wr_001 -> add ( 'wr_008', -anchor , 'nw' , -raisecmd , sub{$status = Security} , -justify , 'left' , -label , 'Security' , -state , 'normal'  );


$wr_014 = $wr_013 -> Button ( -background , '#ffffff' , -command , ['toptions::ok' , $self ] , -state , 'normal' , -text , 'OK' , -relief , 'raised'  ) -> pack(-side=>'left', -anchor=>'nw', -pady=>2, -fill=>'x', -expand=>1, -padx=>2);


$wr_015 = $wr_013 -> Button ( -background , '#ffffff' , -command , ['toptions::cancel' , $self ] , -state , 'normal' , -text , 'Cancel' , -relief , 'raised'  ) -> pack(-side=>'right', -anchor=>'ne', -pady=>2, -fill=>'x', -expand=>1, -padx=>2);


$wr_020 = $wr_004 -> Checkbutton ( -relief , 'flat' , -variable , \$login , -justify , 'left' , -text , 'Login required' , -onvalue , 1  ) -> grid(-sticky=>'nw');


$wr_021 = $wr_004 -> Checkbutton ( -relief , 'flat' , -variable , \$delete , -justify , 'left' , -text , 'Confirm deletions'  ) -> grid(-row=>1, -sticky=>'nw');


$wr_016 = $wr_002 -> Label ( -relief , 'flat' , -justify , 'left' , -text , 'Server name'  ) -> grid(-column=>0, -sticky=>'ne');


$wr_017 = $wr_002 -> Entry ( -justify , 'left' , -relief , 'sunken' , -textvariable , $server , -state , 'normal' , -width , 64  ) -> grid(-row=>0, -sticky=>'ne', -column=>1);


$wr_018 = $wr_002 -> Label ( -relief , 'flat' , -justify , 'left' , -text , 'Priority'  ) -> grid(-row=>1, -column=>0, -sticky=>'ne');


$wr_019 = $wr_002 -> BrowseEntry ( -choices , [qw/low medium high/ ] , -background , '#ffffff' , -justify , 'left' , -relief , 'sunken' , -variable , \$priority , -width , 20  ) -> grid(-row=>1, -column=>1, -sticky=>'nw');


$wr_005 = $wr_003 -> Checkbutton ( -relief , 'flat' , -variable , \$read , -anchor , 'nw' , -justify , 'left' , -text , 'Read' , -onvalue , 1  ) -> grid(-row=>0, -sticky=>'nw', -column=>0);


$wr_006 = $wr_003 -> Checkbutton ( -relief , 'flat' , -variable , \$write , -justify , 'left' , -text , 'Write' , -onvalue , 1  ) -> grid(-row=>1, -column=>0, -sticky=>'nw');


$wr_007 = $wr_003 -> Checkbutton ( -relief , 'flat' , -variable , \$exec , -justify , 'left' , -text , 'Execute'  ) -> grid(-row=>2, -column=>0);


$wr_009 = $wr_008 -> Label ( -relief , 'flat' , -justify , 'left' , -text , 'User name'  ) -> grid(-row=>0, -pady=>5, -column=>0, -sticky=>'ne');


$wr_010 = $wr_008 -> Entry ( -background , '#ffffff' , -justify , 'left' , -relief , 'sunken' , -textvariable , \$userName , -width , 20 , -state , 'normal'  ) -> grid(-row=>0, -pady=>5, -column=>1, -sticky=>'ne');


$wr_011 = $wr_008 -> Label ( -relief , 'flat' , -anchor , 'nw' , -justify , 'left' , -text , 'Password'  ) -> grid(-row=>2, -pady=>5, -column=>0, -sticky=>'ne');


$wr_012 = $wr_008 -> Entry ( -background , '#ffffff' , -justify , 'left' , -relief , 'sunken' , -textvariable , \$password , -state , 'normal' , -width , 20  ) -> grid(-row=>2, -pady=>5, -column=>1, -sticky=>'ne');


$wr_022 = $wr_004 -> Checkbutton ( -relief , 'flat' , -variable , \$new , -justify , 'left' , -text , 'Allow new items' , -onvalue , 1  ) -> grid(-row=>2, -sticky=>'nw', -column=>0);


$wr_023 = $wr_004 -> Checkbutton ( -relief , 'flat' , -variable , \$pi , -justify , 'left' , -text , 'Force program isolation'  ) -> grid(-row=>3, -sticky=>'nw', -column=>0);


$wr_024 = $wr_004 -> Checkbutton ( -relief , 'flat' , -justify , 'left' , -text , 'Trace traffic' , -onvalue , 1  ) -> grid(-sticky=>'nw');


$wr_025 = $wr_026 -> LabEntry ( -background , '#ffffff' , -label , 'Proxy ' , -labelPack , [-side , 'left' , -anchor , 'nw' ] , -justify , 'left' , -relief , 'sunken' , -textvariable , $proxy  ) -> grid(-row=>0, -pady=>5, -padx=>5, -column=>0, -sticky=>'ne');


$wr_028 = $wr_026 -> LabEntry ( -background , '#ffffff' , -label , 'Port number' , -labelPack , [-side , 'left' , -anchor , 'nw' ] , -justify , 'left' , -relief , 'sunken'  ) -> grid(-row=>1, -pady=>5, -padx=>5, -column=>0, -sticky=>'ne');


$wr_031 = $wr_026 -> LabEntry ( -background , '#ffffff' , -label , 'Hypertext protocol' , -labelPack , [-side , 'left' ] , -justify , 'left' , -relief , 'sunken' , -textvariable , \$http  ) -> grid(-row=>3, -pady=>5, -padx=>5, -column=>0, -sticky=>'ne');


$wr_032 = $wr_002 -> Label ( -relief , 'flat' , -justify , 'left' , -text , 'Mode'  ) -> grid(-row=>2, -column=>0, -sticky=>'ne');


$wr_034 = $wr_002 -> BrowseEntry ( -choices , \@accessModes , -background , '#ffffff' , -justify , 'left' , -relief , 'sunken' , -variable , \$accesMode , -width , 20  ) -> grid(-row=>2, -column=>1, -sticky=>'nw');


## ctk: end of gened Tk-code

## ctk: public subwidgets
$self->Advertise('server'=>$wr_017);
## ctk: public subwidgets end
## ctk: ConfigSpecs
	$self->ConfigSpecs(
		'-flag'=>['PASSIVE','flag','flag','flag-value'],
		'-status'=>['METHOD','state','state','normal'],
		'-title'=>['METHOD','title','title','toptions unit test'],
	);
## ctk: ConfigSpecs end
## ctk: Delegates
	$self->Delegates(
		'cancel' => $self,
		'ok' => $self,
	);
## ctk: Delegates end
	return $self;
}
## ctk: methods
sub CreateArgs {
	my ($self, $parent, $args) = @_;
	my @newArgs;
	@newArgs = $self->SUPER::CreateArgs($parent, $args);
	return @newArgs;
}
sub ok {
	my $self = shift;
	$self->DESTROY();
}
sub cancel {
	my $self = shift;
	$self->toplevel->DESTROY();
}
sub title {
	my $self = shift;
	$self->toplevel->configure(-title => $_[0]);
}
sub status {
	print "\nstatus @_"
}
## ctk: methods end

## ctk: testCode
# -----------------------------------------------
##
package main;
&main::init();
my (%args) =();
my $instance = $mw->toptions(%args)->pack();
&main::test_1($instance);
MainLoop;
##
## ctk: testCode end

## ctk: callbacks
sub init {
	$status = 'Ready';
	$http = 'https';
	@accessModes =(qw(NFS FS RPC TCP/IP));
 }
sub test_1 {
	my $mw = shift;
	$mw->configure(-title => 'toptions test OK.');
	$mw->Subwidget('server')->insert('end','www.clicktk.eu');
	print "\n", $mw->{Configure}{-flag};
}
## ctk: other code
## ctk: eof 2008 06 02 - 16:02:51
1;	## make perl compiler happy...

