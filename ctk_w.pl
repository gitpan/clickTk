#!/usr/bin/perl -w
##                  -d:ptkdb

=pod

=head1 ctk_w.pl

	ClickTk main module.

=head2 Programming notes

=over

=item Maintenance

	See clickTk_maintenance.html for details about maintenance history.

=back

=cut

use lib './lib';

use strict;
use Tk 800;

use Time::localtime;
use Getopt::Std;
use Cwd;
use File::Spec;

use Tk::DialogBox;
use Tk::Photo;
use Tk::Checkbutton;
use Tk::Balloon;
use Tk::Adjuster;
use Tk::LabFrame;
use Tk::LabEntry;
use Tk::BrowseEntry;
use Tk::NoteBook;
use Tk::HList;
use Tk::FileSelect;
use Tk::Tiler;
use Tk::ROText;
use Tk::TextUndo;
use Tk::TextEdit;
use Tk::Dialog;
use Tk::ColorEditor;
use Tk::Compound;
use Tk::Message;

use Tk::ItemStyle;

use Tk::ErrorDialog;

use ctkCommon;
use ctkBase 1.04;
use ctkOptions 1.02;
use ctkMenu 1.03;
use ctkFile 1.05;
use ctkSession 1.02;
use ctkProject 1.03;
use ctkWork 1.02;
use ctkTemplate 1.01;
use ctkApplication 1.02;
use ctkPreview 1.01;
use TkAnalysis 1.04;
use ctkWidgetLib 1.10;
use ctkNumEntry 1.01;
use ctkDialogBox 1.02;
use ctkDialogs 1.08;
use ctkParser 1.04;
use ctkWidgetOption 1.01;
use ctkDescriptor 1.01;
use ctkFontDialog 1.02;
use ctkHelp 1.05;
use ctkAssistent 1.06;
use ctkAssistentModal 1.01;
use ctkDirDialog 1.01;
use ctkStatusbar 1.02;
use ctkClipboard 1.01;
use ctkCallback 1.01;
use ctkUndoStack 1.02;

use ctkTargetCode 1.02;
use ctkTargetScript 1.01;
use ctkTargetSub 1.01;
use ctkTargetPackage 1.01;
use ctkTargetComposite 1.02;
use ctkDlgGetCode 1.05;
use ctkTools 1.03;
use ctkWidgetTreeView 1.02;
use ctkImages 1.01;
use ctkDlgGetLibraries 1.01;
use ctkDlgConfigSpec 1.01;
use ctkDlgDelegate 1.01;

require Data::Dumper;

our $VERSION = 4.013;

our $debug = 0;

## options

our $OPTIONS = ctkOptions->new(restore => 1, debug => $debug);

my $ctkTitle;
our $ctkLogFileName ;	## clickTk log file name (used in v.bat to save STDOUT)

my $opt_fileHistory;	## keep the file name of the last x open files
my $opt_autoSave;		## automatically save on Debug, execute, edit
my $opt_coldstart;		## do a coldstart
our $opt_isolate_geom ;		## 1 : generate separated statements for geometry calls

my $defaultGeometryManager; ## default geometry manager for all widget which may use that manager.

our $geomMgr;			## supported geometry managers

our $opt_askIdent;		## 1 : ask user for widget ident
our $opt_colorPicker;	## 1 : use specialized color dialog; 0 : use Tk standard

our $opt_modalDialog;	## 1: set modal mode
our $opt_TestCode ;		## 1: gen additional test code to run composite/package/subroutine

our $MW ='mw';			## variable name of the main window widget


our $opt_autoRestore;	## 1: restore given file (see option -r)

our $opt_copyChildren ;	## 1: copy selected widget and all its children
						## 0: copy only selected widget.

our $HListSelectMode ;	## browse eq single ; extended -> errors (17.10.2005)

our $autoEdit ;			## automatically call edit_widgetOptions on insert

our $identPrefix ;		## prefix for widget variable name (ident) "w_${type}_";

our $popupmenuTearoff  ;	## tearoff option of popup menu for widgets.

our $opt_defaultButtons;		## default list of buttons for modal dialog

my $MSWin32_editor ;	##  editor
my $aix_editor;			##  editor
my $solaris_editor;		##  editor
my $UNIX_editor ;		##  editor
my $linux_editor ;		##  editor

my $MSWin32_explorer;
my $UNIX_explorer;
my $linux_explorer ;

my $xterm ;				##  terminal session

our $tempFolder ;
our $templateFolder;
our $toolbarFolder ;
our $imageFolder;
our $widgetFolder;

my $sessionFileNamePrefix ;

my $initialGeometry;
my $initialGeometryPreview;

our $HListDefaultHeight ; 	## [chars]
our $HListDefaultWidth ; 	## [chars]

our $ctkC;

our $editingCodeProperties;

our $userid;		## user ident

our @cacheLog = ();
our $cacheLogSize = 2048;

our ($myPath,$perlInterp);

map {
	eval "\$$_ = \$OPTIONS->get(\'$_\')";
	main::Log("Invalid option '$_','$@', default applied.") if ($@)
} keys %{$OPTIONS->options};

## global variables

my $FS = 'ctkFile'->FS;		##  file separator

ctkTools->curEditor(-win =>$MSWin32_editor,-aix =>$aix_editor,-solaris =>$UNIX_editor ,-linux => $linux_editor, -unix =>$UNIX_editor);
ctkTools->curExplorer(-win =>$MSWin32_explorer,-aix =>$UNIX_explorer,-solaris => $UNIX_explorer,-linux => $linux_explorer,-unix =>$UNIX_explorer);
ctkTools->autoSave($opt_autoSave);
ctkTools->xterm($xterm);
($myPath,$perlInterp) = &main::getPerl();


BEGIN
{
	print"\nrunning on '$^O'\n";
}

END {
	print"\n$0 ended",' ';
}

## ---------------------------------------------------
## state machine
## ---------------------------------------------------


my $programState = SM_STARTING;

## global variables

my $selected;           # Currently selected widget path
## my %widgets=();         # Tk widgets pointers for highlight
my $hiddenWidgets = []; # list of the hidden widgets

our $projectName = ctkProject->noname;    # last project-name used in Open/Save
my %cnf_dlg_ballon;   # Help messages for all widget configuration options
my (%file_opt) = ctkProject->empty_file_opt();

our ($view_balloons,$view_blink,)=(1,0);

my @baseClass = ();

our $previousFiles = [];

our $workWidget = ctkWidgetLib->new(widgetlib => $widgetFolder);

my $session;					## session instance

our $help = ctkHelp->new(tempFolder => $tempFolder, debug => $debug);

&main::Log("$0 starting under '$^O'");

die "$0 installation error: project folder not found!\n"
	unless (ctkProject->existsFolder($myPath));
die "$0 installation error: directory $myPath$FS$imageFolder not found!\n"
	unless (-d "$myPath$FS$imageFolder");
die "$0 installation error: directory $myPath$FS$toolbarFolder not found!\n"
	unless (-d "$myPath$FS$toolbarFolder");
die "$0 installation error: directory $myPath$FS$templateFolder not found!\n"
	unless (-d "$myPath$FS$templateFolder");
die "$0 installation error: work folder not found!\n"
	unless (ctkWork->existsFolder($myPath));
die "$0 installation error: directory $myPath$FS$widgetFolder not found!\n"
	unless (-d "$myPath$FS$widgetFolder");

mkdir $tempFolder unless(-d $tempFolder);
my %cmdLineOpt=();

# 1. Set up run time environment

## 1.1 set up main window

our $mw = MainWindow->new(-title=>&std::_title($VERSION));
	$mw->geometry($initialGeometry) if ($initialGeometry);

## 1.2 check OS

if ($^O !~ /mswin|solaris|linux/i) {	## show disclaimer
	&std::ShowWarningDialog("clickTk '$VERSION' has been tested only on Windows and on sun solaris systems.");
} else {}

# 1.3 parse command line options

&main::parseCmdLineOpt(\%cmdLineOpt);
ctkBase->debug($debug);

# 1.4 restore session

&main::session_restore($userid,$sessionFileNamePrefix) unless ($opt_coldstart);

# 1.5 parse command line file

&main::parseFileOption;

&main::Log("Version '$VERSION'");

# 1.6 Load widget's class definition

my $w_attr ={};
$w_attr = $workWidget->loadAll();

# 1.7 Set up error handler

## TODO Error handling : Tk::Error($TkError,"message",tracebackMessages);

my $TkError = $mw->ErrorDialog(-cleanupcode => sub{main::TkErrorCleanUp(@_)}, -appendtraceback => 1);

my $mwPalette = $mw->Palette;
my $palette = [
	{-background=>'gray90',-foreground=>'black',},
	{-background=>'gray90',-foreground=>'black'},
	{-background=>'white',-foreground=>'black',-widgetClass => [qw(Text Button LabEntry Entry)]}
	];

# 1.7 Set up some graphic elements

$mw->fontCreate('C_bold',qw/-family courier -weight bold  -size 10/);
$mw->fontCreate('C_normal',qw/-family courier -weight normal -size 10/);

my $pic = &main::loadImages("$myPath$FS$imageFolder");
my $picT = &main::loadImages("$myPath$FS$toolbarFolder");
my $picW = &main::loadImages("$myPath$FS$widgetFolder");

&main::Log("Could not load images.") unless(defined($pic) && defined($picT) && defined ($picW));

die "Could not load mandatory images." unless (scalar(keys %$pic) && scalar(keys %$picT) && scalar(keys %$picW));

die "Could not load mandatory default image." unless (exists $picW->{default});

&main::load_cnf_dlg_ballon(); 		# Load balloon messages

# 1.8 Set up main window (menu, toolbar, ...)

our $top_frame     = $mw->Frame();
our $bottom_frame  = $mw->Frame();

	$top_frame->pack(-side=> 'top',-anchor=> 'nw',-expand=>1,-fill => 'x');
	$bottom_frame->pack(-side=> 'top',-anchor=> 'nw',-expand=>1,-fill => 'both');

my $menubar       = $top_frame->Frame(-borderwidth => 2,-relief => 'sunken')->pack(-side => 'top', -anchor => 'nw',-expand => 1, -fill => 'x');
my $toolbar_frame = $top_frame->Frame(-borderwidth => 1,-relief => 'sunken')->pack(-side=>'top',-anchor=>'nw',-expand => 1,-fill => 'x');


our $main_frame    = $bottom_frame->Frame(-borderwidth => 1,-relief => 'sunken')->pack(-side=>'top',-anchor=>'nw',-expand=>1,-fill=>'both',-pady => 10);
our $wHlist        = $main_frame->Frame()->pack(-side => 'top',-anchor => 'nw',-expand => 1,-fill => 'both');
our $status_frame  = $bottom_frame->Frame(-borderwidth => 1,-relief=>'sunken')->pack(-side=>'bottom',-anchor=>'sw',-fill=>'x',-expand => 1);

my $aMenu = ctkMenu->setupMenu($menubar);
## my $aMenuInitState = ctkMenu->saveMenuInitState($aMenu);

our $popup = ctkMenu->setupPopupMenu($mw) ;		# pop-up menu on right button

our $statusbar = $status_frame->ctkStatusbar()->pack(-side, 'left', -anchor , 'nw', -expand , 1, -fill, 'x');

&main::changes(0);

our $b = &main::setupBallon($mw);

ctkMenu->setupToolbar ($toolbar_frame,$b,$picT);

my $tf = ctkWidgetTreeView->setup ($wHlist,$MW,$picW);

ctkMenu->setupBindings ($mw);

$mw->protocol('WM_DELETE_WINDOW',\&main::abandon);

$SIG{INT}  = \&main::abandon;
$SIG{TERM} = \&main::abandon;
$SIG{HUP}  = \&main::abandon;

$mw->SelectionOwn(-selection=>'CLIPBOARD');

# 1.9 Initialize project

&main::file_init();

$main::projectName = ctkProject->name($cmdLineOpt{'file'}) if (exists $cmdLineOpt{'file'});

if ($opt_autoRestore) {
		unless(&work_restore(1)) {
			my $reply = &std::ShowDialogBox(-bitmap=>'question',
						-title=>'Missing work.',
						-text=> "Work '$main::projectName' do not exist,\ncontinue anyway?",
						-buttons=>['Continue','Cancel']);
			exit(1) if ($reply =~ /Cancel/);
			&main::work_restore(0);
		}
} else {
	if ($main::projectName ne ctkProject->noname) {
		if (-f ctkProject->fileName($main::projectName)) {
			&main::updateFileHistory($main::projectName);
			&main::file_read(ctkProject->fileName($main::projectName));
			&main::preview_repaint();
			&main::extractAndAssignVariables();
			&main::work_save();
		} else {
			my $reply = &std::ShowDialogBox(-bitmap=>'question',
						-title=>'Missing project.',
						-text=> "Project '$main::projectName' do not exist,\ncontinue anyway?",
						-buttons=>['Continue','Cancel']);
			exit(1) if ($reply =~ /Cancel/);
			if ($reply =~ /Continue/) {
				$main::projectName = ctkProject->noname unless (&main::file_open(ctkProject->fileName('*.pl')));
			} else {
				$main::projectName = ctkProject->noname; ## exit via system menu ?
			}
	}
	} else {
		## &main::preview_repaint; # force repaint!
	}
}

# 1.10 Start main loop .

&main::set_selected($MW);

&main::trace("Starting MainLoop");

ctkMenu->updateMenu();

MainLoop;

&main::Log("Something went really bad, pls check your PERL/Tk environment.");
exit(9999);

=head2 General subroutines

	getPerl
	getmw
	getMW
	getImageFolder
	get_picW
	getDescriptor
	getTree
	getW_attr
	getSelected
	selectedWidget
	selectedIsMW

	getFile_opt

	ctkTitle
	getGlobalVariables

	index_of
	getType
	haveGeometry
	nonVisual
	set_selected

=cut

sub getPerl {
	my ($path,$perl);
	$path=$0;
	$path=~s/[^\/\\]+$//;
	$path='.' unless $path;
	unshift (@INC,$path);
	foreach($^X, '/usr/intel/bin/perl', '/usr/local/bin/perl') {
		if (-f $_){
			$perl = $_;
			last;
		}
	}
	$perl = 'perl.exe' unless defined $perl;
	&main::log("$path , $perl");
	return ($path,$perl)
}

sub getmw { return $mw }

sub getMW { return $MW }

sub getImageFolder { return $imageFolder }

sub get_picW { return $picW }

sub getDescriptor { return \%ctkProject::descriptor }

sub getTree { return wantarray ? @ctkProject::tree : \@ctkProject::tree }

sub getW_attr { return $w_attr }

sub getWidgets { return \%ctkPreview::widgets }

sub getSelected {
	return $selected
}

sub selectedWidget {
	my $rv;
	my $_sel = &main::getSelected;
	$rv = $ctkPreview::widgets{$_sel} if (exists $ctkPreview::widgets{$_sel});
	return $rv
}

sub selectedIsMW {
	my $rv = &main::getSelected eq &main::getMW;
	return $rv
}

sub set_selected {
	return undef unless(@_);
	$selected = shift @_ if (@_);
	&main::trace("set_selected  '$selected'");

	$statusbar->Subwidget('message')->configure(-text=>'Selected: '.&main::getSelected);
	# highlight respective object:
	return undef unless (&main::selectedWidget);

	ctkWidgetTreeView->setSelected();

	return &main::getSelected unless $main::view_blink; # return here if no blink  ## u MO3605
	return &main::getSelected unless &main::haveGeometry(ctkProject->descriptor->{&main::path_to_id()}->type);

	&main::doBlink();

	return &main::getSelected;
}

sub getFile_opt {
	return \%file_opt
}

sub ctkTitle { return $ctkTitle }

sub getGlobalVariables {
	return wantarray ? @ctkProject::user_auto_vars : \@ctkProject::user_auto_vars;
}

sub getNoname {
	die "obsolete sub called"
}

sub index_of {
	return ctkProject->index_of(@_);
}

sub getType {
	return ctkProject->getType(@_);
}

sub haveGeometry { 		# those widgets placed without geometry manager
	my $type = shift;
	my $rv;
	if (defined($type)){
		&main::trace("haveGeometry ('$type')");
		$rv = $w_attr->{$type}->{'geom'};
	} else {
		if (defined(&main::getSelected)) {
			$type = &main::getType;
			&main::trace("haveGeometry ('&main::getSelected') '$type'");
			$rv= $w_attr->{$type}->{'geom'};
		} else {
			&std::ShowErrorDialog("'haveGeometry' is missing args type and selected.\nProcess goes on with 'UNDEF', but data may be corrupted.");
		}
	}
	&main::trace("rv = '$rv'");
	return $rv
}

sub nonVisual {
	my $type = shift;
	my $rv = 0;
	if (defined($type)){
		&main::trace("nonVisual ('$type')");
		$rv = $w_attr->{$type}->{'nonVisual'} if(exists $w_attr->{$type});
		$rv = 0 unless defined $rv;
	} else {
		if (defined(&main::getSelected)) {
			$type = &main::getType;
			&main::trace("nonVisual ('".&main::getSelected."') '$type'");
			$rv= $w_attr->{$type}->{'nonVisual'};
		} else {
			&std::ShowErrorDialog("'nonVisual' is missing args type and selected.\nProcess goes on with 'UNDEF', but data may be corrupted.");
		}
	}
	&main::trace("rv = '$rv'");
	return $rv
}

=head3 getDumpArguments

	Return the argument to dump data to the work instance.

=cut

sub getDumpArguments {
	my @rv =();
	push @rv ,[\%ctkProject::descriptor, \@ctkProject::tree, \@ctkProject::user_subroutines,\@ctkProject::user_methods_code,  \@ctkProject::user_gcode, \@ctkProject::other_code, \@ctkProject::user_pod, \@ctkProject::user_auto_vars,\@ctkProject::user_local_vars, \%file_opt, \$main::projectName, \$opt_isolate_geom,$hiddenWidgets,\@ctkProject::libraries,\$ctkApplication::applName,\$ctkApplication::applFolder,\$opt_TestCode,\@ctkProject::baseClass];
	push @rv,['rDescriptor','rTree','rUser_subroutines','rUser_methods_code','rUser_gcode','rOther_code','rUser_pod','rUser_auto_vars','rUser_local_vars','rFile_opt','rProjectName','ropt_isolate_geom','rHiddenWidgets','rLibraries','rApplName','rApplFolder','opt_TestCode','rBaseClass'];
	return wantarray ? @rv : \@rv;
}

=head3 computeState

	Compute the program state to update the menu.

=cut

sub computeState {
	my $rv = 0;
	&main::trace("computeState");
	if ($main::projectName =~ /\S+/ && $main::projectName ne  ctkProject->noname) {
		$rv = SM_WORKING ;
		$rv += SM_CHANGED if(&main::isChanged);
		$rv += SM_UNDO if (ctkUndoStack->undoAvail);
		$rv += SM_REDO if (ctkUndoStack->redoAvail);
		$rv += SM_PASTE if (ctkClipboard->clipboard > 1);

	} elsif ($main::projectName =~ /\S+/ && $main::projectName eq  ctkProject->noname) {
		$rv = SM_WORKING ;
		$rv += SM_CHANGED if(&main::isChanged);
		$rv += SM_UNDO if (ctkUndoStack->undoAvail);
		$rv += SM_REDO if (ctkUndoStack->redoAvail);
		$rv += SM_PASTE if (ctkClipboard->clipboard > 1);
	} else {
		$rv = SM_WAITING
	}
	$rv += &main::computeEditTreeState if ($rv & SM_WORKING);
	&main::trace("program state = '$rv' = ".ctkMenu->symbolics($rv));
	return $rv;
}

=head3 computeEditTreeState

	- ischanged               rv += 01  undo,redo normal
	- clipboard data                02  paste normal
	- !selectedIsMW                 04  options,Copy,delete,rename,replace disabled
	- selected is not Hidden        08  hide normal
	- selected is hidden            16  unhide normal
	- hasGeometry                   32  view geometryInfo normal

	-at least one must match       128
	- always                       256

=cut


sub computeEditTreeState {
	my $rv = 0;
	&main::trace("computeEditTreeState");
	return $rv unless (&main::getSelected);
	$rv +=  SM_ET_CHANGED   if (&main::isChanged());
	$rv +=  SM_ET_CLIPBOARD if (ctkClipboard->clipboard > 1);
	$rv +=  SM_ET_NOTMW     if (!&main::selectedIsMW);
	$rv +=  SM_ET_NOTHIDDEN if (!&main::isHidden);
	$rv +=  SM_ET_HIDDEN    if (&main::isHidden);
	$rv +=  SM_ET_HAVEGEOM  if (&main::haveGeometry);

	&main::trace("edit tree state ='". ctkMenu->symbolics($rv)."'");
	return $rv;
}

=head3 parseCmdLineOpt

	Parse the line command options and
	set the globals accordingly.

=cut

sub parseCmdLineOpt {
	my ($cmdLineOpt) = @_;
	&main::trace("parseCmdLineOpt");

	getopts('dh?crtu:',$cmdLineOpt);

	if ($cmdLineOpt{'h'} || $cmdLineOpt{'?'}) {
		if ($^O =~ /^mswin/i) {
			## system "perldoc.bat $0"
			&main::help();
		} else {
			system "perldoc $0";
		}
		exit 1;
	}
	if (exists $cmdLineOpt{'d'}){
		$debug = 1;
		&main::Log("debug mode is ON");
	}

	if (exists $cmdLineOpt{'r'}) {
		$opt_autoRestore = 1;
		&main::Log("Option autorestore is on");
	}
	if (exists $cmdLineOpt{'t'}) {
		$ctkPreview::opt_useToplevel = 1;
		$initialGeometry                    = '=500x500+10+10';
		$ctkPreview::initialGeometryPreview = '=500x500+420+10';
		&main::Log("Option useToplevel is ON");
	}

	if (exists $cmdLineOpt{'u'}) {
		$userid = $cmdLineOpt{'u'};
		&main::Log("Userid is '$userid'");
	}
	if (exists $cmdLineOpt{'c'}) {
		&main::Log("Cold start requested");
		$opt_coldstart = 1;
		$main::projectName = ctkProject->noname;
		$opt_autoRestore = 0;
	}
	return 1
}

=head3 parseFileOption

	Parse the line command option files

=cut

sub parseFileOption {

	&main::trace("parseFileOption");
	return 0 if ($opt_coldstart) ;
	if (@ARGV == 1) {
		my $file = $ARGV[0];
		$file .= '.pl' unless($file =~ /\.pl$/);
		if ($opt_autoRestore) {
			if (-f ctkWork->fileName($file)) {
				$cmdLineOpt{'file'} = $file;
				&main::Log("Processing work '$file'");
			} else {
				&main::Log("Work '$file' does not exist, ask user to know what next");
				$cmdLineOpt{'file'} = $file;
			}
		} else {
			if (-f ctkProject->fileName($file)) {
				$cmdLineOpt{'file'} = $file;
				&main::Log("Processing project '$file'");
			} else {
				&main::Log("Project '$file' does not exist, discarded");
				$cmdLineOpt{'file'} = $file;
			}
		}
	} elsif (@ARGV > 1) {
		&main::Log("Too many projects specified, all discarded ");
		$cmdLineOpt{'file'} = ctkProject->noname;
	} else {
		$cmdLineOpt{'file'} = $main::projectName;
	}
	return 1
}


=head3 setApplication

	Get application name and application folder

=cut

sub setApplication {
	&main::trace("setApplication");
	ctkApplication->setApplication(@_);
	return undef;
	my ($w1,$w2) = ($ctkApplication::applName,$ctkApplication::applFolder);
	$w2 =~ s/[\\\/]/$FS/g;
	if (&std::dlg_getApplicationParms(&main::getmw(),\$w1,\$w2)) {
		($ctkApplication::applName,$ctkApplication::applFolder) = ($w1,$w2);
		$ctkApplication::applFolder =~ s/[\\\/]/\//g;		## must be unix like
		&main::changes(1);
	}
}

=head3 setupBallon

	Set up an intance of type Balloon.

	Arguments:

		- parent widget (delaut main::getmw())

	Return

		Ref to widget

=cut

sub setupBallon {
	my ($parent) = @_ ;
	my $rv;
	&main::trace("setupBallon");
	$parent = getmw() unless (defined $parent );

	$rv = $parent->Balloon(-background=>'#CCFFFF',-initwait=>550);

	return $rv
}

=head3 loadImages

=cut

sub loadImages { return ctkImages->loadAll(@_) }

=head3 recolorMySelf

	Get fg an bg color and apply them to all defined widgets.

		get current values using message $mw->Palette
		get color for -bg and -fg
		set defualt values if required
		reset to default colors
		recolr all widget of the widget tree
		repaint preview

=cut

sub recolorMySelf {
	&main::trace("recolorMySelf");
	my $mw = main::getmw;
	my ($bg_color,$fg_color)=qw/gray90 black/;
	my $mwPalette = $mw->Palette;
	$bg_color=$mwPalette->{'background'} if(exists $mwPalette->{'background'});
	$fg_color=$mwPalette->{'foreground'} if(exists $mwPalette->{'foreground'});

	my $reply = std::dlg_recolorMySelf($mw,\$bg_color,\$fg_color);
	return if ($reply =~ /Dismiss/i);
	($bg_color,$fg_color)=(qw/gray90 black/) if($reply eq 'Default');

	&resetToDefault($mw);		## reset to default first, because of RecolorTree!

	my %new = (background=>$bg_color,foreground=>$fg_color);

	$mw->RecolorTree(\%new);	## Note: this message apply only to widgets that actually apply default options values for -fg and -bg

	map {
		my $p = $_;
		map {
			$p->{"-$_"} = $new{$_}
		} keys %new;
	} @$palette;
	&main::preview_repaint(); # force repaint!
}

=head3 _resetToDefault

	get default options of -fg and -bg
	apply the options to the given widget
	apply to all children descending the widget tree

=cut

sub _resetToDefault {
	my ($w) = @_;
	$w = main::getmw unless defined $w;
	my $palette = $w->Palette;
	my $fg = $palette->{foreground};
	my $bg = $palette->{background};
	my @opt = $w->configure();
	$w->configure (-foreground, $fg) if (grep $_->[0] =~ /foreground/, @opt);
	$w->configure (-background, $bg) if (grep $_->[0] =~ /background/, @opt);
	foreach ($w->children) {
			&main::_resetToDefault($_);
	}
}

=head3 resetToDefault

	reset the default option starting at main window
	repaint the preview

=cut

sub resetToDefault {
	_resetToDefault(&main::getmw);
	&main::preview_repaint; # force repaint!
}

=head3 pickColor

	See module ctkDialogs

=cut

sub pickColor { return std::pickColor(@_) }

=head3 ColorPicker

	See module ctkDialogs

=cut

sub ColorPicker { &std::ColorPicker(@_)}

=head3 color_Picker

	See module ctkDialogs

=cut

sub color_Picker {
	&std::color_Picker(@_);
	return 1;
}

=head2 method of meni item tools

=head3 tools_edit

	See ctkTools::_edit.

=cut

sub tools_edit { ctkTools->_edit() }

=head3 tools_syntax

	See ctkTools::_syntax.

=cut

sub tools_syntax { ctkTools->_syntax() }

=head3 tools_run

	See ctkTools::_run.

=cut

sub tools_run { ctkTools->_run()}

=head3 tools_cursor

=cut

sub tools_cursor {
	&main::trace("tools_cursor");
	require "selectCursor.pl";
	my $cursor = &std::dlg_selectCursor(&main::getmw,-text => undef);
}

=head3 tools_genFontCode

=cut

sub tools_genFontCode {
	&main::trace("tools_genFontCode");
	require ctkFontDialog;
	my $font = main::getmw->ctkFontDialog(-title => 'Font constructor', -gen => 'configure');
}

=head3 fontExists

=cut

sub fontExists {
	return &std::fontExists(@_)
}

=head2 Tk::Error

=cut

sub Tk::Error {
	my ($widget,$error,@locations) = @_;
	&main::trace("Tk::Error");

	&main::Log ("DEBUG: widget '$widget'", "error '$error'"," from ", @locations);
	main::TkErrorCleanUp($widget);
}

=head3 TkErrorCleanUp

=cut

sub TkErrorCleanUp {
	my ($widget) = @_;


## TODO
## exit process if inError is ON
## set inError to ON
## save debug info
## if changed()
## then do
##   roll back last change
##   save the work as $projectname_rescue.pl
##   end
## else
##   set inError OFF
##   return to caller
}

=head3 clear_preview

=cut

sub clear_preview {
	&main::trace("clear_preview");
	ctkPreview->clear()
}

=head3 initPreview

=cut

sub initPreview {
	&main::trace("initPreview");
	ctkPreview->init;
}

=head3 preview_repaint

=cut

sub preview_repaint {
	return ctkPreview->repaint();
}

sub edit_indicators {
	my ($txt,$lLineCol,$lSize,$lMode,$lChanged,	$numberOfChangesAtInit,$code) = @_ ;
	my $rv;
	my ($line,$col)= split(/\./,$txt->index('insert'));
	my ($last_line,$last_col) = split(/\./,$txt->index('end'));
	my $mode = ($txt->OverstrikeMode) ? 'Ins' : '   ';
	$rv = $txt->numberChanges() ;
	$rv -= $numberOfChangesAtInit;
	my $edit_flag = ($rv > 0 ) ? 'Changed' : '     ';
	$main::editingCodeProperties |= $code if ($rv && $code);
	&main::trace("edit_indicators '$rv' - '$numberOfChangesAtInit' editingCodeProperties '$main::editingCodeProperties'");

	$lLineCol->configure (-text=> "$line $col");	## u MO03604
	$lSize->configure (-text=> "$last_line");		## u MO03604
	$lMode->configure(-text=> "$mode");				## u MO03604
	$lChanged->configure(-text=> "$edit_flag");		## u MO03604

	return $rv
}

sub dlg_libraries {
	ctkDlgGetLibraries->dlg_libraries(&main::getmw)
}

sub file_callbacks {
	&main::trace("file_callback");
	return undef if ($main::editingCodeProperties & 1);
	$mw->ctkDlgGetCode(
		-assistentState => 1,
		-code => \@ctkProject::user_subroutines,
		-extract => \&main::extractSubroutines,
		-editcode=> 1,
		-title => "Edit properties",
		-subtitle => "Callbacks - $main::projectName",
		-debug => $debug);
	return 1
}

sub file_other_code {
	&main::trace("file_other_code");
	return undef if ($main::editingCodeProperties & 16);
	$mw->ctkDlgGetCode(
		-assistentState => 1,
		-code => \@ctkProject::other_code,
		-extract => \&main::extractSubroutines,
		-editcode=> 16,
		-title => "Edit properties",
		-subtitle => "Other code - $main::projectName",
		-debug => $debug);
	return 1
}

sub file_pod {
	&main::trace("file_pod");
	return undef if ($main::editingCodeProperties & 2);
	$mw->ctkDlgGetCode(
		-assistentState => 0,
		-code => \@ctkProject::user_pod,
		-editcode=> 2, -title => "Edit properties",
		-subtitle => "POD section - $main::projectName",
		-debug => $debug);
	return 1
}

sub file_gcode {
	&main::trace("file_gcode");
	return undef if ($main::editingCodeProperties & 4);
	$mw->ctkDlgGetCode(
		-assistentState => 1,
		-code => \@ctkProject::user_gcode,
		-editcode=> 4,
		-title => "Edit properties",
		-subtitle => "General code - $main::projectName",
		-debug => $debug);
	return 1
}

sub file_methods {
	&main::trace("file_methods");
	return undef if ($main::editingCodeProperties & 8);
	$mw->ctkDlgGetCode(
		-assistentState => 1,
		-code => \@ctkProject::user_methods_code,
		-editcode=> 8,
		-extract => \&main::extractMethods,
		-title => "Edit properties",
		-subtitle => "Methods - $main::projectName",
		-debug => $debug);
	return 1
}

sub dlg_getVariables {
	return &std::dlg_getVariables(@_);
}

sub deleteFromLocal {
	my $var = shift;
	for (my $i=0; $i < @ctkProject::user_local_vars; $i++) {
		if ($ctkProject::user_local_vars[$i] eq $var) {
				splice(@ctkProject::user_local_vars,$i,1);
				last;
		}
	}
	return 1
}

sub deleteFromGlobal {
	my $var = shift;
	for (my $i=0; $i < @ctkProject::user_auto_vars; $i++) {
		if ($ctkProject::user_auto_vars[$i] eq $var) {
				splice(@ctkProject::user_auto_vars,$i,1);
				last;
		}
	}
	return 1
}

sub moveLocal2Global {
	my ($from, $to) = @_;
	my @v = $from->curselection;
	map {
		my $var = $from->get($_);
		$to->insert('end',$var);
		$from->delete($_);
		&deleteFromLocal($var);
		push @ctkProject::user_auto_vars, $var  unless (grep /$var/ , @ctkProject::user_auto_vars)
	} @v;
}
sub moveGlobal2Local {
	my ($from, $to) = @_;
	my @v = $from->curselection;
	map {
		my $var = $from->get($_);
		$to->insert('end',$var);
		$from->delete($_);
		&deleteFromGlobal($var);
		push @ctkProject::user_local_vars, $var unless (grep /$var/ , @ctkProject::user_local_vars);
	} @v;
}
sub editLocal {
	my $lb = shift;
	my @v = $lb->curselection();
	map {
		my $var = $lb->get($v[0]);
		my $nVar = &std::dlg_getSingleValue($lb,$var);
		## if (defined($nVar) && $nVar =~ /\S+/) {
		if ($nVar) {
			$lb->delete($v[0]);
			$nVar =~ s/\s//g;
			$lb->insert('end',$nVar);
			&deleteFromLocal($var);
			push @ctkProject::user_auto_vars, $nVar  unless (grep /$nVar/ , @ctkProject::user_auto_vars);
		}
	} (@v);
	return 1
}
sub editGlobal {
	my $lb = shift;
	my @v = $lb->curselection();
	map {
		my$var = $lb->get($v[0]);
		my $nVar = &std::dlg_getSingleValue($lb,$var);
		## if (defined($nVar) && $nVar =~ /\S+/) {
		if ($nVar) {
			$lb->delete($v[0]);
			$nVar =~ s/\s//g;
			$lb->insert('end',$nVar);
			&deleteFromGlobal($var);
			push @ctkProject::user_auto_vars, $nVar unless (grep /$nVar/ , @ctkProject::user_auto_vars);
		}
	} @v;
	return 1
}
sub addLocal {
	my $lb = shift;
	my $nVar = &std::dlg_getSingleValue($lb);
	## if (defined($nVar) && $nVar =~ /\S+/) {
	if ($nVar) {
		$nVar =~ s/\s//g;
		$lb->insert('end',$nVar);
		push @ctkProject::user_local_vars, $nVar  unless (grep /$nVar/ , @ctkProject::user_local_vars);
	}
}
sub addGlobal {
	my $lb = shift;
	my $nVar = &std::dlg_getSingleValue($lb);
	## if (defined($nVar) && $nVar =~ /\S+/) {
	if ($nVar) {
		$nVar =~ s/\s//g;
		$lb->insert('end',$nVar);
		push @ctkProject::user_auto_vars,$nVar unless (grep /$nVar/ , @ctkProject::user_auto_vars);
	}
}
sub deleteGlobal {
	my $lb = shift;
	my @v = $lb->curselection();
	map {
		my $var = $lb->get($_);
		$lb->delete($_);
		&deleteFromGlobal($var)
	} @v;

}
sub deleteLocal {
	my $lb = shift;
	my @v = $lb->curselection();
	map {
		my $var = $lb->get($_);
		$lb->delete($_);
		&deleteFromLocal($var)
	} @v;

}

sub code_variables {
	&main::trace("code_variables");
	&main::extractAndAssignVariables();
	&main::dlg_getVariables($mw);
}

sub dlg_getAdvertisedWidgets {
	my @aList =  &std::dlg_getAdvertisedWidgets(@_);
	return wantarray ? @aList : \@aList
}

sub dlg_codeOptions {
	&main::trace("dlg_codeOptions");

	my $subWidgetList;
	my (%new_file_opt)=(%file_opt);
	$new_file_opt{'description'} =~ s/\\\'/\'/g;
	$new_file_opt{'title'} =~ s/\\\'/\'/g;
	my $reply = &std::dlg_codeOptions($mw,\%new_file_opt);

	return undef unless (defined $reply);

	$new_file_opt{'description'} =~ s/\'/\\\'/g;
	$new_file_opt{'title'} =~ s/\'/\\\'/g;
	if ((@ctkProject::user_local_vars > 0 || @ctkProject::user_auto_vars > 0) &&
		($new_file_opt{'autoExtract2Local'} ne $file_opt{'autoExtract2Local'} ||
		 $new_file_opt{'autoExtractVariables'} ne $file_opt{'autoExtractVariables'})) {
			(%file_opt) = (%new_file_opt);
			my $subroutineArgsName = $ctkTargetSub::subroutineArgsName;
			if ($file_opt{'subroutineArgs'}) {
				push @ctkProject::user_local_vars, $subroutineArgsName  unless (grep /subroutineArgsName/ , @ctkProject::user_local_vars);
			} else {
				@ctkProject::user_local_vars = grep ($_ ne $subroutineArgsName, @ctkProject::user_local_vars);
			}
			my @w = &main::_extractVariables();
			ctkProject->refreshVariables(@w);
			&main::dlg_getVariables($mw) if &std::askYN("Auto extracted variables has been reassigned,\ndo you want start the 'edit variable' dialog anyway?");
	} else {
		(%file_opt) = (%new_file_opt);
	}

	&main::changes(1); # can't store undo info so far!
	return 1
}

sub recolor_dialog {
	my $widget = shift;
	my ($level) = @_;
	&main::trace("recolor_dialog");
	$level = 0 unless(defined($level));
	&main::trace("'$widget'  '$level'");
	return unless (defined($widget) and Tk::Exists($widget)); 	## i MO0xx01
	my $x = $widget->class;
	if ( !exists $palette->[$level]->{-widgetClass} or grep ($x eq $_, @{$palette->[$level]->{-widgetClass}})) {
		my %p = %{$palette->[$level]} if (defined($palette->[$level])) ;
		if (%p) {
			delete $p{-widgetClass};
			$widget->configure(%p);
			&main::trace("widget '$x' recolored");
			undef %p;
		}
	} else {
			&main::trace("widget '$x' skipped");
	}
	$level++ if ($level < scalar(@$palette)-1);
	foreach my $child ($widget->children) {
			&main::recolor_dialog($child,$level);
	}
}

sub file_init {
	&main::struct_new;
	&main::preview_repaint; # force repaint!
	&ctkUndoStack::clearUndoStack; # clear undo/redo stacks
	ctkProject->init();
	(%file_opt)=ctkProject->empty_file_opt();
	$opt_isolate_geom = 0;
}
sub file_new {
	# check for save status here!
	&main::trace("file_new");

	return undef unless &main::save_changes;

	&work_save();

	$main::projectName = ctkProject->noname;
	$ctkApplication::applName = '';
	$ctkApplication::applFolder = '';

	&main::file_init();
	return 1
}

sub file_newx {
	return undef unless (defined(&main::file_new()));
	if (&main::template_load()) {
		&main::preview_repaint();
	} else {
		&main::dlg_codeOptions();
	}
	ctkMenu->updateMenu();
	return 1
}

sub struct_new {
	&main::trace("struct_new");

	&main::clear_preview();

	@ctkProject::tree=($MW);
	%ctkProject::descriptor =();
	ctkProject->descriptor->{$MW} = &main::createDescriptor($MW,undef,'Frame',undef,undef,undef);
	&main::set_selected($MW);
	&main::tree_repaint();
	ctkPreview->clearWidgets;
	@ctkProject::user_auto_vars=();
	@ctkProject::user_local_vars=();

	ctkCallback->clearAll;

	$ctkProject::objCount = 0;		## reset object counter !!!
	$hiddenWidgets =[];
}

sub work_save {
	&main::trace("work_save");
	my $rv;
	my $name = ($main::projectName) ? $main::projectName : ctkProject->noname;
	$name = ctkWork->name($name);
	if ($name =~ /[\/\\]/)  {
		my $path = &main::head($name);
		$path =~ s/[\\\/]$//;
		$path = ctkWork->fileName($path);
		mkdir $path unless (-d $path);
	} else {}

	my $file = ctkWork->fileName($name);
	return undef if(&main::isUnchanged() && (-f $file));

	$mw->Busy;
	&main::Log("Doing work_save on '$file' ...");
	$Data::Dumper::Indent = 1;		# turn indentation to a minimum
	my $s = Data::Dumper->Dump(&main::getDumpArguments);
#	my $s = Data::Dumper->Dump([\%ctkProject::descriptor, \@ctkProject::tree, \@ctkProject::user_subroutines,\@ctkProject::user_methods_code,  \@ctkProject::user_gcode, \@ctkProject::other_code, \@ctkProject::user_pod, \@ctkProject::user_auto_vars,\@ctkProject::user_local_vars, \%file_opt, \$main::projectName, \$opt_isolate_geom,$hiddenWidgets,\@ctkProject::libraries,\$ctkApplication::applName,\$ctkApplication::applFolder,\$opt_TestCode,\@ctkProject::baseClass],
#							   ['rDescriptor','rTree','rUser_subroutines','rUser_methods_code','rUser_gcode','rOther_code','rUser_pod','rUser_auto_vars','rUser_local_vars','rFile_opt','rProjectName','ropt_isolate_geom','rHiddenWidgets','rLibraries','rApplName','rApplFolder','opt_TestCode','rBaseClass']);
	$rv = ctkWork->save($file,$s);
	$mw->Unbusy;
	if ($rv) {
			&main::Log("Work saved into '$file'");
	} else {
		&std::ShowErrorDialog("Could not open '$file',\ncannot save work!");
	}
	ctkMenu->updateMenu();
	return $rv;
}

sub work_select {
	my ($force) = @_;
	$force = 0 unless(defined($force));

	&main::trace("work_select");

	# open file save dialog box
	my $name = ctkProject->name($main::projectName);
	my $file = ctkWork->fileName($name);
	return ctkWork->select($mw,$file,$force);
}

sub work_restore {

	my ($force) = @_;
	my $rv;
	$force = 0 unless(defined($force));

	&main::trace("work_restore");

	my $name = $main::projectName;
	my $file = ctkWork->fileName($name);
	my @code = ();
	my ($rDescriptor,$rTree,$rUser_subroutines,$rOther_code,$rUser_methods_code,$rUser_gcode,$rUser_pod,$rUser_auto_vars,$rUser_local_vars,$rFile_opt,$rProjectName,$ropt_isolate_geom,$rHiddenWidgets,$rLibraries,$rApplName,$rApplFolder,$rOpt_TestCode,$rBaseClass);

	return undef unless(-d ".$FS$ctkWork::workFolder");  ## precondition

	if (&main::save_changes()) {
		&main::changes(0);	## clear change bit even when user cancelled the save!
	} else {}
	$file = ctkWork->select($mw,$file,$force) ;
	if (defined($file)) {
		$file = ctkWork->fileName($file);
		$mw->Busy;
		&main::trace("Restoring work from '$file");
		my $workCode = ctkWork->restore($file);
		unless ($workCode) {
			$mw->Unbusy;
			&std::ShowErrorDialog("Could not open '$file',\ncannot restore work!");
			return undef
		}
		$workCode =~ s/\$rLastfile/\$rProjectName/g; ## compat fix
		eval $workCode;
		if ($@) {
			&std::ShowErrorDialog("Could not restore work '$file' because of\n'$@'");
			&main::file_new();
		} else {
			$main::projectName = ctkProject->name(ctkWork->name($file));
			&main::file_init();
			%ctkProject::descriptor = %$rDescriptor;
			@ctkProject::tree = @$rTree;
			@ctkProject::user_subroutines = @$rUser_subroutines;
			@ctkProject::user_methods_code = @$rUser_methods_code;
			@ctkProject::user_gcode = @$rUser_gcode;
			@ctkProject::other_code = @$rOther_code if (defined($rOther_code));
			@ctkProject::user_auto_vars = @$rUser_auto_vars;
			@ctkProject::user_local_vars = @$rUser_local_vars;
			@ctkProject::user_pod = @$rUser_pod;
			@ctkProject::libraries = @$rLibraries if(defined ($rLibraries));
			@ctkProject::baseClass = @$rBaseClass if (defined($rBaseClass));
			%file_opt = %$rFile_opt;
			$file_opt{code} = delete $file_opt{fullcode} if(exists $file_opt{fullcode});
			$file_opt{Toplevel} = 1 unless (exists $file_opt{Toplevel});
			$file_opt{subroutineArgs} = $ctkTargetSub::opt_defaultSubroutineArgs unless (exists $file_opt{subroutineArgs});

			$opt_isolate_geom = $$ropt_isolate_geom;
			$main::projectName = $$rProjectName;
			$opt_TestCode = (defined ($rOpt_TestCode)) ? $$rOpt_TestCode : 1;
			$ctkApplication::applName = (defined ($rApplName)) ? $$rApplName : '';
			$ctkApplication::applFolder = (defined ($rApplFolder)) ? $$rApplFolder : '';
			$ctkProject::objCount = scalar(@ctkProject::tree);
			$hiddenWidgets = $rHiddenWidgets if defined($rHiddenWidgets);
			&main::Log("Work restored from '$file'");
			$mw->Unbusy;
		}
		&main::changes(1);
		&main::tree_repaint();
		&main::preview_repaint();
		&main::extractAndAssignVariables();
		&main::extractMethodsAndSubroutineNames;
		$rv = 1;
	} else {
		&main::trace("Select work dismissed.");
	}
	$mw->Unbusy;
	ctkMenu->updateMenu();
	return $rv;
}

sub template_save {
	&main::trace("template_save");
	my $file = ctkProject->noname;

	return undef unless(-d ".$FS$templateFolder");  ## precondition

	$mw->Busy;

	$file = &template_select('save') ;
	if (defined($file)) {
		&main::Log("Doing template_save on '$file'");
		$file = &main::buildTemplateFileName($file);
		my $f = ctkFile->new(fileName => $file,debug => $debug);
		$f->backup();
		unless ($f->open('>')) {
			&sid::ShowErrorDialog("Could not open '$file',\ncannot save template!");
			$mw->Unbusy;
			return undef
		}
		$Data::Dumper::Indent = 1;         # turn indentation to a minimum
		my $s = Data::Dumper->Dump(&main::getDumpArguments);
#		my $s = Data::Dumper->Dump([\%ctkProject::descriptor, \@ctkProject::tree, \@ctkProject::user_subroutines,\@ctkProject::user_methods_code,  \@ctkProject::user_gcode, \@ctkProject::other_code, \@ctkProject::user_pod, \@ctkProject::user_auto_vars,\@ctkProject::user_local_vars, \%file_opt, \$main::projectName, \$opt_isolate_geom,$hiddenWidgets,\@ctkProject::libraries,\$ctkApplication::applName,\$ctkApplication::applFolder,\$opt_TestCode,\@ctkProject::baseClass],
#								   ['rDescriptor','rTree','rUser_subroutines','rUser_methods_code','rUser_gcode','rOther_code','rUser_pod','rUser_auto_vars','rUser_local_vars','rFile_opt','rProjectName','ropt_isolate_geom','rHiddenWidgets','rLibraries','rApplName','rApplFolder','opt_TestCode','rBaseClass']);
		$f->print($s);
		$f->close;
		&main::Log("Template saved into '$file'");
	} else {
		&main::trace("Select template dismissed.");
	}
	$mw->Unbusy;
	ctkMenu->updateMenu();
	return 1
}

sub template_select {
	my ($action) = @_;

	&main::trace("template_select");

	# open file save dialog box
	my $file = ctkProject->noname;
	$file = &main::tail($main::projectName) if($main::projectName);

	$file = &main::buildTemplateFileName($file);
	if ($action  eq 'open') {
		if($^O =~ /(^mswin)|(^$)/i) {
			my @types = ( ["Template",'.pl'], ["All files", '.*'] );
			$file = $mw->getOpenFile(-filetypes => \@types,
				-initialfile => $file,
				-defaultextension => '.pl',
				-title=>&std::_title('Select template to load.'));
		} else {
			$file =~ s/\\/\//g;		## i MO03602
			my $initialDir = ctkFile->head($file);
			$file = $mw->FileSelect(-directory => $initialDir,
				-initialfile => $file,
				-title=>&std::_title('Select template to load.'))->Show;
		}
	} elsif ($action  eq 'save') {
		if($^O =~/(^mswin)|(^$)/i) {
			my @types = ( ["Template",'.pl'], ["All files", '*'] );
			$file =~ s/\//\\/g;
			$file = $mw->getSaveFile(-filetypes => \@types,
				-initialfile => $file,
				-defaultextension => '.pl',
				-title=>&std::_title('Select template to save'));
		} else {
			$file =~ s/\\/\//g;		## i MO03602
			my $initialDir = ctkFile->head($file);
			$file = $mw->FileSelect(-directory => $initialDir,
				-initialfile => $file,
				-title=>&std::_title('Select template to save'))->Show;
		}
	} else {
		&main::Log("Invalid action code '$action'");
		return undef;
		}
	# return 'Cancel' if file not selected
	return ($file) ? $file : undef;
}

sub template_load {
	my $rv;

	my $file = ($main::projectName) ? &main::tail($main::projectName) : ctkProject->noname;
	my $code ='';
	my ($rDescriptor,$rTree,$rUser_subroutines,$rOther_code,$rUser_methods_code,$rUser_gcode,$rUser_pod,$rUser_auto_vars,$rUser_local_vars,$rFile_opt,$rProjectName,$ropt_isolate_geom,$rHiddenWidgets,$rLibraries,$rApplName,$rApplFolder,$rOpt_TestCode,$rBaseClass);

	&main::trace("template_load");

	return undef unless(-d ".$FS$templateFolder");  ## precondition

	$mw->Busy;
	$file = &main::template_select('open') ;
	if (defined($file)) {
		&main::trace("Loading template from '$file");
		my $f = ctkFile->new(fileName => $file,debug => $debug);
		unless ($f->open ('<')) {
			&std::ShowErrorDialog("Could not open '$file',\ncannot load template!");
			$mw->Unbusy;
			return undef
		};
		my @lines = $f->get;
		$f->close;
		$code = join ('',@lines);
		if ($code !~ /^\s*$/) {
			eval $code;
			unless ($@) {
				%ctkProject::descriptor = %$rDescriptor;
				@ctkProject::tree = @$rTree;
				@ctkProject::user_subroutines = @$rUser_subroutines;
				@ctkProject::user_methods_code = @$rUser_methods_code;
				@ctkProject::user_gcode = @$rUser_gcode;
				@ctkProject::other_code = @$rOther_code if (defined($rOther_code));
				@ctkProject::user_auto_vars = @$rUser_auto_vars;
				@ctkProject::user_local_vars = @$rUser_local_vars;
				@ctkProject::user_pod = @$rUser_pod;
				@ctkProject::libraries = @$rLibraries if(defined ($rLibraries));
				%file_opt = %$rFile_opt;
				$file_opt{code} = delete $file_opt{fullcode} if(exists $file_opt{fullcode});
				$file_opt{Toplevel} = 1 unless (exists $file_opt{Toplevel});
				$opt_isolate_geom = $$ropt_isolate_geom;
				$main::projectName = $$rProjectName;
				$main::projectName = ctkProject->noname unless (defined($main::projectName) && $main::projectName =~ /\S+/);
				$opt_TestCode = (defined ($rOpt_TestCode)) ? $$rOpt_TestCode : 1;
				$ctkApplication::applName = (defined ($rApplName)) ? $$rApplName : '';
				$ctkApplication::applFolder = (defined ($rApplFolder)) ? $$rApplFolder : '';
				$ctkProject::objCount = scalar(@ctkProject::tree);
				$hiddenWidgets = $rHiddenWidgets if defined($rHiddenWidgets);
				&main::Log("Template load from '$file'");
			} else {
				&std::ShowErrorDialog("Could not successfully load template '$file'.\n\n'$@'");
			}
		} else {
			&std::ShowErrorDialog("'$file' is empty,\ncannot process, pls check this template!");
		}
		&main::changes(0);
		&main::tree_repaint();
		## &main::preview_repaint();
		$rv = 1;
	} else {
		&main::trace("Select template dismissed.");
	}
	$mw->Unbusy;
	return $rv;
}

sub help {
	return $help->userDoc();
}

sub menu_about {
	&main::trace("menu_about");
	my $d = &std::dlg_about(@_);
	$d->Show();
}

sub doBlink {
	my ($sw) = @_;
	$sw = &main::selectedWidget unless (defined($sw));

	return undef unless $sw->Tk::Exists();
	return undef if isHidden(&main::path_to_id());

	my $bg=$sw->cget(-background);
	my $fg = $sw->cget(-foreground);

	my $delay = 30;

	foreach (0..4) {
		$sw->configure(-background=>$fg,-foreground=>$bg);
		$mw->update;$mw->after($delay);
		$sw->configure(-background=>$bg,-foreground=>$fg);
		$mw->update;$mw->after($delay);
		last unless $sw->Tk::Exists();
	}
	$mw->update;
	return 1
}

sub buildWidgetOptionsOnEdit {
	my ($args) = @_;
	my (@w) = %$args;
	my $rv = &main::quotatY(\@w);
	return $rv;
}

sub buildWidgetOptions {
	my ($args,$type) = @_;
	my (@w) = %$args;
	my $rv = &main::quotatX(\@w,$type);
	return $rv;
}

sub isChanged { return ($ctkProject::changes) ? 1 : 0 }

sub isUnchanged { return !&main::isChanged()}

sub changes {
	&main::trace("changes");
	$ctkProject::changes = shift if (@_);
	&main::trace("changes= '$ctkProject::changes'");
	$statusbar->Subwidget('changes')->configure(-text=> (isChanged())?'changed':'    ');
	$statusbar->Subwidget('changes')->configure(-bg=> (isChanged()) ? '#FF7D7D' : $mwPalette->{'background'});
	if (isChanged()) {
		my @conflicts = ctkProject->conflicts();
		if (@conflicts) {
			&std::ShowWarningDialog(join ("\n\n",@conflicts));
		}
		## &work_save();
		&main::preview_repaint();
		&main::tree_repaint();
	}
	ctkMenu->updateMenu();
	return isChanged();
}

sub session_restore {
	my ($userid,$prefix) = @_;
	my $rv;
	&main::trace("session_restore");
	$session = ctkSession->new(prefix => $prefix,userid => $userid, debug => $debug) unless(defined($session));
	if (defined($session)) {
		if ($session->restore) {
			&main::Log("Session '$userid' successfully restored.");
			$rv = 1;
		} else {
			&main::Log("Session '$userid' not restored.");
		}
	} else {
		&main::Log("Could not instantiate session '$userid'.");
	}
	ctkMenu->updateMenu();
	return $rv
}
sub session_save {
	my ($userid,$prefix) = @_;
	my $rv;
	&main::trace("session_save");
	$session = ctkSession->new(prefix => $prefix,userid => $userid, debug => $debug) unless(defined($session));
	if (defined($session)) {
		if ($session->save([$main::main::projectName, $main::previousFiles,$ctkApplication::applName,$ctkApplication::applFolder],
							[qw/main::main::projectName main::previousFiles ctkApplication::applName ctkApplication::applFolder/])) {
			&main::Log ("Session '$userid' successfully saved.");
			$rv = 1
		} else {
			&main::Log ("Could not save session '$userid'.")
			}
	} else {
		&main::Log("Could not instantiate session '$userid'.");
	}
	return $rv
}

sub abandon {
	&main::trace("abandon");
	&main::session_save($userid,$sessionFileNamePrefix);
	if (&main::save_changes ) {
		&main::work_save();
		$help->killAll();
		exit
	} else { ## cancel
		## continue
	}
}

sub save_changes {
	my $rv;
	&main::trace("save_changes");
	$session = ctkSession->new(prefix => $sessionFileNamePrefix,userid => $userid, debug => $debug) unless(defined($session));
	$rv = $session->save_changes();
	return $rv;		# Ok
}

sub _extractVariables {
	&main::trace("extractVariables");

	my @rv =();
	my $parser = ctkParser->new();
	foreach my $element (@ctkProject::tree[1..$#ctkProject::tree]) {
		my $d=ctkProject->descriptor->{&main::path_to_id($element)};
		next unless $d;
		my @token = $parser->parseString($d->opt);
		foreach (0..$#token) {
			next unless $token[$_] =~ /^-/;
			my ($opt,$value) = @token[$_,$_ + 1];
			if ($value =~ /^[\'\"\#\w]/i) {
				next
			} elsif ($value =~ /^[%@\$]/) {
				if ($value =~ /^(.)(\w+)\s*([\[\{])/) {
					$value =($3 eq '[') ? "\@$2" : ($3 eq '{') ? "\%$2" : "\$$2";
				}
				push(@rv,$value) unless grep($_ eq $value,@rv);
			} elsif ($value =~ /^\\[\$@%]/) {
				$value =~ s/^\\//;
				if ($value =~ /^\$(\w+)\s*([\[\{])/) {
					$value =($3 eq '[') ? "\@$2" : ($3 eq '{') ? "\%$2" : "\$$2";
				}
				push(@rv,$value) unless grep($_ eq $value,@rv);
			} elsif ($value =~ /\[[^,]+,([^]]+)\]/) {	## -command => [ sub {}, $var1,$var2]
				my $user_var = "$1";
				&main::trace("Possible variable list detected '$user_var'");
				$user_var =~ s/,/ /g;
				map {
					my $v = $_;
					if ($v =~ /^\$/) {
						push (@rv,$v) unless (grep $_ eq $v ,@rv);
						&main::trace("Variable '$v' detected.");
					} elsif ($v =~ /^\\[@%][a-z_]/i) {
						$v =~ s/^\\//;
							push (@rv,$v) unless (grep $_ eq $v ,@rv);
							&main::trace("Variable '$v' detected.");
					} elsif ($v =~ /\d+$/){
						## numeric constant, OK
					} elsif ($v =~ /sub\s*\{/){
						## anonymous sub
					} else {
						&main::trace("Extracting variables, possible variable $v discarded.") unless ($v =~ /^-/);
					}
				} $parser->parseWidgetOptions($parser->parseString($user_var));
			} else {}
			## if() { ## more variable patterns go here
		}
	}
	return wantarray ? @rv : \@rv
}

sub extractVariables {
	my @rv =();
	&main::trace("extractVariables");
	return wantarray ? @rv : \@rv  unless($file_opt{'autoExtractVariables'});
	@rv = &main::_extractVariables();
	foreach (@ctkProject::user_local_vars, @ctkProject::user_auto_vars) { ## eliminate vars which are already explicitly declared
		my $v = $_;
		next unless (grep ($v eq $_, @rv));
		foreach ( reverse 0..$#rv) {
			if ($rv[$_] eq $v) {
				splice @rv,$_,1 ;
				&main::trace("variable '$v' already declared, eliminated");
				last
			}
		}
	}
	return wantarray ? @rv : \@rv ;
}

sub extractMethodsAndSubroutineNames {
	&main::trace("extractMethodsAndSubroutineNames");
	ctkCallback->extractMethodsAndSubroutineNames();
}

sub extractAndAssignVariables {
	my $rv;
	&main::trace("extractAndAssignVariables");
	my @w = ctkProject->extractVariables();
	$rv = ctkProject->assignVariables(@w);
	return $rv
}

sub genUselib {
	&main::trace("genUselib");
	die "obsolete call";
}

sub genUseStatements {
	&main::trace("genUseStatements");
	die "absolete call";
}

sub genPod {
	my ($code,$now) = @_;
	&main::trace("genPod");
	die "obsolete call";
}

sub genGcode {
	my ($code, $now) = @_;
	&main::trace("genGcode");
	die "obsolete call";
}

sub genOptions {
	my ($code,$now) = @_;
	&main::trace("genOptions");
	die "obsolete call";
}

sub genCallbacks {
	my ($code,$now) = @_;
	&main::trace("genCallbacks");
	die "obsolete call" ;
	return $code;
}


sub genMethods {
	my ($code,$now) = @_;
	&main::trace("genMethods");
	die "obsolete call";
}

sub genOtherCode {
	my ($code,$now) = @_;
	&main::trace("genOtherCode");
	die "obsolete call";
}
sub genVariablesLocal {
	my ($code, $mw) = @_;
	&main::trace("genVariablesLocal");
	die "obsolete call";
}

sub genAllVariablesLocal {
	my ($code, $mw) = @_;
	&main::trace("genAllVariablesLocal");
	die "obsolete call";
}

sub genVariablesGlobal {
	my ($code, $mw) = @_;
	&main::trace("genVariablesGlobal");
	die "obsolete call";
}

sub genAllVariablesGlobal {
	my ($code, $mw) = @_;
	&main::trace("genAllVariablesGlobal");
	die "obsolete call";
}

sub genGlobalVariablesClassVariables {
	my ($code, $mw) = @_;
	&main::trace("genGlobalVariablesClassVariables");
	die "obsolete call";
}

sub genCalls2Test {
	my ($code,$now,$mw) = @_;
	&main::trace("genCalls2Test");
	die "obsolete call";
}

sub genOnDeleteWindow {
	my ($code,$now,$mw) = @_;
	die "obsolete call";
}

sub genTestCode4package {
	my ($code,$now,$mw) = @_;
	&main::trace("genTestCode4package");
	die "obsolete call";
}
sub genTestCode4Composite {
	my ($code,$now,$mw) = @_;
	&main::trace("genTestCode4Composite");
	die "obsolete code";
}

sub genTestCode4script {
	my ($code,$now,$mw) = @_;
	&main::trace("genTestCode4script");
	die "obsolete call";
}
sub genTestCode4subroutine {
	my ($code,$now,$mw) = @_;
	&main::trace("genTestCode4subroutine");
	die "obsolete code";
}

sub genTestCode {
	my ($code,$now,$mw) = @_;
	&main::trace("genTestCode");
	die "obsolete code";
}

sub genScript {
	my ($code, $now,$mw) = @_;
	&main::trace("genScript");
	$code = ctkTargetScript->generate(-code => $code, -mw => $mw, -now => $now);
	return $code
}

sub genPackage {
	my ($code,$now,$mw) = @_;
	&main::trace("genPackage");
	$code = ctkTargetPackage->generate(-code => $code, -mw => $mw, -now => $now);
	return $code
}

sub genAdvertisedWidgets  {
	my ($code,$now,$mw) = @_;
	die "obsolete code";
}

sub genComposite {
	my ($code,$now,$mw) = @_;
	&main::trace("genComposite");
	$code = ctkTargetComposite->generate(-code => $code, -mw => $mw, -now => $now);
	return $code;
}

sub genSubroutine {
	my ($code,$now,$mw) = @_;
	&main::trace("genSubroutine");

	$code = ctkTargetSub->generate(-code => $code, -mw => $mw, -now => $now);
	return $code
}

sub genUselibStrictAndUseStatements {
	my ($code,$now) = @_;
	&main::trace("genUselibStrictAndUseStatements");
	die "obsolete call";


	return $code
}

sub genMainWindow {
	my ($code,$now) = @_;
	&main::trace("genMainWindow");
	die "obsoelete call";
}

sub code_generate {

	&main::trace("code_generate");
	if (@$hiddenWidgets) {
		return undef unless (&std::askYN("There are still hidden widgets,\ngenerate code anyway?"))
	}
	&main::extractAndAssignVariables();
	my $code = ctkTargetCode->generateTarget();
	return $code
}

sub buildProjectName {
	die "obsolete sub called"
}

sub buildProjectFileName {
	die "obsolete sub called"
}

sub buildWorkName {
	die "obsolete sub called "
}

sub buildWorkFileName {
	die "obsolete sub called "
}

sub buildTemplateFileName {
	my ($file) = @_ ;
	&main::trace("buildTemplateFileName");
	$file = ctkProject->noname unless(defined($file));
	$file = &main::tail($file);
	return ".$FS$templateFolder$FS$file";
}

sub buildApplicationFileName {
	my ($file) = @_ ;
	my $rv;
	&main::trace("buildApplicationFileName");
	#$rv = &main::tail($file);
	#$rv = "$ctkApplication::applFolder$FS$file" if ($ctkApplication::applFolder);
	$rv = 'ctkApplication'->buildApplicationFileName($file);
	return $rv
}

sub selectFileForSave {
	return &std::selectFileForSave(@_);
}

sub selectFileForOpen {
	return &std::selectFileForOpen(@_);
}

sub updateFileHistory {
	my ($file) = @_;
	&main::trace("updateFileHistory");
	return undef unless(defined($file));
	foreach (@$previousFiles) {
		last if ($_  gt $file);
		return undef if( $_ eq $file);
		}
	shift @$previousFiles unless(scalar(@$previousFiles) < $opt_fileHistory);
	push @$previousFiles, $file ;
	@$previousFiles = sort @$previousFiles;
	return 1
}

sub saveDataToFile {
	die "obsolete call";
	my ($fName) = @_;
	my $rv;
	&main::trace("saveDataToFile");

	my $source = &main::code_generate();
	if (defined($source)) {
		my $f = ctkFile->new(fileName =>$fName,debug => $debug);
		$f->backup();
		if ($f->open('>')) {
			map {$f->print("$_\n") } @$source;
			$f->close;
			$rv = 1;
			&main::trace("project '$fName' successfully saved")
		} else {
			# report error
			&std::ShowErrorDialog("Project '$fName' write error\n'$!'");
			}
	} else {
			&std::ShowErrorDialog("Project '$fName' not saved because of\n'empty gened code'");
	}
	return $rv
}

sub file_close {
	&main::trace("file_close");
	if (&main::isChanged()) {
		my $reply=&std::ShowDialogBox(-bitmap=>'question',
							-text=>"Project '$main::projectName' not yet saved!\nDo you want to save the changes?",
							-title => 'Project changed.',
							-buttons => ["Save","Don't save", "Cancel"]);
		&main::file_save() if ($reply eq 'Save');
		return 0 if($reply eq 'Cancel');
	}
	$main::projectName = ctkProject->noname;
	$ctkApplication::applName ='';
	$ctkApplication::applFolder = '';
	&main::file_init();
	&main::changes(0);
	ctkMenu->updateMenu();
	return 1
}

sub file_save {

	&main::trace("file_save");

	return undef unless (&main::isChanged());

	if($editingCodeProperties) {
		return undef unless(&std::askYN("You are editing the code properties,\n save anyway?"));
	}

	return &main::file_save_as() if ($main::projectName eq ctkProject->noname);
	return &main::file_save_as($main::projectName) if( !( -f $main::projectName) );

	my $file = $main::projectName;
	$file = ctkProject->noname if ($file eq $0); ##  protect me from myself !
	$file = ctkProject->fileName($file);

	$mw->Busy;
	ctkProject->saveDataToFile($file);									# save data structure to file
	&work_save();
	$mw->Unbusy;
	&main::changes(0);			# reset changes flag
	ctkMenu->updateMenu();
	return 1;
}

sub file_save_as {
	my ($file) = @_;
	&main::trace("file_save_as");

	if($editingCodeProperties) {
		return undef unless(&std::askYN("You are editing the code properties,\n save anyway?"));
	}

	unless (defined($file)) {
		$file = ctkProject->fileName();
		$file = &main::selectFileForSave($file);
		unless(defined($file)) { # return undef if file not selected
			return undef
		}
	} else {
		$file = ctkProject->fileName($file);
	}
	$file = ctkProject->fileName(ctkProject->noname) if ($file eq $0); ##  protect me from myself !
	$mw->Busy;
	$main::projectName = &main::makeRelative($file);
	ctkProject->saveDataToFile($file); # save data structure to file
	&main::updateFileHistory($main::projectName);
	&work_save();
	$mw->Unbusy;
	&main::changes(0);
	ctkMenu->updateMenu();
	return 1;
}

sub file_open {
	&main::trace("file_open");
	my ($file) = @_ ;
	my $rv;
	$mw->Busy;
	# open file dialog box
	$file = $main::projectName unless (defined($file));
	$file = ctkProject->fileName($file) unless ($file =~ /[\\\/]/) ;
	$file = &main::selectFileForOpen($file,'Select project to be load.');
	$mw->Unbusy;

	return undef unless($file);
	return undef if ($file eq $0);
	$file = &main::makeRelative($file);

	$file = ctkProject->name($file);

	&main::updateFileHistory($file);

	if (defined(&main::file_new())) {
		&main::trace("Loading project '$file' ...");
		&main::file_read(ctkProject->fileName($file));
		$main::projectName = $file;
		&main::changes(0);
		&main::preview_repaint;
		ctkMenu->updateMenu();
		return 1
	} else {
		return undef
	}
}

sub setupPopupMenu4PreviousFiles {
	my ($hwnd) = @_;
	my $popup=$hwnd->Menu(-tearoff=>0);
	map {
		my $s = "sub {&main::execPrevious(\$previousFiles->[$_])}";
		my $w = eval $s;
		&main::trace("$s","$w");
		$popup->add('command',-label=>$previousFiles->[$_],
			-underline=>0,
			-command=> $w);
	} 0..scalar(@$previousFiles)-1;
	return $popup;
}

sub execPrevious {
		my $file = shift;
		&main::Log("execPrevious $file");
		 return undef unless(defined(&main::file_new()));
		$main::projectName = $file;
		&main::Log("Loading project '$main::projectName' ...");
		&main::file_read();
		&main::Log("... project '$main::projectName' loaded.");
		&main::preview_repaint;
		&main::extractAndAssignVariables();
		&main::work_save();
}

sub file_openPrevious {
	my $ans;
	my $wOpen;
	my $answ = '';

	return undef unless(scalar(@$previousFiles));

	my $popup = &main::setupPopupMenu4PreviousFiles($mw);
	my $x = $popup->Post($mw->pointerxy);
	&main::trace("x = '$x'") if defined $x;
	return 1;

}

sub askForOpen {
	my $rv = 0 ;
	&main::trace("askForOpen");
	my $reply=&std::ShowDialogBox(-bitmap=>'question',
							-text=>"Open the imported project?",
							-title => 'Import project.',
							-buttons => ["Ok","Cancel"]);
	$rv = 1 if ($reply =~ /Ok/i);
	return $rv;
}

sub file_import {
	&main::trace("file_import");

	$mw->Busy;
	# open file save dialog box
	my $iFile = "./*.pl";
	$iFile = &main::selectFileForOpen($iFile,'Project import, select target name.');
	$mw->Unbusy;

	unless($iFile) {
			$mw->Unbusy;
			return undef;
	}

	if ($iFile eq $0)  {
			$mw->Unbusy;
			return undef;
	}

	&main::Log("Importing file '$iFile' ...");

	my $file = ctkProject->fileName(&main::tail($iFile));
	my $if = ctkFile->new(fileName => $iFile,debug => $debug);
	my $of = ctkFile->new(fileName => $file,debug => $debug);
	$of->backup;
	my @lines = $if->get;
	if (@lines) {
		$of->print(@lines);
	} else {
		&std::ShowWarningDialog("Could not import project,\npls check the file.");
		$if->close;
		$of->close;
		$mw->Unbusy;
		return undef;
	}
	$if->close;
	$of->close;
	&main::Log("Project '$iFile' imported");

	if (&main::askForOpen()) {
			return undef unless(defined(&main::file_new()));
			$main::projectName = ctkProject->name($file);
			&main::updateFileHistory($main::projectName);
			&main::trace("Loading project '$main::projectName' ...");
			&main::file_read();
			&main::trace("... project '$main::projectName' loaded");
			&main::changes(0);
			&main::preview_repaint;
	} else {
			$mw->Unbusy;
	}
	return 1
}

sub file_export {
	my $file;
	return undef if  (&main::isChanged());
	$mw->Busy;
	&main::Log("Exporting project '$main::projectName'");

	$file =  ctkProject->fileName($main::projectName);
	my $oFile = &main::buildApplicationFileName($file);
	$oFile =selectFileForSave($oFile,'Export project, select target name') ;
	unless($oFile) { # return undef if file not selected
			$mw->Unbusy;
			return undef;
	}
	$file = ctkProject->noname if ($oFile eq $0); ##  protect me from myself !

	my $s = $opt_TestCode;
	$opt_TestCode = ($file_opt{'code'} == 1) ? 1 : 0;
	if ($opt_TestCode && ctkTargetCode->existsTestCode) {
		$opt_TestCode = (&std::askYN("Include the test code?")) ? 1 : 0;
		&main::Log("Test code suppressed.") unless ($opt_TestCode);
	} else {
		&main::Log("Test code, if any is there, suppressed.");
	}
	if (ctkProject->saveDataToFile($oFile)) { # save data structure to file
		&main::Log("Project '$main::projectName'  successfully exported to '$oFile'.");
	} else {
		&main::Log("Project '$main::projectName' not exported.");
	}
	$opt_TestCode = $s;

	$mw->Unbusy;
	return 1;
}


sub file_read { 	# read project and convert to internal data
	my ($file)=@_;
	&main::trace("file_read");
	$file = ctkProject->fileName($main::projectName) unless (defined($file));
	my $f = ctkFile->new(fileName => $file,debug => $debug);
	my @file;

	unless($f->open ('<')) {
		&std::ShowErrorDialog("Project $file read - $!\n");
		return 'Cancel';
	}
	@file = $f->get;
	$f->close;

	&main::parseTargetCode(\@file);
	&main::extractAndAssignVariables();
	&main::tree_repaint(0);
}

sub getWidgetIconName {
	my ($id) = @_;
	my $rv;
	$id = &main::path_to_id() unless (defined ($id));
	my $type = ctkProject->descriptor->{$id}->type;
	$rv = $w_attr->{$type}->{'icon'} if (exists $w_attr->{$type}->{'icon'});
	unless ($rv) {
		if (exists $w_attr->{$type}->{'nonVisual'}) {
			$rv =  ($w_attr->{$type}->{'nonVisual'}) ? 'nonVisual' : lc($type);
		} else {
			$rv = lc($type)
		}
	}
	return $rv;
}

sub tree_repaint {
	return ctkWidgetTreeView->repaint(@_);
}

sub isGeomMgrSupported {
	my ($manager) = @_;
	my $rv;
	&main::trace("isGeomMgrSupported");

	$rv =  1 if (grep $manager eq $_, @$geomMgr);
	return $rv
}

sub geomForget {
	my ($widget) = @_;
	my $rv;
	$widget = &main::selectedWidget unless (defined($widget));
	&main::trace("geomForget");

	my $m = $widget->manager;
	unless (&isGeomMgrSupported($m)) {
		&main::log("Geometry handler '$m' not yet supported, cannot forget '$widget'");
		return undef
	}
	if ($m eq 'pack') {
		$widget->packForget(); $rv = 1
	} elsif ($m eq 'grid') {
		$widget->gridForget(); $rv = 1
	} elsif ($m eq 'place') {
		$widget->placeForget(); $rv = 1
	} elsif ($m eq 'form') {
		$widget->formForget(); $rv = 1
	} else {}
	return $rv
}

sub geomInfo {
	my ($widget) = @_;
	my @rv;
	$widget = &main::selectedWidget unless (defined($widget));
	&main::trace("geomInfo");

	my $m = $widget->manager;
	unless (&main::isGeomMgrSupported($m)) {
		&main::log("Geometry handler '$m' not yet supported, could not Info '$widget'");
		return undef
	}
	if ($m eq 'pack') {
		@rv = $widget->packInfo()
	} elsif ($m eq 'grid') {
		@rv = $widget->gridInfo()
	} elsif ($m eq 'place') {
		@rv = $widget->placeInfo()
	} elsif ($m eq 'form') {
		@rv = $widget->formInfo()
	} else {}
	return wantarray ? @rv : scalar(@rv);
}

=head3 hideWidget

	Send packForget to the widget in order to unmap the widget.

=cut

sub hideWidget {
	my $rv;
	&main::trace("hideWidget");

	return undef if (&main::selectedIsMW);
	my $id = &main::path_to_id();
	return undef if (&main::isHidden($id));
	if (&main::haveGeometry()) {
		if (&geomForget()){
			push @$hiddenWidgets, $id;
			&main::trace("'$id' now hidden.");
			&main::changes(1);
			&main::tree_repaint();
			$rv = 1;
		} else {
			&std::ShowWarningDialog("Cannot hide widget ($id),\nprobably geometry manager is not (yet) supported by clickTk.");
		}
	} else {
		&std::ShowWarningDialog("Cannot hide widget ($id) which is not managed by the geometry handler.");
	}
	return $rv
}

sub isHidden {
	my ($id) = @_;
	my $rv;
	&main::trace("isHidden");

	$id = main::path_to_id() unless defined($id);

	$rv = 1 if (grep ($_ eq $id, @$hiddenWidgets));

	return $rv
}

sub unhide {
	my ($id) = @_;
	my $rv;
	&main::trace("unhide");

	$id = main::path_to_id() unless defined($id);
	return undef unless isHidden($id);

	my $i = @$hiddenWidgets;
	while (--$i >= 0) {
		if ($hiddenWidgets->[$i] eq $id) {
			splice @$hiddenWidgets,$i,1;
			last
		}
	}
	do {
		&main::changes(1);
		&main::tree_repaint();
		## &main::preview_repaint();
	} if ($i >= 0);
	$rv = ($i >= 0) ? 1 : undef;
	return $rv
}

sub view_defaultOptions {
	&main::trace("view_defaultOptions");
	return if (&main::selectedIsMW);
	my $id=&main::path_to_id();
	my $a = TkAnalysis->new(hwnd => $mw, debug => $debug);
	$a->viewDefaultOptions(undef,ctkProject->descriptor->{$id}->{type});
}

sub viewAllOptions {
	&main::trace("view_defaultOptions");
	return if (&main::selectedIsMW);
	my $a = TkAnalysis->new(hwnd => $mw, debug => $debug);
	my $id=&main::path_to_id();
	$a->viewCurrentOptions(undef,&main::selectedWidget,"$id - ctkProject->descriptor->{$id}->{type}");
}

sub view_geomInfo {
	&main::trace("view_geomInfo");
	return undef if (&main::selectedIsMW);
	my @list = &main::geomInfo();
	if (@list) {
		&std::dlg_geomInfo($mw, info => \@list);
	} else {
		&std::ShowWarningDialog("Could not get widget information (".&main::getSelected."),\nprobably geometry manager is not (yet) supported by clickTk.");
	}
}

sub viewLogFile {
	return &std::dlg_viewLogFile(@_);
	}


sub addWidgetClassDef {
	my $workWidget = ctkWidgetLib->new('widgets' => $w_attr,widgetlib => $widgetFolder);
	my $rv;
	if ($rv = $workWidget->register($mw,undef)) {
		&std::ShowInfoDialog("Widget class '".$workWidget->class."' registered.");
	} ## else {}
	return $rv
}

sub updateWidgetClassDef {
	my @widgets = sort keys(%$w_attr);

	my $widgetClass = &std::dlg_getWidgetClass($mw,'-widgets',\@widgets); ## select widget first
	return undef unless(defined($widgetClass));
	my $rv;
	my $workWidget = ctkWidgetLib->new('widgets' => $w_attr, 'class' => $widgetClass);
	## TODO : check if this class is actually used in the project.
	##			if so then ask user what next (save first, continue,dismiss)
	if ($rv = $workWidget->register($mw,$widgetClass)) {
		&std::ShowInfoDialog("Widget class '$widgetClass' updated.");
	} ## else {}
	return $rv
}

sub deleteWidgetClassDef {
	my @widgets = sort keys(%$w_attr);
	my $rv;
	my $widgetClass = &std::dlg_getWidgetClass($mw,'-widgets',\@widgets); ## select widget first
	return undef unless(defined($widgetClass));
	my $w;
	## TODO : check if this class is actually used in the project
	##			if so then ask user what next (save first, continue,dismiss)
	if (&std::askYN("Do you want really delete '$widgetClass' ?")) {
		my $workWidget = ctkWidgetLib->new('widgets' => $w_attr, 'class' => $widgetClass,widgetlib => $widgetFolder);
		if ($workWidget->deleteWidgetClass($widgetClass)) {
			&std::ShowInfoDialog("Widget class '$widgetClass' deleted.");
			$rv = 1;
		} ## else {}
	} else {
		return undef ## delete dismissed
	}
	return $rv
}

=head2 Clipboard operations

=over

=item Rules

	 1. Clipboard data consistency (check for signature line)

	 2. All clipboard operations can be performed on single
	    widget selection (and all it's sub-widgets).

	 3. When placing to clipboard the data must be 'transferred'
	    to root hierarchy level by substitution of 'parent' for
	    selected widget.

	 4. While pasting data from clipboard 1st of all the type of
	    the selected widget (target) must be checked in order to
	    decide if it can accept the pasted widget.

	 5. Next check is for possible geometry management conflicts
	    between widget to be inserted and context. User can
	    choose one of following: 'propagate' | 'adopt' | 'cancel'.

	 6. Last check must be done per widget to be inserted:
	    does it's ID conflicting with existing widgets?
	    In case of conflict the widget must be renamed (main::ask_new_id_for_paste).

=item Class

	Module ctkClipboard.pm models the clipboard object.

=item Methods in the package main

	These methods implements the use of the clipboard.
	On start up a clipboard operation they first instantiate
	ctkClipboard to get access to the clipboard itself.

		edit_cut
		edit_copy
		edit_delete
		edit_paste
		edit_replace
		ask_new_id_for_paste
		_adapt

=back

=cut

sub edit_cut {
	&main::trace("edit_cut");
	return if (&main::selectedIsMW);
	# store selected:
	&edit_copy;
	# delete selected:
	&edit_delete;
}

sub edit_copy {
	&main::trace("edit_copy");
	return if (&main::selectedIsMW);
	my $id=&main::path_to_id();
	my $clipboard = ctkClipboard->new(-clear => 1);
	return undef unless(defined $clipboard);

	$clipboard->clipboardAppend(
		join('|',
			ctkProject->descriptor->{$id}->parent,
			$id,
			ctkProject->descriptor->{$id}->type,
			ctkProject->descriptor->{$id}->geom
		));
	my @copy_id;
	if ($opt_copyChildren) {
		# get all IDs of copied widgets:
		@copy_id=grep(/(^|\.)$id(\.|$)/,@ctkProject::tree);
	} else {
		@copy_id=grep(/(^|\.)$id$/,@ctkProject::tree);
	}
	$clipboard->clipboardAppend('#'.join('|',@copy_id));
	map{
		my $id = &main::path_to_id($_);
		$clipboard->clipboardAppend(&gen_WidgetCode($id))
	} @copy_id;
}

sub _adapt {
	my ($old_parent,$old_id,$new_parent,$new_id,$s) = @_;
	$s =~ s/=\s*\$($old_parent)/=\$$new_parent/; # rename parent for pasted widget
	$s =~ s/^\s*\$($old_id)/\$$new_id/ if(defined($new_id)); # rename pasted widget
	return $s
}

sub edit_paste {
	&main::trace("edit_paste");
	my $new_id;
	my $old_id;
	my $id=&main::path_to_id();

	my $clipboard = ctkClipboard->new();

	return undef unless(defined $clipboard);

	return undef unless($clipboard->clipboard);

	my @clipboard = $clipboard->clipboard;

	my @new_names = ();

	unless ($clipboard->checkClipboard){
	  &std::ShowErrorDialog("clickTk clipboard is corrupted!");
	  return undef;
	}
	# check type conflict:
	my $parent=ctkProject->descriptor->{$id};		## use the selected widget as new parent
	my $parent_type=$parent->type;
	my ($clp_parent,$clp_id,$clp_type,$clp_geom)=split(/\|/,shift(@clipboard));
	if(
		($clp_type eq 'NoteBookFrame' && $parent_type ne 'NoteBook') ||
		($clp_type eq 'Menu' && $parent_type !~ /^(Menubutton|cascade)$/) ||
		($parent_type ne 'Menu' && $clp_type =~ /^(cascade|command|checkbutton|radiobutton|separator)$/))
	{
		&std::ShowErrorDialog("Clipboard <-> destination type conflict ($clp_type,$parent_type)!");
		return;
	}
	# check name conflict:
	$clipboard[0]=~s/^#//;
	my $ix = 1;
	my @new_clipboard =($clipboard[0]);
	my @clp_widgets = split(/\|/,$clipboard[0]);

	$old_id = &main::path_to_id($clp_widgets[0]);
	shift @clp_widgets;

	map(s/^.+\.$old_id/$old_id/,@clp_widgets);	## make relative
	map{
		my @w = split /\./;
		while( @w > 2) { shift @w } ;
		$_ = \@w;
	} @clp_widgets;		## convert to 2dim array


	my $new_parent = $id;
	if(exists ctkProject->descriptor->{$old_id}) {
			$new_id=&main::generate_unique_id(ctkProject->descriptor->{$old_id}->type);
			$new_id=&ask_new_id($new_id,ctkProject->descriptor->{$old_id}->type); ## assign a new ID
			return undef unless (defined($new_id));
			push @new_names,"$old_id|$new_id";
			push @new_clipboard,&main::_adapt($clp_parent,$old_id,$new_parent,$new_id,$clipboard[$ix]);
		} else {
			$new_id = $old_id ;
			push @new_clipboard,$clipboard[$ix];
		}

	$ix++;
	for (my $i = 0; $ix < @clipboard; $i++,$ix++) {
		$clp_parent = $clp_widgets[$i]->[0];
		my ($old_id,$new_id);

		$old_id = $clp_widgets[$i]->[1];
		if(exists ctkProject->descriptor->{$old_id}) {
			$new_id=&main::generate_unique_id(ctkProject->descriptor->{$old_id}->type);
			$new_id=&ask_new_id_for_paste($new_id,ctkProject->descriptor->{$old_id}->type,$old_id); ## assign a new ID
			return undef unless (defined($new_id));
			if ($new_id) {
				push @new_names,"$old_id|$new_id";
				my @renamed = grep(/^$clp_parent/, @new_names);
				if (@renamed == 1) {
					$new_parent = $1 if ($renamed[0] =~ /\|(.+)$/);
				}
				push @new_clipboard,&main::_adapt($clp_parent,$old_id,$new_parent,$new_id,$clipboard[$ix]);
			} else {}
		} else {
			$new_id = $old_id ;		## widget may has been deleted by means of <ctrl-x>
			push @new_clipboard,$clipboard[$ix];
		}
	}
	@clipboard = @new_clipboard;
	my $reply = '';
	# check geometry conflict:
	if ($clp_geom) {
		my $clp_geom_patt=$clp_geom;
		$clp_geom_patt =~ s/\(.*$//; ## isolate manager

		## my @allBrothers =&tree_get_sons($parent);
		my @wBrothers = &main::getBrotherToBeCheckedForGeom($clp_id);
		my @brothers = ();
		map {
			push @brothers,ctkProject->descriptor->{$_}->geom
		} @wBrothers ; # get their geometry

		## get rid of brother which dont have geom!

	if (grep(!/^$clp_geom_patt/,@brothers)) {
	    # if any of brothers does not match:
	    # Ask user about possible conflict solution
	    # 'Propagate' | 'Adopt' | 'Cancel'
	    # return on 'Cancel'
		my @w= ();
		map {
				push @w, $_ if (ctkProject->descriptor->{$_}->geom !~ /^$clp_geom_patt/);
		} @wBrothers;
		my $reply = askUserForGeom($new_id,$clp_geom_patt,join(',',@w));
	    return undef if ($reply eq 'Cancel');
	  }
	}

	shift(@clipboard);

	$clipboard[0] =~ s/=\s*\$($clp_parent)/=\$$id/; # rename parent for pasted widget
	$clipboard[0] =~ s/^\s*\$($old_id)/\$$new_id/ if(defined($new_id)); # rename pasted widget

	&main::undo_save();	 # Save undo information:

	&parseTargetCode(\@clipboard,'splice'); # insert here
	&main::log("widget '$new_id' pasted.");

	if ($reply eq 'Propagate') {
		foreach (&tree_get_brothers($new_id)) {
			ctkProject->descriptor->{$_}->geom(ctkProject->descriptor->{$new_id}->geom) if (&main::haveGeometry($_));
		}
	} else {}
	if ($reply eq 'Adopt') {
		my @w= &main::getBrotherToBeCheckedForGeom($clp_id);
		ctkProject->descriptor->{$new_id}->geom(ctkProject->descriptor->{$w[0]}->geom)
	}

	&main::changes(1);
	&main::set_selected(&main::getSelected);
}

sub edit_delete {
	&main::trace("edit_delete");
	my @deleted=();
	if (&main::selectedIsMW) { # say something to user here:
		&std::ShowErrorDialog("You cannot delete $MW,\nuse File/New instead if you want delete all widgets.");
		return undef;
	}
	my $parent_path;
	my $w = &main::path_to_id();
	if (exists ctkProject->descriptor->{$w}) {
		my $parent = (ctkProject->descriptor->{&main::path_to_id()}->parent);	# save parent for position
		$parent_path = &main::id_to_path($parent) ;
	} else {
		&std::ShowErrorDialog("Missing descriptor for '".&main::getSelected."',\npls check widget definitions resp. generated code.");
	}
	&main::undo_save(); # save current state for undo

	# 1. remove internal structures (including sub-widgets)
	my $_sel = &main::getSelected;
	if (&std::askYN("Do you want really delete '$w' ?")) {
		foreach my $d (grep(/$_sel/,@ctkProject::tree)) {
			my $id=$d; $id=~s/.*\.//;
			## undef %{ctkProject->descriptor->{$id}} if(ref ctkProject->descriptor->{$id});
			delete ctkProject->descriptor->{$id};
			push @deleted, $id
			}
		} else {
			return undef ## delete dismissed
		}
	@ctkProject::tree = grep(!/$_sel/,@ctkProject::tree);
	# 2. remove from tree
	ctkWidgetTreeView->delete('entry',$_sel);
	map {
		main::unhide($_);
		main::log("Widget '$_' deleted");
	} @deleted;
	$parent_path = $MW unless defined($parent_path);

	&main::changes(1);
	&main::set_selected($parent_path) ;
	ctkWidgetTreeView->selectionSet(&main::getSelected);

	return 1
}

=head2 edit_updateAllOptions

	Edit all options of the selected widget.

=cut

sub edit_updateAllOptions {
	&main::trace("edit_updateAllOptions");
	return undef if (&main::selectedIsMW);
	my $rv;
	my $id=&main::path_to_id();
	my $a = TkAnalysis->new(hwnd => $mw, debug => $debug);
	my @opt = $a->updateAllOptions(&main::selectedWidget,&std::_title("$id - ctkProject->descriptor->{$id}->{type}"));
	if (@opt) {
		&main::trace("Updating widget $id - ctkProject->descriptor->{$id}->{type}");
		my $w   = &main::selectedWidget;
		my $pr  = $w_attr->{ctkProject->descriptor->{$id}->type}->{attr};
		my $d   = ctkProject->descriptor->{$id};
		my (%val) = &main::split_opt($d->opt);
		foreach (@opt) {
			next unless (defined($_->[1]));
			next if($_->[1] =~ /^\s*$/);
			my $n   = $_->[0];
			my $cur   = $_->[1];
			$pr->{$n} = 'text' unless(exists $pr->{$n});
			if (exists $val{$n}) {
				if ($cur ne $val{$n}) {
					$val{$n} = $cur; ## take over if ne
					$rv++;
					&main::trace("option updated : $n => '$cur'");
				} else {} ## already set and unchanged
			} else {
				$val{$n} = $cur;
				$rv++;
				&main::trace("option added : $n => '$cur'");
			}
		}
		if ($rv) {
			&main::undo_save();
			## map {my $w = $val{$_};$val{$_} = "'$w'" if($w =~ /\s/)}keys %val;
			if(ctkProject->descriptor->{$id}->type =~ /^Scrolled/) {
				my ($w) = ctkProject->descriptor->{$id}->type =~ /^Scrolled(.+)/ ;
				$w = "'$w' , ". &main::buildWidgetOptionsOnEdit(\%val);
				$d->opt($w)
			} else {
				$d->opt(&main::buildWidgetOptionsOnEdit(\%val));
			}
			&main::changes(1);
			&main::unhide($id) if (&main::isHidden($id));
			&main::trace("$rv options updated.");
		} else{
			&main::trace("No options updated.");
		}
	} else {
		&main::trace("No updates saved.");
	}
	return $rv
}

sub insert {
	my ($where) = @_; # qw(before after subwidget frame nonVisual)
	my $rv;
	&main::trace("insert where = '$where'");

	my $pic = $picW;
	my $newNonVisual = ' -- New -- ';

	return undef if(&main::selectedIsMW && $where ne 'subwidget' && $where ne 'frame' && $where ne 'nonVisual');

	my @legalWidgets =();

	## 0. process framing & nonVisual

	if ($where eq 'frame') {
		my $id=&main::path_to_id();
		my $type = ctkProject->descriptor->{$id}->type;
		unless ($id eq $MW || $type =~ /Frame|LabFrame/i) {
			return undef unless (std::askYN("Widget '$id' class '$type' may not be the right one to contain frames,\ncontinue anyway?"))
		}
		$rv = &main::insertFrame();
		return $rv
	} elsif ($where eq 'nonVisual') {
		@legalWidgets = grep(&main::nonVisual($_),keys %$w_attr);
		@legalWidgets = sort @legalWidgets;
		unshift @legalWidgets, $newNonVisual;
	} else {
		# determine where insertion point is
		# if it's menu/menubutton/cascade - change legalWidgets to respective array
		# Menubutton -> Menu
		# Menu,cascade -> cascade,command,checkbutton,radiobutton,separator
		my $parent=&main::path_to_id();
		$parent = ctkProject->descriptor->{$parent}->parent if ($where ne 'subwidget');  # go up one level
		if (ctkProject->descriptor->{$parent}->type eq 'NoteBook'){
			$rv = &main::do_insert($where,'NoteBookFrame');
			return $rv;
		}
		return $rv if ctkProject->descriptor->{$parent}->type =~ /^(command|checkbutton|radiobutton|separator)$/;
		return $rv if $legalWidgets[0] eq 'Menu' && &tree_get_sons($parent);
		@legalWidgets = &main::getLegalWidgets($parent,&main::getSelected);
	}

	# 1. ask for widget type
	my $db=$mw->ctkDialogBox(-title => 'Create '.$where.' '.&main::getSelected ,-buttons=>['Cancel']); ## u MO0xx05!perl!

	my $type=$legalWidgets[0];
	my $reply;
	my $i=0;
	my $imgName;
	my $w0 = 0;
	map {
		$w0 = length($_) if (length($_) > $w0)
	}@legalWidgets;
	my $f=$db->LabFrame(-labelside => 'acrosstop' , -label => 'Widgets', -relief => 'ridge')->pack(-expand => 1, -fill=>'both',-padx=>10,-pady=>10);
	my $tiler = $f->Scrolled('Tiler', -columns => 4, -scrollbars=>'oe')->pack(-expand => 1, -fill => 'both');
	foreach my $lw (@legalWidgets) {
		my $frb = $f->Frame();
		$imgName = (exists $pic->{lc($lw)}) ?  lc($lw) : 'default';
		$imgName = lc($w_attr->{$lw}->{'icon'}) if(exists $w_attr->{$lw}->{'icon'} && $w_attr->{$lw}->{'icon'} =~ /\w+/);
		$imgName = 'missing' unless (exists $pic->{$imgName});

		my $b1 = $frb->Button(
			-command =>[sub{
			$type = shift;
			$db->Subwidget('B_Cancel')->invoke;
			},$lw
			],
			-anchor => 'nw'
			);
		&std::buildAndSetCompoundImage($b1,-image => $pic->{$imgName},-text => $lw);
		$b1->pack(-side => 'top',-anchor => 'nw',-expand => 1, -fill => 'x', -padx => 5, -pady => 5);
		$tiler->Manage($frb);
	}
	$db->resizable(1,1);
	&main::recolor_dialog($db);
	$type = undef;
	$mw->bind('<Return>','');
	$reply = $db->Show();
	return undef unless(defined($type) && $type =~ /\w+/);

	if ($type eq $newNonVisual) {
		$type = &std::ask_new_nonVisual($w_attr);
		if (defined ($type)) {
			unless (exists $w_attr->{$type}) {
				my $workWidget = ctkWidgetLib->new('widgets' => $w_attr,widgetlib => $widgetFolder);
				$w_attr->{$type} = $workWidget->createNonVisualClass($type);
				$w_attr->{$type}->{'file'} = "$type";
				$workWidget->save($type);
				$workWidget->destroy;
			}
		} else {
			return undef
		}
	}
	my $id = &do_insert($where,$type);
	return undef unless (defined($id));
	&main::Log("widget '$id' inserted");
	&main::set_selected($id);
	## set default options
	&main::edit_widgetOptions() if ($main::autoEdit);
	return 1
}

sub getLegalWidgets {
	my ($parent, $widget) = @_;
	my @rv;
	$widget = &main::getSelected unless defined ($widget);
	$parent = &main::path_to_id($widget) unless defined $parent;
	if(ctkProject->descriptor->{$parent}->type =~ /^(Menubutton|cascade)$/) {
		@rv = ('Menu')
	} elsif (ctkProject->descriptor->{$parent}->type eq 'Menu') {
		@rv = (qw/cascade command checkbutton radiobutton separator/);
	} else {
		if ($widget eq $MW) {
			@rv = keys %$w_attr;
		} else {
			@rv = (grep(&main::haveGeometry($_),keys %$w_attr),'packAdjust');
		}
	}
		return wantarray ? sort @rv : scalar(@rv)
}

sub setDefaultWidgetOptions {
	my ($type,$id) = @_;
	my @rv = ();
	foreach my $k (keys %{$w_attr->{$type}->{attr}}) {
		# text fields
		next if $k =~ /^-(accelerator|show|command|createcmd|raisecmd|textvariable|variable|onvalue|offvalue)$/;
		push(@rv,"$k, $id") if($w_attr->{$type}->{attr}->{$k}=~/text/);
	}
	if (&main::defaultWidgetOptions($type)) {
		@rv = &main::split_opt(&main::defaultWidgetOptions($type));
	} else {
		push(@rv,'-scrollbars, se') if $type =~ /^Scrolled\w*$/;
		push(@rv,'-relief, flat') if $type =~ /^(Label|Menubutton|Checkbutton|Radiobutton|Scale|Message)$/;
		push(@rv,'-relief, sunken') if $type =~ /^(BrowseEntry|Entry|Text|ROText|ScrolledText|ScrolledTextUndo|ScrolledROText|Listbox|ScrolledListbox|LabEntry)$/;
		push(@rv,'-relief, ridge') if $type =~ /^(LabFrame)$/;
		push(@rv,'-indicatoron, 1') if $type =~ /^(Radiobutton|Checkbutton)$/;
	}
	return wantarray ? @rv : \@rv;
	}

sub do_updateOrder {
	return undef unless (&main::getSelected);
	&main::trace("do_updateOrder","selected = '".&main::getSelected."'");
	my $id=&main::path_to_id();
	if ($id eq $MW) {
		&std::ShowWarningDialog("Order are not (yet) allowed at this level.");
		return undef  ;
	}
	my $order = ctkProject->descriptor->{$id}->order;
	my $type = ctkProject->descriptor->{$id}->type;
	my $answer = &std::dlg_getOrder($mw,$id,$type,$order);
	if (defined $answer) {
		$answer = &main::alltrim($answer);
		if ($answer ne $order) {
			ctkProject->descriptor->{$id}->order($answer);
			&main::changes(1);
			&main::trace("order changed for '$id'");
		} else {
			&main::trace("order let unchanged for '$id'");
		}
	} else {
		## dismissed, continue
	}
	return 1
}

sub do_insert {
	my ($where,$type)=@_;
	my $rv;
	my $order = '';
	&main::trace("do_insert","where = '$where', type = '$type'");
	# 1. Find selected element index in @ctkProject::tree
	my $i=&main::index_of(&main::getSelected);
	my $j=$i+1;
	$j=$i if $where eq 'before';
	if($where eq 'subwidget')  { # insert after last sub-entry
		my $_sel = &main::getSelected;
		while ($ctkProject::tree[$j] =~ /(^|\.)$_sel(\.|$)/) {
		$j++
		}
	}
	my $id=&main::generate_unique_id($type);
	# 2. Ask user for human-readable name here:
	if($opt_askIdent) {
		return undef unless ($id=&ask_new_id($id,$type));
	} ## else {}
	# 3. save current state for undo
	&main::undo_save();
	my $parent=&main::path_to_id();
	$parent = ctkProject->descriptor->{$parent}->parent
	  if($where ne 'subwidget');  # go up one level
	# 4. Create descriptor
	my ($insert_path)=grep(/(^|\.)$parent$/,@ctkProject::tree);
	$insert_path=$MW unless $insert_path;
	my @w_opt=();

	# 5. Set up default widget's values:

	@w_opt = &main::setDefaultWidgetOptions($type,$id);
	&main::trace("default options = ",@w_opt);

	## 7. Set up geometry

	my $geom='';
	if (&main::haveGeometry($type)) {
		my $o = &main::defaultGeometryOptions($type);
		my $m = &main::defaultGeometryManager($type);
		$m = $defaultGeometryManager unless($m);
		$geom ="$m ( $o ) ";
		&main::trace("default geom = '$geom'");

		# resolving geometry conflicts: get geometry from 'brothers'
		my @brothers =&tree_get_sons($parent);
		foreach (@brothers) {
				if (&main::haveGeometry(ctkProject->descriptor->{$_}->type)) {
					$geom = ctkProject->descriptor->{$_}->geom;
					&main::log("geom inherited from '$_'");
					last
				}
				}
		&main::trace("applied geom = '$geom'");
	}

	# 8. Add data to internal structures according to gathered parameters:

	ctkProject->descriptor->{$id}=&main::createDescriptor($id,$parent,$type,join(', ',@w_opt),$geom,$order);

	splice(@ctkProject::tree,$j,0,"${insert_path}.$id");

	# 9. Update the display of the widget's tree

	my $pic = $picW;
	my $picN = getWidgetIconName($id);
#	if($where eq 'subwidget') {				## d MO03606
#		ctkWidgetTreeView->add("${insert_path}.$id",-text=>$id,
#				-data=>"${insert_path}.$id",-image => $pic->{$picN}); ## -image=>$pic->{lc($type)});
#	} elsif($where =~/before|after/i) {
#		ctkWidgetTreeView->add("${insert_path}.$id","-$where"=>&main::getSelected,-text=>$id,
#				-data=>"${insert_path}.$id",-image => $pic->{$picN}); ##-image=>$pic->{lc($type)})
#	} elsif ($where =~/nonvisual/i) {
#		ctkWidgetTreeView->add("${insert_path}.$id",-text=>$id,
#				-data=>"${insert_path}.$id",-image => $pic->{$picN}); ##-image=>$pic->{'nonvisual'});
#	} else {
#		## unexpected
#	}

	# For menu-related elements automatically create 'Menu':
	$rv = $id;
	if($type =~ /^(Menubutton|cascade)$/)
	{
		$parent=$id;
		$id=&main::generate_unique_id('Menu');
		ctkProject->descriptor->{$id}=&main::createDescriptor($id,$parent,'Menu','','',$order);
		splice(@ctkProject::tree,$j+1,0,"${insert_path}.$parent.$id");
		ctkWidgetTreeView->add("${insert_path}.$parent.$id",-text=>$id,
				-data=>"${insert_path}.$parent.$id",-image=>$pic->{lc('Menu')});
	}
	&main::changes(1);
	return $rv;
}

sub frameMenu {
	my ($where,$pvar,$balloon) = @_;
	&main::trace("frameMenu");
	my $mnb = $where->Menubutton(-direction=>'below',-cursor=>'left_ptr');
	## &main::cnf_dlg_ballon($balloon,$mnb,'-frame') if $balloon;
	my $mnu = $mnb->menu(qw/-tearoff 0/); $mnb->configure(-menu => $mnu);
	my @fName = (qw/SingleFrame SplitFrameV SplitFrameH/);
	$mnb->configure(-image=>&main::map_pic(lc($$pvar),''));
	foreach my $r (@fName) {
	  $mnu->command(-label=>$r,
	                -image=>&main::map_pic(lc($r),''),
	                -columnbreak=>1,
	                -command=>sub{
	                      $$pvar=$r;
	                      $mnb->configure(-image=>&main::map_pic(lc($r),''));
	                      });
	}
	return $mnb;
	# end SideMenu
}

sub do_insertFrame {
	my ($where,$type,$framing)=@_;
	my $rv;
	my $order = '';
	my $pic = $picW;

	&main::trace("do_insertFrame where = '$where', type = '$type'");

	# 1. Find selected element index in @ctkProject::tree

	my $i=&main::index_of(&main::getSelected);
	my $j=$i+1;
	if($where eq 'subwidget')  { # insert after last sub-entry
		my $_sel = &main::getSelected;
		while ($ctkProject::tree[$j] =~ /(^|\.)$_sel(\.|$)/) {
		$j++
		}
	}
	my $id=&main::generate_unique_id($type);

	# 3. save current state for undo

	&main::undo_save();

	my $parent=&main::path_to_id();
	$parent = ctkProject->descriptor->{$parent}->parent if($where ne 'subwidget');  # go up one level

	# 4. Create descriptor

	my ($insert_path)=grep(/(^|\.)$parent$/,@ctkProject::tree);
	$insert_path=$MW unless $insert_path;
	my @w_opt=();

	# 5. Set up default widget's values:

	@w_opt = &main::setDefaultWidgetOptions($type,$id);
	&main::log("default options = ",@w_opt);

	if ($type =~/LabFrame/i) {
		unless (grep /-labelside/ , @w_opt) {
			push @w_opt, ('-labelside', 'acrosstop')
		}
	}
		## 6. Set up geometry

	my $geom='';
	my $o = "-side , %%side%%, -anchor , nw, -fill , both, -expand , 1";
	my $m = 'pack';
	if ($framing =~ /singleFrame/i) { $o =~ s/%%side%%/top/
	} elsif($framing =~ /splitFrameH/i){ $o =~ s/%%side%%/top/
	} elsif($framing =~ /splitFrameV/i){ $o =~ s/%%side%%/left/
	} else {}

	$geom ="$m ( $o ) ";

	&main::trace("default geom = '$geom'");

	# 7. resolving geometry conflicts: get geometry from 'brothers'
	my @brothers =&tree_get_sons($parent);
	foreach (@brothers) {
				if (&main::haveGeometry(ctkProject->descriptor->{$_}->type)) {
					$geom = ctkProject->descriptor->{$_}->geom;
					&main::log("geom inherited from '$_'");
					last
				}
	}
	&main::trace("applied geom = '$geom'");

	# 8. Add data to internal structures according to gathered parameters:

	ctkProject->descriptor->{$id}=&main::createDescriptor($id,$parent,$type,join(', ',@w_opt),$geom,$order);

	splice(@ctkProject::tree,$j,0,"${insert_path}.$id");

	# 9. Update tree view

	if($where eq 'subwidget')
	{
	  ctkWidgetTreeView->add("${insert_path}.$id",-text=>$id,
			  -data=>"${insert_path}.$id",-image=>$pic->{lc($type)});
	}
	else
	{
	  ctkWidgetTreeView->add("${insert_path}.$id","-$where"=>&main::getSelected,-text=>$id,
	    -data=>"${insert_path}.$id",-image=>$pic->{lc($type)})
	}

	&main::changes(1);
	return $rv;
}

sub insertFrame {
	my $rv;
	&main::trace("insertFrame");
	my $f = 'SingleFrame';
	my $labFrame = 0;
	my $db = $mw->ctkDialogBox(-title => "Insert/split frame",-buttons=>['Ok','Cancel']);
	my $f1 = $db->Frame()->pack(-side, 'top');
	my $f2 = $db->Frame()->pack(-side, 'top');
	$f1->Label(-text,"Select frame structure.")->pack(-side, 'left', -anchor , 'w');
	my $mf = &main::frameMenu($f1,\$f,0)->pack(-side, 'left');
	my $mft = $f2->Checkbutton ( -relief , 'flat' , -variable , \$labFrame , -state , 'normal' , -justify , 'left' ,-anchor, 'w', -text , 'Use LabFrame' , -onvalue , 1  )->pack(-side, 'top',-anchor, 'w');
	&main::recolor_dialog($db);
	my $ans = $db->Show();
	return undef if ($ans =~/Cancel/i);
	my $frameClass = ($labFrame) ? 'LabFrame' : 'Frame';
	if ($f =~ /SingleFrame/i) {
			$rv = &main::do_insertFrame('subwidget',$frameClass,$f)
	} elsif ($f =~ /SplitFrameV/i) {
			$rv = &main::do_insertFrame('subwidget',$frameClass,$f);
			$rv = &main::do_insertFrame('subwidget',$frameClass,$f)
	} elsif ($f =~ /SplitFrameH/i) {
			$rv = &main::do_insertFrame('subwidget',$frameClass,$f);
			$rv = &main::do_insertFrame('subwidget',$frameClass,$f)
	} else {
	}
	return $rv
}

sub ask_new_id {
	my ($id,$type)=(@_);
	&main::trace("ask_new_id id, default='$id', type = '$type'");
	my $se;
	do {
		$id = &std::dlg_ask_new_id($id,$type);
		return undef  unless(defined($id));

		$id =~ s/^\s+//; $id =~ s/\s+$//;
		if (exists ctkProject->descriptor->{$id}) {
			&std::ShowErrorDialog("Entered ident already exists,\n pls check and enter a different ident.");
			$se = 1
		} else {
			eval "{my \$$id = 0;}";
			if ($@) {
				&main::trace("eval syntax error checking '$id':", $@);
				&std::ShowErrorDialog("Syntax error,\n entered ident is not valid, pls correct.");
				$se = 1;
			} else {
				$se = 0
			}
		}
	} while($se || exists ctkProject->descriptor->{$id} || $id =~ /^\s*$/);
	&main::trace("ident = '$id'");
	return $id;
}

sub ask_new_id_for_paste {
	my ($id,$type,$old_id) = @_;
	&main::trace("ask_new_id_for_paste id, default='$id', type = '$type', old_id = '$old_id'");
	my $se;
	do {
		my $db=&main::getmw->ctkDialogBox(-title=>"New ident for $type widget ($old_id)",-buttons=>[qw/Proceed skip Cancel/]);
		$db->LabEntry(-textvariable=>\$id,-labelPack=>[-side=>'left',-anchor=>'w'],
						-label=>'Widget ident ')->pack(-pady=>20,-padx=>30);
		$db->resizable(1,0);
		&main::recolor_dialog($db);
		my $reply = $db->Show();
		return undef  if( $reply =~ /Cancel/i);
		return ' ' if($reply =~ /skip/i);

		$id =~ s/^\s+//; $id =~ s/\s+$//;
		if (exists ctkProject->descriptor->{$id}) {
			&std::ShowErrorDialog("Entered ident already exists,\n pls check and enter a different ident.");
			$se = 1
		} else {
			eval "{my \$$id = 0;}";
			if ($@) {
				&main::trace("eval syntax error checking '$id':", $@);
				&std::ShowErrorDialog("Syntax error,\n entered ident is invalid, pls correct.");
				$se = 1;
			} else {
				$se = 0
			}
		}
	} while($se || exists ctkProject->descriptor->{$id} || $id =~ /^\s*$/);
	&main::trace("ident = '$id'");
	return $id;
}

sub generate_unique_id {
	return ctkProject->generate_unique_id(@_);
}

sub rename {
	&main::trace("rename");
	my $old_id=&main::path_to_id();
	my $id=$old_id;
	return if $id eq $MW;
	$id=&ask_new_id($id,ctkProject->descriptor->{$id}->type);
	return unless $id;

	# save current state for undo
	&main::undo_save();
	# Read generated program and globally substitute $old_id with new one
	my $code = &main::gen_TkCode();
	map {
	  s/\$($old_id)(\W)/\$$id$2/g
	} @$code;
	&main::struct_new();
	&main::parseTargetCode($code);
	&main::changes(1);
}

sub ask_new_type {
	my ($id,$type) = @_;
	&main::trace("ask_new_type id = $id, type = $type");
	my $se;
	my $db=$mw->ctkDialogBox(-title=>"Class name for widget $id ",-buttons=>['OK','Cancel']);
	$db->LabEntry(-textvariable=>\$type,-labelPack=>[-side=>'left',-anchor=>'w'],
				-label=>"Replace class name '$type' with ")->pack(-pady=>20,-padx=>30);
	$db->resizable(1,0);
	&main::recolor_dialog($db);
	do
	{
		if($db->Show() eq 'Cancel') {
			return 0 ;
		} else {
			$type =~ s/^\s+//; $type =~ s/\s+$//;

			if (exists $w_attr->{$type}) {
				$se = 0
			} else {
				&main::trace("Entered class name '$type' is not (yet) supported.");
				&std::ShowErrorDialog("Entered class name is not (yet) supported,\n pls correct.");
				$se = 1
			}
		}
	} while($se);
	return $type;
}

sub edit_replace {
	&main::trace("edit_replace");
	my $id=&main::path_to_id();
	return if $id eq $MW;
	my $type;
	my $old_type=ctkProject->descriptor->{$id}->type;
	$type = &main::ask_new_type($id,$old_type);
	return unless $type;

	&main::undo_save(); 				# save current state for undo
	ctkProject->descriptor->{$id}->type($type);
	my $geom = &main::haveGeometry(ctkProject->descriptor->{$id}->type) ? ctkProject->descriptor->{$id}->geom : '';
	my $parent = ctkProject->descriptor->{$id}->parent;
	my $opt = &defaultWidgetOptions($type);
	my $order = ctkProject->descriptor->{$id}->order;
	ctkProject->descriptor->{$id}=&main::createDescriptor($id,$parent,$type,$opt,$geom,$order);

	&main::edit_widgetOptions();
	&main::changes(1);
	ctkMenu->updateMenu();
}

sub optMenuWidget {
	my ($parent,$opt,$values,$rVar) = @_;
				my $mnb = $parent->Menubutton(-underline=>0,
									-relief=>'ridge',-borderwidth=>4,
									-textvariable=>$rVar,
					-direction =>'below');
				my $mnu = $mnb->menu(-tearoff => 0);
					$mnb->configure(-menu => $mnu);
				foreach my $r (@$values) {
					$mnu->command(-label=>$r,
								-image=>$pic->{"rel_$r"},
								-command=>sub{
											$$rVar=$r;
											$mnb->configure(-relief=>$r)
											});
					}
	return $mnb;
}

=head3 validateOptions

=cut

sub validateOptions {
	my ($id,$values) = @_ ;
	my $rv;
	&main::trace("validateOptions id = '$id'");

	my %val = %$values;
	foreach (keys %val) {
		if (defined $val{$_}) {
			delete $val{$_} if ( $val{$_}=~ /^\s*$/)
		} else {
			delete $val{$_}
		}
	}
	my (@opt) = (%val);
	my $type = ctkProject->descriptor->{$id}->type;
	my $o = &main::quotatY(\@opt);

	{
		no strict;
		eval "($o)";
	}
	if ($@) {
		$rv ="syntax error '$@'";
	} elsif (grep (/^-text/,@opt) && grep(/^-image/,@opt)) {
			$rv = "Option '-text' and '-image' are mutually exclusive";
	} elsif(grep(/^-text\s*$/,@opt) && grep(/^-textvariable/,@opt)) {
			$rv = "Option '-text' and '-textvariable' are mutually exclusive";
	} else {
		main::trace("validation OK.");
	}
	&main::trace("rv='$rv'");
	return $rv
}

=head3 askUserForGeom

=cut

sub askUserForGeom {
	my ($id,$geom_type,$brothers) = @_;
	my $rv;
	&main::trace('askUserForGeom');
	$rv = &std::ShowDialogBox(-bitmap=>'warning',
			-title=>'Geometry conflict.',
			-buttons=>[qw/Propagate Reset Back Cancel/],
			-text=> "Geometry <$geom_type> for widget '$id' conflicts with\n".
					"other children of '".ctkProject->descriptor->{$id}->parent."':\n".
					$brothers."\n".
					"Pls select one of the following buttons:\n\n".
					" Propagate  propagate entered geometry options to neighbor widgets.\n".
					" Reset      reset current widget geometry to it's neighbors.\n".
					" Back       return to widget's option's window.\n".
					" Cancel     cancel your changes and exit widget's options window.");

	&main::trace("rv : '$rv'");
	return $rv;
}

=head3 edit_widgetOptions

=cut

sub edit_widgetOptions {
	return undef unless &main::getSelected;
	&main::trace("edit_widgetOptions");


	my (%w_geom) = (
		'pack'  => [qw/-side -fill -expand -anchor -ipadx -ipady -padx -pady/],
		'grid'  => [qw/-row -column -rowspan -columnspan -sticky -ipadx -ipady -padx -pady/],
		'place' => [qw/-anchor -height -width -x -y -relheight -relwidth -relx -rely/],
		'form' => [ qw/-top -right -bottom -left -padx -pady -padtop -padbottom -padleft -padright -fill/]
		);


re_enter:
	&main::trace("re_enter");
	my $id=&main::getSelected;
	$id =~ s/.*\.//;

	return undef unless (defined(ctkProject->descriptor->{$id}));
	return undef if ($id eq $MW);
	return undef if (ctkProject->descriptor->{$id}->type eq 'separator');

	my $pr = $w_attr->{ctkProject->descriptor->{$id}->type}->{attr};

	return undef unless (keys %$pr);

	map{&main::trace("pr{'$_'} = '$pr->{$_}'")} keys %$pr;

	my $d = ctkProject->descriptor->{$id};
	my @frm_pack = qw/-side left -fill both -expand 1 -padx 5 -pady 5/;
	my @pl = qw/-side left -padx 5 -pady 5/;

	my $db  = $mw->ctkDialogBox(-title=>"Widget options of '$id'",-buttons=>['Accept','Cancel','Widget doc','Geometry doc']);
	my $fbl = $db->LabFrame(-labelside=>'acrosstop',-label=>'Option\'s information')->pack(-side=>'bottom',-anchor=>'s',-expand => 1, -fill => 'x');
	my $bl  = $fbl->Label(-height=>2,-width=>80,-justify => 'left', -anchor => 'nw',-background => '#EEEEEE')->pack(-side => 'left',-padx => 0, -pady => 0, -expand => 1, -fill => 'x');

	my %val;
	my %lpack;

	if (keys %$pr) {
		my $db_lf = $db->LabFrame(-labelside=>'acrosstop',-label=>"Widget options (".$d->type.')')->pack(@frm_pack);
		my $db_lft = $db_lf->Scrolled('Tiler', -columns => 1, -scrollbars=>'oe')->pack;
		(%val) = &main::split_opt($d->opt);

		my @optPackRight=(qw/-side right -padx 7/);

		foreach my $k (sort keys %$pr) {
			my $f = $db_lf->Frame();
			$db_lft->Manage( $f );
			my $lab = $f->Label(-text => $k)->pack(-padx=>7,-pady=>5,-side=>'left');
			&main::cnf_dlg_ballon($bl,$lab,$k);
			if ($pr->{$k} eq 'color'){
				$val{$k} = '' unless (exists $val{$k});
				&main::color_Picker($f,'Color',\$val{$k},1);
			} elsif($pr->{$k} eq 'float') {
				$val{$k} = 0 unless (exists $val{$k});
				$f->Button(-text=>'+',-command=>sub{($val{$k})++})->pack(@optPackRight);
				$f->Entry(-textvariable=>\$val{$k},-width=>4)->pack(-side=>'right');
				$f->Button(-text=>'-',-command=>sub{($val{$k})--;})->pack(@optPackRight);
			} elsif($pr->{$k} eq 'int+'){
				$val{$k} = 0 unless (exists $val{$k});
				&ctkNumEntry::numEntry($f,-textvariable=>\$val{$k},-width=>4,-minvalue=>0)->pack(@optPackRight);
			} elsif($pr->{$k} eq 'text') {
				$val{$k} = '' unless (exists $val{$k});
				$val{$k} = $id if (!$val{$k} && $k =~ /^text$/);
				$f->Entry(-textvariable=>\$val{$k})->pack(@optPackRight);
			} elsif($pr->{$k} eq 'text-') {
				$val{$k} = '' unless (exists $val{$k});
				$f->Entry(-textvariable=>\$val{$k})->pack(@optPackRight);
			} elsif($pr->{$k} eq 'list') {
				$val{$k} = '' unless (exists $val{$k});
				$f->Entry(-textvariable=>\$val{$k})->pack(@optPackRight);
			} elsif($pr->{$k} eq 'file' ) {
				$val{$k} = '' unless (exists $val{$k});
				my $wE = $f->Entry(-textvariable  => \$val{$k},-bg => 'white', -width => 48); ## u MO03604
				my $wV = $val{$k};
				my $wB = $f->Button(-text=>'Browse',
							-command => [sub{
								my $file = shift;
								my $w = &main::imageFileSelect($f,$file);
								if(defined($w)) {
									$wE->delete(0,'end');
									$wE->insert('end',$w);
									$wE->update()
								} ## else {}
								},$wV]
							);
				$wB->pack(@optPackRight);
				$wE->pack(@optPackRight);
				$wE->xview('end');
			} elsif($pr->{$k} eq 'font') {
				$val{$k} = '' unless (exists $val{$k});
				my $wE = $f->Entry(-textvariable  => \$val{$k},-bg => 'white', -width => 32);	## u MO03604
				my $wV = $val{$k};
				my $wB = $f->Button(-text=>'Browse',
							-command => [sub{
								my $self = shift;
								my ($target) = @_;
								my $w = $self->ctkFontDialog(-title => "$ctkTitle - Font options", -gen => 'options',-target => $target);
								},$db,$wE]
								);
				$wB->pack(@optPackRight);
				$wE->pack(@optPackRight);
				$wE->xview('end');
			} elsif($pr->{$k} eq 'photo'){	## n MO03701
				my $widgets = &main::getWidgets;
				my @wIdent;
				map {
					push @wIdent,$_ if (ref($widgets->{$_}) =~/photo/i)
				} sort keys %$widgets;
				@wIdent = map { &main::path_to_id($_)} @wIdent;
				@wIdent = map {"\$$_"} @wIdent;
				$f->BrowseEntry(-variable=>\$val{$k},-width=>14,-choices=>\@wIdent)->pack(@optPackRight);
			} elsif($pr->{$k} eq 'callback'){
				my @allSubs = ctkCallback::allCallbackNames;
				map {s/^(\w+)$/\\&$1/} @allSubs;
				$f->BrowseEntry(-textvariable=>\$val{$k},-width=>14,
						-choices=>\@allSubs
						)->pack(@optPackRight);
			} elsif($pr->{$k} eq 'variable'){
				my @aVars = sort (@ctkProject::user_auto_vars,@ctkProject::user_local_vars);
				my $wR = eval "\\\$val{$k}";
				$f->BrowseEntry(-variable=>$wR,-width=>14,-choices=>\@aVars)->pack(@optPackRight); ;
			} elsif($pr->{$k} eq 'widget'){
				my @wIdent = sort keys %ctkProject::descriptor;
				map {$_ = '$'.$_} @wIdent;
				$f->BrowseEntry(-variable=>\$val{$k},-width=>14,-choices=>\@wIdent)->pack(@optPackRight);
			} elsif($pr->{$k} eq 'justify') {
				$val{$k}='left' unless $val{$k};
				my $mnb = $f->Menubutton(-underline=>0,-relief=>'raised',-textvariable=>\$val{$k}, -direction =>'below')->pack(@optPackRight);
				my $mnu = $mnb->menu(qw/-tearoff 0/); $mnb->configure(-menu => $mnu);
				foreach my $r(qw/left center right/) {
					$mnu->command(-label=>$r,-image=>$pic->{"justify_$r"},-command=>sub{$val{$k}=$r;});
					}
			} elsif($pr->{$k} eq 'relief') {
				my $mnub = &main::optMenuWidget($f,$k,[qw/raised sunken flat ridge solid groove/],\$val{$k});
				$mnub->pack(@optPackRight);
			} elsif($pr->{$k} eq 'anchor') {
				$val{$k} = '' unless (exists $val{$k});
				&main::AnchorMenu($f,\$val{$k},'')->pack(@optPackRight);
			} elsif($pr->{$k} eq 'side') {
				$val{$k} = '' unless (exists $val{$k});
				&main::SideMenu($f,\$val{$k},'')->pack(@optPackRight);
			} elsif($pr->{$k} =~ /^menu\(/) {
				my $menu=$pr->{$k};
				my @w;
				$menu=~s/.*\(//;$menu=~s/\)//;
				@w = split('\|',$menu);
				if(scalar(@w) > 2) {
					$f->Optionmenu(-options=>[@w],-textvariable=>\$val{$k})->pack(@optPackRight);
				} else {
					my ($on,$off)=@w;
					$val{$k}=$on unless $val{$k};
					$f->Button(-textvariable=>\$val{$k},-relief=>'raised',-command=>sub{$val{$k}=($val{$k} eq $on)?$off:$on;})->pack(@optPackRight);
				}
			} elsif($pr->{$k} eq 'lpack') {
				$val{$k} =~ s/[\[\]']//g if (exists($val{$k}));
				(%lpack)=&main::split_opt($val{$k});
				$f->Optionmenu(-options=>[qw/n ne e se s sw w nw/],-textvariable=>\$lpack{'-anchor'})->pack(@optPackRight);
				$f->Optionmenu(-options=>[qw/left top right bottom/],-textvariable=>\$lpack{'-side'})->pack(@optPackRight);
			} else {
				$f->Entry(-textvariable=>\$val{$k})->pack(@optPackRight);
				## &std::ShowErrorDialog("Unexpected attribute type '$pr->{$k}' , discarded.");
			}
		}
	}

	my ($geom_type,$geom_opt,$n,$wn);
	my %g_val;
	my @brothers;
	# geometry part
	if ($d->geom) {
		my $db_rf=$db->LabFrame(-labelside=>'acrosstop',-label=>'Geometry manager')->pack(@frm_pack); # define right frame
		($geom_type,$geom_opt) = split('[)(]',$d->geom); # get type and options
		$geom_type =~ s/ //g;
		(%g_val)=&main::split_opt($geom_opt); # get geometry option values
		$n = $db_rf->NoteBook( -ipadx => 6, -ipady => 6 )->pack(qw/-expand yes -fill both -padx 5 -pady 5 -side top/);
		$wn = [];
		foreach  (@$geomMgr) {
			push @$wn,$n->add($_, -label => $_, -underline => 0);
		}
		my ($g_pack,$g_grid,$g_place,$g_form) = @$wn;

		# pack options:
		{
			&main::cnf_dlg_ballon($bl,$g_pack->Label(-text=>'-side',-justify=>'left')->grid(-row=>0,-column=>0,-sticky=>'w',-padx=>8),'-side');
			&main::SideMenu($g_pack,\$g_val{'-side'},$bl)->grid(-row=>0,-column=>1,-pady=>4);
		}
		{
			&main::cnf_dlg_ballon($bl,$g_pack->Label(-text=>'-anchor',-justify=>'left')->grid(-row=>1,-column=>0,-sticky=>'w',-padx=>8),'-anchor');
			&main::AnchorMenu($g_pack,\$g_val{'-anchor'},$bl)->grid(-row=>1,-column=>1,-pady=>4);
		}
		{
			&main::cnf_dlg_ballon($bl,$g_pack->Label(-text=>'-fill',-justify=>'left')->grid(-row=>2,-column=>0,-sticky=>'w',-padx=>8),'-fill');
			&main::FillMenu($g_pack,\$g_val{'-fill'},$bl)->grid(-row=>2,-column=>1,-pady=>4);
		}
		{
			&main::cnf_dlg_ballon($bl,$g_pack->Label(-text=>'-expand',-justify=>'left')->grid(-row=>3,-column=>0,-sticky=>'w',-padx=>8),'-expand');
			$g_val{'-expand'} = '0' unless exists $g_val{'-expand'};
			&main::cnf_dlg_ballon($bl,$g_pack->Button(-textvariable => \$g_val{'-expand'},-relief=>'raised', -command=>
								sub{$g_val{'-expand'}=1-$g_val{'-expand'}})->grid(-row=>3,-column=>1,-pady=>4),'-expand');

		}
		my $i=0;
		foreach my $k (qw/-ipadx -ipady -padx -pady/) {
			$i++;
			&main::cnf_dlg_ballon($bl,$g_pack->Label(-text=>$k,-justify=>'left')->grid(-row=>3+$i,-column=>0,-sticky=>'w',-padx=>8),$k);
			my $f=$g_pack->Frame()->grid(-row=>3+$i,-column=>1,-pady=>4);
			&main::cnf_dlg_ballon($bl,$f,$k);
			&ctkNumEntry::numEntry($f,-textvariable=>\$g_val{$k},-width=>4,-minvalue=>0)->pack(-side=>'right');
		}

		# geometry: grid
		{
			&main::cnf_dlg_ballon($bl,$g_grid->Label(-text=>'-sticky',-justify=>'left')->
					grid(-row=>0,-column=>0,-sticky=>'w',-padx=>8),'-sticky');
			my $f=$g_grid->Frame()->grid(-row=>0,-column=>1,-pady=>4);
			&main::cnf_dlg_ballon($bl,$f,'-sticky');
			my %st;
			foreach my $s (qw/n s e w/) {
				$st{$s}=grep(/$s/,$g_val{'-sticky'}) if exists $g_val{'-sticky'};
				$f->Checkbutton(-text=>$s,-variable=>\$st{$s},-command => sub{$g_val{'-sticky'}=~s/$s//g;$g_val{'-sticky'}.=$s if $st{$s}})->pack(-side=>'left');
				}
		}
		$i=1;
		foreach my $k (qw/-column -row -columnspan -rowspan -ipadx -ipady -padx -pady/) {
			&main::cnf_dlg_ballon($bl,$g_grid->Label(-text=>$k,-justify=>'left')->grid(-row=>$i,-column=>0,-sticky=>'w',-padx=>8),$k);
			my $f = $g_grid->Frame()->grid(-row=>$i,-column=>1,-pady=>4);
			&main::cnf_dlg_ballon($bl,$f,$k);
			&ctkNumEntry::numEntry($f,-textvariable=>\$g_val{$k},-width=>4,-minvalue=>($k=~/(-column|-row)$/)?0:1)->pack(-side=>'right');
			$i++;
		}

	  # geometry: place
		$i=0;
		foreach my $k (qw/-height -width -x -y /) {
			&main::cnf_dlg_ballon($bl,$g_place->Label(-text=>$k,-justify=>'left')->grid(-row=>$i,-column=>0,-sticky=>'w',-padx=>8),$k);
			my $f=$g_place->Frame()->grid(-row=>$i,-column=>1,-pady=>4);
			&main::cnf_dlg_ballon($bl,$f,$k);
			&ctkNumEntry::numEntry($f,-textvariable=>\$g_val{$k},-width=>4,-minvalue=>0)->pack(-side=>'right');
			$i++;
		}
		foreach my $k (qw/-relheight -relwidth -relx -rely/) {
			&main::cnf_dlg_ballon($bl,$g_place->Label(-text=>$k,-justify=>'left')->grid(-row=>$i,-column=>0,-sticky=>'w',-padx=>8),$k);
			my $f=$g_place->Frame()->grid(-row=>$i,-column=>1,-pady=>4);
			&main::cnf_dlg_ballon($bl,$f,$k);
			&ctkNumEntry::numEntry01($f,-textvariable=>\$g_val{$k},-width=>4,-minvalue=>0)->pack(-side=>'right');
			$i++;
		}
	  # geometry: form
		{
		$i=0;
		foreach my $k (qw/-top -left -right -bottom/) {
			&main::cnf_dlg_ballon($bl,$g_form->Label(-text=>$k,-justify=>'left')->grid(-row=>$i,-column=>0,-sticky=>'w',-padx=>8),$k);
			my $f=$g_form->Frame()->grid(-row=>$i,-column=>1,-pady=>4);
			&main::cnf_dlg_ballon($bl,$f,$k);
			$f->Entry(-textvariable=>\$g_val{$k})->grid(-row=>$i,-column=>1,-pady=>4);
			$i++;
		}
		foreach my $k (qw/-padtop -padleft -padright -padbottom/) {
			&main::cnf_dlg_ballon($bl,$g_form->Label(-text=>$k,-justify=>'left')->grid(-row=>$i,-column=>0,-sticky=>'w',-padx=>8),$k);
			my $f=$g_form->Frame()->grid(-row=>$i,-column=>1,-pady=>4);
			&main::cnf_dlg_ballon($bl,$f,$k);
			&ctkNumEntry::numEntry($f,-textvariable=>\$g_val{$k},-width=>4,-minvalue=>0)->grid(-row=>$i,-column=>1,-pady=>4);
			$i++;
		}
			&main::cnf_dlg_ballon($bl,$g_form->Label(-text=>'-fill',-justify=>'left')->grid(-row=>$i,-column=>0,-sticky=>'w',-padx=>8),'-fill');
			my $f=$g_form->Frame()->grid(-row=>$i,-column=>1,-pady=>4);
			my $mnb = &main::FillMenu($f,\$g_val{'-fill'},0);
			$mnb->grid(-row=>$i,-column=>1,-pady=>4);
		}
	$n->raise($geom_type);
	}
	# bind balloon message + help on click
	$bl->bind('<Enter>', sub{$bl->configure(-text=>'')});
	$bl->bind('<Leave>', sub{$bl->configure(-text=>'')});

	$db->resizable(0,0);
	&main::recolor_dialog($db);

my $errMsg;
my $reply;
	do {
		$errMsg = undef;
		$reply=$db->Show();
		if($reply eq 'Cancel') {
			return undef;
		} elsif ($reply eq 'Widget doc'){
			$help->tkpod($id,undef,$mw);
			$errMsg = '';
		} elsif ($reply eq 'Geometry doc'){
			if ($n) {
				my $id = $n->raised();
				$help->tkpod($id,undef,$mw);
			} else {}
			$errMsg = '';
		} else {
			if ($errMsg = &main::validateOptions($id,\%val)) {
				&std::ShowErrorDialog("$errMsg.\n\nPlease correct.",-buttons=>['Continue']);
			}
		}
	} until !defined($errMsg);

	if (keys %$pr) {
		$val{'-labelPack'} = "[-side=>'$lpack{'-side'}',-anchor=>'$lpack{'-anchor'}']"
		if %lpack;
	}
	my @wBrothers =();
	if ($d->geom) {
		$geom_type=$n->raised();
		# check for geometry conflicts here:
		# find all 'brothers' for current widget
		@wBrothers= &main::getBrotherToBeCheckedForGeom($id);
		@brothers = ();
		map {
			push @brothers,ctkProject->descriptor->{$_}->geom
		} @wBrothers;

		# if any of brothers does not match:
		# Ask user about conflict solution
		# 'Propagate' | 'Adopt' | 'Back' | 'Cancel'
		# go to start on 'Back'
		# return on 'Cancel'
		# otherwise - fix geometry respectively after 'undo_save'

		if (grep(!/^$geom_type/,@brothers)) {
			# we have conflict with one of the brothers
			my @w= ();
			map {
				push @w, $_ if (ctkProject->descriptor->{$_}->geom !~ /^$geom_type/);
			} @wBrothers;
			$reply = &main::askUserForGeom($id,$geom_type,join(',',@w));
			return undef if ($reply eq 'Cancel');
			goto re_enter if ($reply eq 'Back');
		}
	}

	&main::undo_save(); 	# save current state for undo

	if (keys %$pr) {
		foreach my $k ( keys %val) {
			if($k =~/^-(showvalue|tearoff|indicatoron|underline)$/){
				delete $val{$k} if ($val{$k} = ~/^\s*$/);
			} else {
				delete $val{$k} unless ($val{$k});
			}
			if($pr->{$k} eq 'callback') {
				&main::pushCallback($val{$k});
			}
		}
		## $d->opt(&main::buildWidgetOptions(\%val,$d->type));
		if(ctkProject->descriptor->{$id}->type =~ /^Scrolled/) {
				my ($w) = ctkProject->descriptor->{$id}->type =~ /^Scrolled(.+)/ ;
				$w = "'$w' , ". &main::buildWidgetOptionsOnEdit(\%val);
				$d->opt($w)
		} else {
				$d->opt(&main::buildWidgetOptionsOnEdit(\%val));
		}
	}

	if ($d->geom) {
		foreach my $k (keys %g_val) {
			if($k =~/^(-row|-column)$/) {
				delete $g_val{$k} if ($g_val{$k}=~/^\s*$/);
			} else {
				delete $g_val{$k} unless($g_val{$k});
			}
			delete $g_val{$k} unless grep($k eq $_,@{$w_geom{$geom_type}})
		}
		$geom_opt = join(', ',%g_val);
		$d->geom($geom_type."($geom_opt)");
		if ($reply eq 'Propagate') {
			main::Log("Propagating geom manager ".$d->geom. " to: $id");
			foreach (@wBrothers) {
				main::Log("$_");
				ctkProject->descriptor->{$_}->geom($d->geom)
			}
		}
		if ($reply eq 'Adopt') {
			main::Log("Adopting geom manager ".ctkProject->descriptor->{$wBrothers[0]}->geom . " to: " . &main::getSelected);
			$d->geom(ctkProject->descriptor->{$wBrothers[0]}->geom)
		}
	}
	&main::unhide(&main::path_to_id()) if (main::isHidden(&main::path_to_id()));
	&main::changes(1);
	return 1;
}

=head3 getBrotherToBeCheckedForGeom

=cut

sub getBrotherToBeCheckedForGeom {
	my $id = shift;
	my @rv;
	&main::trace("getBrotherToBeCheckedForGeom");
	if ( exists ctkProject->descriptor->{$id} ) {
		@rv= &main::tree_get_brothers($id);
		for (my $i = scalar(@rv)-1; $i >= 0; $i--) {
			splice @rv,$i,1 unless (&main::haveGeometry(ctkProject->descriptor->{$rv[$i]}->type));
			}
	} else {
		@rv =();
	}
	return wantarray ? @rv : \@rv;
}

=head3 Wrapper to the class ctkImages

imageFileSelect

=cut

sub imageFileSelect {
	return ctkImages->fileSelect(@_)
}
=head3 Wrappers to methods of the class ctkCallback

	extractMethods
	extractSubroutines
	pushCallback
	pushSubroutineName
	extractSubroutineName
	extractMethodName
	pushMethod

=cut

sub extractMethods {
	ctkCallback->extractMethods(@_);
}

sub extractSubroutines {
	ctkCallback->extractSubroutines(@_);
}

sub pushCallback {
	ctkCallback->pushCallback(@_);
}

sub pushSubroutineName {
	ctkCallback->pushSubroutineName(@_);
}

sub extractSubroutineName {
	return ctkCallback->extractSubroutineName(@_);
}

sub extractMethodName {
	return ctkCallback->extractMethodName(@_);
}


sub pushMethod {
	ctkCallback->pushMethod(@_);
}

=head2 Specialized Input dialogs

	Fillmenu
	SideMenu
	AnchorMenu

=cut

sub FillMenu {
	my ($where,$pvar,$balloon) =@_;
	&main::trace("FillMenu");
	my $mnb = $where->Menubutton(-direction=>'below');
	&main::cnf_dlg_ballon($balloon,$mnb,'-fill') if ($balloon);
	my $mnu = $mnb->menu(qw/-tearoff 0/);
	$mnb->configure(-menu => $mnu);
	foreach my $r('','x','y','both') {
		$mnu->command(-label=>$r,-image=>map_pic('fill',$r),-columnbreak=>($r eq 'x'),
					-command=>sub{$$pvar=$r;$mnb->configure(-image=>map_pic('fill',$r))});
	}
	if(defined $$pvar) {
		$mnb->configure(-image=>&map_pic('fill',$$pvar))
	} else {
		$mnb->configure(-image=>&map_pic('undef'))
	}
	return $mnb
}

sub SideMenu
{
	my ($where,$pvar,$balloon) = @_;
	&main::trace("SideMenu");
	my $mnb = $where->Menubutton(-direction=>'below',-cursor=>'left_ptr');
	&main::cnf_dlg_ballon($balloon,$mnb,'-side')
	 if $balloon;
	my $mnu = $mnb->menu(qw/-tearoff 0/); $mnb->configure(-menu => $mnu);
	foreach my $r ('','left','bottom','top','right')
	{
	  my $break=0;
	  $break=1 if $r =~ /left|top/;
	  $mnu->command(-label=>$r,
	                -image=>map_pic('side',$r),
	                -columnbreak=>$break,
	                -command=>sub{$$pvar=$r;$mnb->configure(-image=>map_pic('side',$r))});
	  $mnb->configure(-image=>&map_pic('side',$r)) if(defined $$pvar && $r eq $$pvar);
	  $mnb->configure(-image=>&map_pic('side','undef')) unless (defined $$pvar);
	}
	return $mnb;
	# end SideMenu
}

sub AnchorMenu
{
	my ($where,$pvar,$balloon)= @_ ;
	&main::trace("AnchorMenu");
	my $mnb = $where->Menubutton(-direction=>'below',-cursor=>'left_ptr');
	&main::cnf_dlg_ballon($balloon,$mnb,'-anchor') if $balloon;
	my $mnu = $mnb->menu(qw/-tearoff 0/); $mnb->configure(-menu => $mnu);
	foreach my $r('','nw','w','sw','n','center','s','ne','e','se')
	{
	  my $break=0;
	  $break=1 if $r =~ /^n/; # break before North pole ;-)
	  $mnu->command(-label=>$r,
					-image=>&map_pic('anchor',$r),
					-columnbreak=>$break,
					-command=>sub{$$pvar=$r;$mnb->configure(-image=>&map_pic('anchor',$r))});
	  $mnb->configure(-image=>&map_pic('anchor',$r)) if(defined $$pvar && $r eq $$pvar);
	  $mnb->configure(-image=>&map_pic('undef')) unless (defined $$pvar);
	}
	return $mnb;
}

=head2 Methods - Structure's handling

	cnf_dlg_ballon
	map_pic
	id_to_path
	parent_path
	path_to_id
	replace_id
	depthOfWidgetPath
	load_cnf_dlg_ballon
	tree_get_brothers
	tree_get_sons

=cut

sub path_to_id {
	return ctkProject->path_to_id(@_)
}

sub id_to_path {
	return ctkProject->id_to_path(@_);
}

sub depthOfWidgetPath {
	my $path = shift;
	$path = &main::getSelected unless (defined ($path));
	my $rv = my @w = split /\./ , $path;
	main::Log("depthOfWidgetPath rv = $rv");
	return ++$rv;
}

sub replace_id {
	my ($new_id,$path) = @_;
	my $rv;
	$path = &main::getSelected unless (defined($path));
	my $id = &main::path_to_id($path);
	$rv = $path;
	$rv =~s/$id$/$new_id/;
	return $rv
}

sub parent_path {
	my ($path) = @_;
	my $rv;
	$path = &main::getSelected unless (defined($path));
	my $id = &main::path_to_id($path);
	$rv = $path;
	$rv =~s/\.$id$//;
	return $rv
}

sub tree_get_sons {
	my $parent=shift;
	&main::trace("tree_get_sons  of parent = $parent");
	my @rv =();
	foreach my $widget (grep (/(^|\.)$parent\.[^\.]+$/,@ctkProject::tree)) {
		my $wid=$widget;
		$wid =~ s/.*\.//;
		push(@rv,$wid);
	}
	return wantarray ? @rv : \@rv ;
}

sub tree_get_brothers {
	my ($id) = @_ ;
	my @rv = ();
	&main::trace("tree_get_brothers   '$id'");
	my ($parent)=ctkProject->descriptor->{$id}->parent;
	@rv =  grep(!/^$id$/,&tree_get_sons($parent));
	return wantarray ? @rv : \@rv ;
}

sub cnf_dlg_ballon {
	my ($bln,$w,$key) = @_ ;
	&main::trace("cnf_dlg_ballon");
	return undef unless exists $cnf_dlg_ballon{$key};
	$w->bind("<Enter>",sub{
		my $widget = shift;
		my $key = $widget->cget(-text);
		$bln->configure(-text=>'', ,-background => '#F5F5F5') unless defined $key;
		$bln->configure(-text=>$cnf_dlg_ballon{$key}, ,-background => '#F5F5F5') if defined $key && exists $cnf_dlg_ballon{$key};
		});
	$w->bind("<Leave>",sub{
		$bln->configure(-text=>'',,-background => '#F5F5F5')
		});
	return 1
}

sub load_cnf_dlg_ballon {
	&main::trace("load_cnf_dlg_ballon");
	my $bf = ctkFile->new(fileName => "$myPath$FS$toolbarFolder${FS}balloon_cnf_dlg.txt");
	%cnf_dlg_ballon = ();
	return undef unless $bf->open("<");
	my $key='';
	my $line;
	while($line = $bf->get) {
		chomp ($line);
		next if ($line =~ /^\s*$/);
		next if ($line =~ /^\s*\#+/);
		if($line =~ /^\s*-/) {
			($key,$line) = ($line =~ /^\s*(-\S+)\s*=>\s*(\S.*)/);
		}
		next unless $key;
		if (exists $cnf_dlg_ballon{$key}) {
			$cnf_dlg_ballon{$key}.="\n$line";
		} else {
			$cnf_dlg_ballon{$key} = " $key => $line";
		}
	}
	$bf->close;
	return 1;
}

sub map_pic {
	my ($name,$x) = @_;
	&main::trace("map_pic",@_);
	$x = '_'.$x if ($x);
	my $p = $name;
	$p .= $x if ($x);
	return $pic->{'undef'} unless exists $pic->{$p};
	return $pic->{$p};
}

=head2 Methods - Undo/Redo

	redo
	undo
	undo_save

=cut

sub undo_save {
	my $rv = ctkUndoStack->undo_save(@_);
	ctkMenu->updateMenu() if ($rv);
	return $rv
}

sub redo {
	my $rv = ctkUndoStack->redo(@_);
	ctkMenu->updateMenu() if ($rv);
	return $rv
}

sub undo {
	my $rv = ctkUndoStack->undo(@_);
	ctkMenu->updateMenu() if ($rv);
	return $rv
}

=head2 Methods - View

	main_listBindings
	main_viewWidgetStructure

=cut

sub main_listBindings {
	&main::trace("main_listBindings");
	my $a = TkAnalysis->new(hwnd => $mw, debug => $debug);
	my $sw=&main::selectedWidget;
	$a->listBindings($mw,$sw);
}


sub main_viewWidgetStructure {
	&main::trace("main_viewWidgetStructure");
	my $sw=&main::selectedWidget;
	my $a = TkAnalysis->new(hwnd => $mw, debug => $debug);
	$a->showClassDiagram($mw,$sw);
}

=head2 Methods - Handling of generated code

	callback
	checkCallbackOption
	createDescriptor
	gen_my_variables
	gen_TkCode
	gen_WidgetCode

	quotate
	quotatX
	split_opt
	parseTargetCode
	view_code

=cut

sub view_code {
	&main::trace("view_code");
	return &std::viewCode($mw,$main::projectName);
}

sub gen_TkCode {
	&main::trace("gen_TkCode");
	my $now = localtime();
	my $code = ctkTargetCode->gen_TkCode();
	return wantarray ? @$code : $code;

}

sub getWidgetIdList {
	my $rv = ctkProject->getWidgetIdList(@_);
	return wantarray ? @$rv : $rv;
}

sub isRef2Widget {
	&main::trace("isRef2Widget");
	return ctkProject->isRef2Widget(@_);
}

=head3 gen_OrderCode

	See module ctkTargetCode.

=cut

sub gen_OrderCode {
	return ctkTargetCode->genOrderCode(@_);
}

=head3 gen_WidgetCode

	See module ctkTargetCode.

=cut

sub gen_WidgetCode {
	return ctkTargetCode->genWidgetCode(@_);
}

=head3 quotate

	See module ctkWidgetOption.

=cut

sub quotate {
	my $rv = ctkWidgetOption->quotate(@_);
	return $rv;
}

=head3 quotatX

	See module ctkParser.

=cut

sub quotatX {
	my $rv = ctkParser->quotatX(@_);
	return $rv;
}

=head3 string2Array

	See module ctkParser.

=cut

sub string2Array {
	my $rv = ctkWidgetOption->string2Array(@_);
	return wantarray ? @$rv : $rv
}

=head3 quotatY

	See module ctkParser.

=cut

sub quotatY {
	my $rv = ctkParser->quotatY(@_);
	return $rv
}

=head3 quotatZZ

	See module ctkParser.

=cut

sub quotatZZ {
	if (wantarray) {
		my @rv = ctkParser->quotatZZ(@_);
		return @rv;
	} else {
		my $rv = ctkParser->quotatZZ(@_);
		return $rv
	}
}

=head3 quotatZ

	See module ctkParser.

=cut

sub quotatZ {
	my $rv = ctkParser->quotatZ(@_);
	return $rv;
}

=head3 convertToList

	See module ctkParser.

=cut

sub convertToList {
	my $rv = ctkParser->convertToList(@_);
	return wantarray ? @$rv : $rv
}

=head3 parseTkCode

	See module ctkProject.

=cut

sub parseTkCode {
	my @rv = ctkProject->parseTkCode(@_);
	return wantarray ? @rv : \@rv;
}

sub normalize {
	my ($lines) = @_;
	&main::trace("normalize");
	die "obsolete code";
}

sub parseTargetCode  { # read external data structure to internal
	my ($lines,$where) = @_;
	my $rv;
	&main::trace("parseTargetCode");
	$where = 'push' unless (defined($where));
	$rv = ctkTargetCode->parseTargetCode($lines,$where);

	return $rv;
}

=head3 createDescriptor

	Return an instance of the class ctkDescriptor.

=cut

sub createDescriptor {
	my @argList = @_;
	my $rv;
	&main::trace("createDescriptor");
	map {
		s/\s+$// if (defined($_));
		s/^\s+// if (defined($_))
	}  @argList;
	my ($id,$parent,$type,$opt,$geom,$order) = @argList;
	$rv = ctkDescriptor->new('id' => $id , 'parent' => $parent , 'type' => $type , 'opt' => $opt , 'geom' => $geom , 'order' => $order);
	&main::trace($rv->dump);
	return $rv;
}

sub defaultGeometryOptions {
	my $type = shift;
	return (exists $w_attr->{$type}->{'defaultgeometryoptions'}) ?
					$w_attr->{$type}->{'defaultgeometryoptions'} : '';
}

sub defaultWidgetOptions {
	my ($type) = shift;
	return (exists $w_attr->{$type} && exists $w_attr->{$type}->{'defaultwidgetoptions'}) ?
						$w_attr->{$type}->{'defaultwidgetoptions'} : '';
}

sub defaultGeometryManager {
	my $type = shift;
	return undef unless(&main::haveGeometry($type));
	return (exists $w_attr->{$type}->{'defaultgeometrymanager'}) ?
						$w_attr->{$type}->{'defaultgeometrymanager'} : '';
}

=head3 preprocessOptions

	See module ctkParser.

=cut

sub preprocessOptions {
	my $opt = shift;
	return $opt unless ($opt);
##
##  eliminate positional option for scrolled widgets like scrolled('listbox', <options>)
##

	$opt =~ s/^\s*\'*[A-Za-z_][A-Za-z0-9_]*\'*\s*,//;
	return $opt
}

=head3 split_opt

	See module ctkWidgetOption.

=cut

sub split_opt {
	my @rv = ctkWidgetOption->split_opt(@_);
	return wantarray ? @rv : scalar(@rv);
}

=head3 callback

=cut

sub callback {
	ctkCallback->callback(@_);
}

=head3 checkCallbackOption

=cut

sub checkCallbackOption {
	return ctkCallback->checkCallbackOption(@_);
}

=head3 showTkVariables

=cut

sub showTkVariables {
	my $a= TkAnalysis->new(hwnd => $mw);
	my $db = $a->showTkVariables(-title => 'ctk - Tk variables');
	my $replay = $db->Show();
	$a->destroy();
	return 1
}
1;## make perl compiler happy ...
__END__
