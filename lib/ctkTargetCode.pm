=pod

=head1 ctkTargetCode

	Class targetCode models the basic functionality to generate
	the various targets.
	Thus it is the parent class of all implemented targetCode.

	the main functions are

		generate	generate the target
		parse		parse existing target
		load		load the target definition (template)

=head2 Syntax

	The main usage of this class is to work as base class.

		use ctkTargetCode;
		use base (qw/ctkTargetCode/);

=head2 Programming notes

=over

=item Methods

	new
	destroy
	_init
	generate
	parse
	load
	genVariablesGlobal
	genAllVariablesGlobal
	genVariablesLocal
	genGlobalVariablesClassVariables
	existsTestCode
	genCalls2Test
	genOnDeleteWindow
	genGcode
	gen_TkCode
	gen_my_variables
	genCallbacks
	genOptions
	genPod
	genUselibStrictAndUseStatements
	genUseStatements
	genMainWindow
	genOtherCode
	genUselib
	genOrderCode
	genWidgetCode
	generateTarget
	gen_OrderCode
	normalize
	parseTargetCode		read external data structure to internal


=back

=head2 Maintenance

	Author:	Marco
	date:	28.10.2006
	History
			28.10.2006 MO03101 mam First draft
			28.11.2007 MO03501 mam refactoring
			13.12.2007 version 1.02
			13.03.2008 version 1.03

=cut

package ctkTargetCode;

use strict;

use ctkFile;
use base (qw/ctkBase ctkFile/);

use Time::localtime;

our $VERSION = 1.02;

our $debug = 0;

my $ctkC ;

sub new {
	my $class = shift;
	my (%args) = @_;
	$class = ref($class) || $class ;
	my $self = $class->SUPER::new(%args);
	bless  $self, $class;
	$self->_init(%args);

	return $self
}

sub destroy {
	my $self = shift;
	$self->SUPER::destroy(@_);
}

sub _init {
	my $self = shift;
	my (%args) = @_;
	## $self->SUPER::_init(%args);

	return 1
}

sub generate {
	my $self = shift;
	my (%args) = @_;
	my $rv;
	return $rv
}

sub parse {
	my $self = shift;
	my (%args) = @_;
	my $rv;
	return $rv
}

sub load {
	my $self = shift;
	my (%args) = @_;
	my $rv;
	return $rv
}

=head3 genVariablesGlobal

=cut

sub genVariablesGlobal {
	my $self = shift;
	my ($code, $mw) = @_;
	&main::trace("genVariablesGlobal");
	$ctkC = $main::ctkC unless defined($ctkC);
	my @w = sort @ctkProject::user_auto_vars;
	push @$code , "$ctkC Globalvars";
	push @$code , "\nuse vars qw/".join(' ',@w)."/;\n" if (@w);
	push @$code , "$ctkC Globalvars end";
	return $code
}


=head3 genAllVariablesGlobal

=cut

sub genAllVariablesGlobal {
	my $self = shift;
	my ($code, $mw) = @_;
	&main::trace("genAllVariablesGlobal");
	$ctkC = $main::ctkC unless defined($ctkC);
	my @w = @ctkProject::user_auto_vars;
	map {my $v = $_; push @w, $v unless(grep($v eq $_,@w))} @ctkProject::user_local_vars;
	@w = sort @w;
	push @$code , "$ctkC Globalvars";
	push @$code , "\nuse vars qw/ ".join(' ',@w)."/;\n" if (@w);
	push @$code , "$ctkC Globalvars end";
	return $code
}

sub genVariablesLocal {
	my $self = shift;
	my ($code, $mw) = @_;
	&main::trace("genVariablesLocal");
	$ctkC = $main::ctkC unless defined($ctkC);
	my @w = sort @ctkProject::user_local_vars;
	push @$code , "$ctkC Localvars";
	push @$code , "\nmy (".join(',',@w).");\n" if (@w);
	push @$code , "$ctkC Localvars end";
	return $code
}

sub genGlobalVariablesClassVariables {
	my $self = shift;
	my ($code, $mw) = @_;
	$ctkC = $main::ctkC unless defined($ctkC);
	&main::trace("genGlobalVariablesClassVariables");
	my @w = sort @ctkProject::user_auto_vars;
	push @$code , "$ctkC Globalvars";
	push @$code , "\nmy (".join(',',@w).");\n" if (@w);
	push @$code , "$ctkC Globalvars end";
	return $code
}

=head3 existsTestCode

	Return the number of test-subrotines.

=cut

sub existsTestCode {
	my $self = shift;
	my ($code,$now,$mw) = @_;
	&main::trace("existsTestCode");
	my @aNames = ctkCallback->subroutineNames;
	my $rv = grep(/^test\w*/, @aNames);
	return $rv
}

=head3 genCalls2Test

=cut

sub genCalls2Test {
	my $self = shift;
	my ($code,$now,$mw) = @_;
	&main::trace("genCalls2Test");
	my @aNames = ctkCallback->subroutineNames;
	my @sub = grep(/^test\w*/, @aNames);
	$mw =~ s/^\$//;
	map {
			push @$code ,"\&main::$_(\$$mw);"
	} sort @sub;
	return $code
}

=head3 genOnDeleteWindow

=cut

sub genOnDeleteWindow {
	my $self = shift;
	my ($code,$now,$mw) = @_;
	my $file_opt = &main::getFile_opt();
	if (exists $file_opt->{'onDeleteWindow'}) {
		$file_opt->{'onDeleteWindow'} = 'sub{1}' unless($file_opt->{'onDeleteWindow'});
		push @$code,"\$$mw".'->protocol(\'WM_DELETE_WINDOW\','.$file_opt->{'onDeleteWindow'}.');' unless $file_opt->{'onDeleteWindow'} =~ /^\s*none\s*$/i;
	} else {
		push @$code,"\$$mw".'->protocol(\'WM_DELETE_WINDOW\',sub {1});'
	}
	return $code
}

=head3 genGcode

=cut

sub genGcode {
	my $self = shift;
	my ($code, $now) = @_;
	&main::trace("genGcode");
	$ctkC = $main::ctkC unless defined($ctkC);
	if(@ctkProject::user_gcode) {
			push @$code, "$ctkC gcode";
			map {
				push @$code , "$_";
			} @ctkProject::user_gcode;
			push @$code, "$ctkC gcode";
	} else {}
	return $code;
}

sub gen_TkCode {
	my $self = shift;
	&main::trace("gen_TkCode");
	my $now = localtime();
	my $code=[];
	my $file_opt = &main::getFile_opt();
	$ctkC = $main::ctkC unless defined($ctkC);

	push @$code,"$ctkC code generated by ctk_w version '$main::version' ";
	if($file_opt->{'strict'}){
		push @$code,"$ctkC lexically scoped variables for widgets \n";
		push @$code,$self->gen_my_variables() ;
	} ## else {}
	push @$code,"$ctkC instantiate and display widgets \n";
	my $wTree = [];
	my $i = -1;
	foreach  my $item (@ctkProject::tree) {
		my $n = my @n = split(/\./, $item);
		$i++;
		next unless ($n);
		$n--;
		$wTree->[$n] =[] unless (defined $wTree->[$n]);
		push @{$wTree->[$n]}, $i;
	}
	while (@$wTree) {
		my $items = shift @$wTree;
		foreach my $i(@$items) {
			my $codeLine=&main::gen_WidgetCode($ctkProject::tree[$i]);
			push (@$code,$codeLine) if $codeLine;
		}
	}
	push @$code,"$ctkC end of gened Tk-code\n";
	return $code;
}

sub gen_my_variables {
	my $self = shift;
	&main::trace("gen_my_variables");
	my @rv = ();
	map {
		my $v = '$'.$_;
		push @rv,$v unless grep ($v eq $_ , @ctkProject::user_auto_vars);
	} sort ctkProject->getWidgetIdList;
	if (@rv > 1) {
		map {$rv[$_] .= ','} 0 .. $#rv - 1;
		unshift @rv ,'my (';
		push @rv,');';
		&main::trace('rv=',@rv);
	} elsif (@rv == 1) {
		$rv[0] = "my $rv[0] ;"
	} else {
		$rv[0] = "## no 'my' widget list"
	}
	return wantarray ? @rv : join ('',@rv);
}

sub genCallbacks {
	my $self = shift;
	my ($code,$now) = @_;
	&main::trace("genCallbacks");
	$ctkC = $main::ctkC unless defined($ctkC);

	if ($main::opt_TestCode) {
		if(@ctkProject::user_subroutines){
			unless (grep /^\s*sub\s+init\s+/,@ctkProject::user_subroutines) {
				unshift @ctkProject::user_subroutines ,"sub init { 1 }\n"
			}
		} else {
			@ctkProject::user_subroutines = ("sub init { 1 }\n");
		}
	} ## else {} # intentionally left empty

	push @$code , "$ctkC callbacks";

my $gen = 1;
	map {
		if (/^\s*sub\s+test\w+\s+/) {
			$gen = $main::opt_TestCode;
		} elsif (/^\s*sub\s+[\w_]+\s+/) {
			$gen = 1;
		} else {
			##
		}
		push @$code , $_  if($gen);
	} @ctkProject::user_subroutines;
	return $code;
}

sub genOptions {
	my $self = shift;
	my ($code,$now) = @_;
	&main::trace("genOptions");
	my $file_opt = &main::getFile_opt();
	$ctkC = $main::ctkC unless defined($ctkC);

	push @$code , "#!$main::perlInterp" if ($file_opt->{'code'} == 1) ; ## shebang
	push @$code , "$ctkC description $file_opt->{'description'}";
	push @$code , "$ctkC title $file_opt->{'title'}";
	push @$code , "$ctkC application '$ctkApplication::applName' '$ctkApplication::applFolder'";
	push @$code , "$ctkC strict  $file_opt->{'strict'}";
	push @$code , "$ctkC code  $file_opt->{'code'}";
	push @$code , "$ctkC testCode  $main::opt_TestCode";
	push @$code , "$ctkC subroutineName $file_opt->{'subroutineName'}";
	push @$code , "$ctkC autoExtractVariables  $file_opt->{'autoExtractVariables'}";
	push @$code , "$ctkC autoExtract2Local  $file_opt->{'autoExtract2Local'}";
	push @$code , "$ctkC modalDialogClassName $file_opt->{'modalDialogClassName'}" if ($file_opt->{modal} && $file_opt->{'modalDialogClassName'});
	push @$code , "$ctkC modal $file_opt->{modal}";
	push @$code , "$ctkC baseClass  $file_opt->{'baseClass'}" if ($file_opt->{'baseClass'});
	push @$code , "$ctkC isolGeom $main::opt_isolate_geom";
	push @$code , "$ctkC version $main::version";
	push @$code , "$ctkC onDeleteWindow  $file_opt->{'onDeleteWindow'}";
	push @$code , "$ctkC Toplevel  $file_opt->{'Toplevel'}";
	push @$code , "$ctkC argList $file_opt->{'subroutineArgs'} ";
	push @$code , "$ctkC $now";
	push @$code , '';

	return $code;
}

sub genPod {
	my $self = shift;
	my ($code,$now) = @_;
	&main::trace("genPod");
	my $file_opt = &main::getFile_opt();
	$ctkC = $main::ctkC unless defined($ctkC);

	return $code unless (@ctkProject::user_pod);

	push @$code,"\n";
	map {
		push @$code , $_;
	} @ctkProject::user_pod;
	push @$code,"\n";
	return $code
}

sub genUselibStrictAndUseStatements {
	my $self = shift;
	my ($code,$now) = @_;
	&main::trace("genUselibStrictAndUseStatements");
	my $file_opt = &main::getFile_opt();
	$ctkC = $main::ctkC unless defined($ctkC);

	my @useStmts = $self->genUseStatements();

	map {
		push @$code, "$_\n"
	} $self->genUselib;

	push @$code,"use strict;" if ($file_opt->{'strict'});

	push @$code,'use Tk;';
	map {
			push @$code , "use $_;";
	} sort @useStmts;

	return $code
}

sub genUseStatements {
	my $self =shift;
	&main::trace("genUseStatements");
	my @rv =();
	my $file_opt = &main::getFile_opt();
	my $t;
	my $w_attr = &main::getW_attr;
	$ctkC = $main::ctkC unless defined($ctkC);
	foreach my $k (keys %$ctkProject::descriptor) {
			next if($k =~/^\s*$/ || $k =~/^mw$/);		## temp 24.07.2005
			if (exists $w_attr->{ctkProject->descriptor->{$k}->type}->{'use'}) {
				if ($w_attr->{ctkProject->descriptor->{$k}->type}->{'use'} =~/\S+/) {
					$t = $w_attr->{ctkProject->descriptor->{$k}->type}->{'use'}
				} else {
					undef $t
				}
			} else {
					$t = 'Tk::'.ctkProject->descriptor->{$k}->type
			}
			push @rv, $t unless (!defined($t) || $t =~ /^\s*$/ || grep /^$t$/ ,@rv);
	}
	return wantarray ? @rv : \@rv;
}

sub genMainWindow {
	my $self =shift;
	my ($code,$now) = @_;
	&main::trace("genMainWindow");
	my $file_opt = &main::getFile_opt();
	$ctkC = $main::ctkC unless defined($ctkC);
	my $mw = &main::getMW;
	my $my = ($file_opt->{'strict'}) ? 'my ' :'';
	return $code unless($main::opt_TestCode);
	push @$code , "$my \$$mw=MainWindow->new(-title=>'$file_opt->{title}');";
	return wantarray ? @$code : $code
}

sub genOtherCode {
	my $self =shift;
	my ($code,$now) = @_;
	&main::trace("genOtherCode");
	my $file_opt = &main::getFile_opt();

	$ctkC = $main::ctkC unless defined($ctkC);
	push @$code , "$ctkC other code";
	if(@ctkProject::other_code){
		map{push @$code , $_ } @ctkProject::other_code;
	} ## else {}
	return $code
}

sub genUselib {
	my $self = shift;
	&main::trace("genUselib");
	my @rv =();
	my $file_opt = &main::getFile_opt();

	$ctkC = $main::ctkC unless defined($ctkC);
	if ($main::opt_TestCode) {
		@rv = ("$ctkC uselib start");
		unshift @ctkProject::libraries ,$ctkApplication::applFolder unless ( !$ctkApplication::applFolder || grep $ctkApplication::applFolder eq $_ , @ctkProject::libraries);
		map {
			s/[\\\/]/\//g;		## must be unix like
			push @rv, "use lib '$_';";
		} @ctkProject::libraries ;
		push @rv, "$ctkC uselib end";
	} else {}
	return wantarray ? @rv : \@rv
}

sub genOrderCode {
	my $self = shift;
	my ($type,$id,$order) = @_;
	my $rv = '';
	my $file_opt = &main::getFile_opt();

	$ctkC = $main::ctkC unless defined($ctkC);
	return $rv unless $order;
	$rv = $ctkC.' nonvisual start '.$type.' '.$id."\n".$order."\n$ctkC".' nonvisual end';
	return $rv;
}

sub genWidgetCode {
	my $self = shift;
	my ($element) = @_;
	my ($code, $codeWidget, $codeGeom,$order);
	my $file_opt = &main::getFile_opt();

	$ctkC = $main::ctkC unless defined($ctkC);
	&main::trace("gen_WidgetCode   element = '$element'");
	my $id=&main::path_to_id($element);

	return '' unless (exists ctkProject->descriptor->{$id});
	return '' if($id eq &main::getMW);

	my ($d,$my,$geom,$postconfig,$parent, $type,@opt,$opt);

	my $parser = ctkParser->new();

	$d = ctkProject->descriptor->{$id};
	if (&main::nonVisual(&main::getType($id))) {
		$type = &main::getType($id);
		$order =  ($d->order) ? $self->genOrderCode($type,$id,$d->order)  : '';
	} else {
		$my = ($file_opt->{'strict'}) ? 'my ' :'';
		$postconfig='';
		$postconfig=' $'.$d->parent."->configure(-menu=>\$$id);" if $d->type eq 'Menu';
		$geom = ' -> '.&main::quotate($d->geom);
		$geom='' unless &main::haveGeometry($d->type);
		$parent=$d->parent;
		if (defined(ctkProject->descriptor->{$parent})) {
			$parent = ctkProject->descriptor->{$d->parent}->parent if ctkProject->descriptor->{$parent}->type eq 'cascade';
		} else {
		}
		$type=$d->type;
		@opt = $parser->parseWidgetOptions($parser->parseString($d->opt));
		$opt=&main::quotatX(\@opt,$type);

		if (defined(ctkProject->descriptor->{$parent})) {
			if(ctkProject->descriptor->{$parent}->type eq 'NoteBook') {
				$type='add';
				$opt="'$id', $opt";
			}
		}
		&main::trace("type='$type', id='$d->{id}'");
		if ($type =~ /^Scrolled/) {
			##	$type =~ /^Scrolled(\S+)/;
			$type = 'Scrolled';
			#	$opt = "'$1',$opt" if ($1);
		}
		$order = ($d->order) ? $d->order : '';
		if ($main::opt_isolate_geom) {
			$codeWidget = '$'.$d->id.' = $'.$parent.' -> '.$type.' ( '.$opt.' )'.";\n";
			$codeWidget .= &main::gen_OrderCode($type,$id,$order);
			$codeGeom = '';
			$codeGeom = '$'.$d->id.$geom .';' if ($geom);
			$code = $codeWidget . $codeGeom . "\n"  ;
			$code .= "$postconfig ;\n" if($postconfig);
		} else {
			$code = '$'.$d->id.' = $'.$parent.' -> '.
					$type.' ( '.$opt.' )'.$geom . ";";
			$code .= ($postconfig) ? "$postconfig\n" : "\n";
		}
	}

	$code .= "$order\n";

	&main::trace("code='$code'");
	return $code;
}

sub generateTarget {
	my $self = shift;
	my $file_opt = &main::getFile_opt();
	my $now = &main::getDateAndTime();

	my $mw = &main::getMW();
	my $code =[];

	$ctkC = $main::ctkC unless defined($ctkC);

	$code = ctkTargetCode->genOptions($code,$now);
	$code = ctkTargetCode->genPod($code,$now);
	$code = ctkTargetCode->genUselibStrictAndUseStatements($code,$now);
	$code = ctkTargetCode->genMainWindow($code,$now);

	if($file_opt->{'code'} == 3) {
		$code = &main::genComposite($code,$now);	##  emit here code for composite
	} elsif($file_opt->{'code'} == 2) {
		$code = &main::genPackage($code,$now);	##  emit here code for package
	} elsif($file_opt->{'code'} == 1) {
		$code = &main::genScript($code,$now,$mw);	## emit code for script
	} elsif($file_opt->{'code'} == 0) {
		$code = &main::genSubroutine($code,$now,$mw); ## emit code for subroutine
	} else {
		&std::ShowErrorDialog("Unexpected value of code}='$file_opt->{code}'.\nThis is a program failure,\n pls save work and terminate.");
	}

	$code = ctkTargetCode->genOtherCode($code,$now);

	push @$code , "$ctkC eof $now";
	push @$code , "1;\t## make perl compiler happy...\n";

	return wantarray ? @$code : $code;
}

sub gen_OrderCode {
	my $self = shift;
	my ($type,$id,$order) = @_;
	my $rv = '';
	return $rv unless $order;
	$ctkC = $main::ctkC unless defined($ctkC);
	$rv = $ctkC.' nonvisual start '.$type.' '.$id."\n".$order."\n$ctkC".' nonvisual end';
	return $rv;
}

=head2 normalize

=cut

sub normalize {
	my $self = shift;
	my ($lines) = @_;
	&main::trace("normalize");
	foreach my $line (@$lines) {
		## TODO reduce multi-line Tk-statements to one-line statements
		## (to be applied at import time!)
	}
	return 1
}

=head2 parseTargetCode

	This method does the followin tasks

	- parse the given target,
	- save tokens into project data members and file_opt structure,
	- display errors on the standard message dialog box.

	It accepts two arguments
		- target code (ref to array)
		- arg where for method parseTkCode
	It returns true if no error was found, 0 otherwise.

=cut

sub parseTargetCode  { # read external data structure to internal
	my $self = shift;
	my ($lines,$where) = @_;
	my $rv;
	&main::trace("parseTargetCode");

	$where = 'push' unless (defined($where));

	my @errors;
	my $count = 0; # just for diagnostics - input line number
	my $user_subroutines = 1;
	my $pod = 2;		## 1 line is inside pod, stack into description ; 0 line is outside pod
	my $gcode = 4;
	my $otherCode = 8;
	my $testCode = 16;
	my $eof_Tkcode = 32;
	my $user_methods = 64;
	my $public = 128;
	my $globalVars = 256;
	my $localVars = 512;
	my $uselib = 1024;
	my $nonvisual = 2048;
	my $CONFIGSPEC = 4096;
	my $DELEGATES = 8192;

	my $nonvisualClass = '';
	my $nonvisualId = '';

	my $status = 0;

	my @wX;			## stack of lines indices belonging to the same widget definition's statement
	my $wCount;		## line no of first line of a widget def.
	my @wY;			## stack of lines indices belonging to the same widget geometry call
	my $wyCount;	## line no of first line of a widget geometry call.
	my @wO;			## stack of lines indices belonging to the order of widget on @wX
	my $woCount;	## line no of first line of a widget geometry call.
	my @nvO;		## stack of lines indices belonging to the order of nonvisual class

	my $wConfigSpec = '';
	my $wDelegates = '';

	my $file_opt = &main::getFile_opt();
	my $w_attr = &main::getW_attr();

	chomp @$lines;

	@ctkProject::other_code = ();
	@ctkProject::user_gcode = ();
	@ctkProject::user_pod   = ();
	@ctkProject::user_subroutines = ();
	@ctkProject::user_methods_code = ();
	@ctkProject::libraries = ();

	$self->normalize($lines);

	foreach my $line (@$lines) {
		$count++;
		## check state first!!!
		last if($line =~ /^## ctk: eof/);
		if ($status & $otherCode) {
			push @ctkProject::other_code, $line;
			my $n = &main::extractMethodName($line);
			&main::pushMethod($n) if ($n);
			next;
		}
		if ($status & $gcode) {
			if($line =~ /^## ctk: gcode/) {
				$status = 0;
			} else {
				push @ctkProject::user_gcode,$line;
			}
			next
		} elsif ($status & $user_methods) {
			next if($line=~ /^\s*$/);
			if($line =~ /^## ctk: callbacks/) {
				$status = 0; $status |= $user_subroutines;
				next;
			}  elsif($line =~ /^## ctk: methods/) {
				$status = 0;
				next;
			} else {}
			push(@ctkProject::user_methods_code,$line);
			my $n = &main::extractMethodName($line);
			&main::pushMethod($n) if ($n);
			next
		} elsif ($status & $user_subroutines) {
			next if($line=~ /^\s*$/);
			if($line =~ /^## ctk: callbacks/) {
				$status = 0;
			} elsif($line =~ /^## ctk: other code/) {
				$status = 0; $status |= $otherCode;
				next;
			} else {
			}
			push(@ctkProject::user_subroutines,$line);
			my $n = &main::extractSubroutineName($line) if($line =~ /^\s*sub\s+/);
			&main::pushSubroutineName($n) if ($n);
			next
		} elsif ($status & $pod) {
			push @ctkProject::user_pod, $line;
			if ($line =~ /^=cut/) {
				$status = 0;
			}
			next
		} elsif ($status & $public) {
			if ($line =~ /^## ctk: public/) {
				$status = 0;
			} else {
				if ($line =~ /Advertise\s*\(\s*'*(\w+)'*\s*=>\s*\$(\w+)/) {
					push @{$file_opt->{'subWidgetList'}}, {name => $1, ident => $2, public => '1'};
				} else {
				}
			}
			next
		} elsif ($status & $globalVars) {
			if ($line =~ /^## ctk: Globalvars/) {
				$status = 0;
			} else {
				if ($line =~ /Advertise\s*\(\s*(\w+)\s*=>\s*\$(\w+)/) {
					push @{$file_opt->{'subWidgetList'}}, {name => $1, ident => $2, public => '1'};
				} else {
					while ($line =~ /([\$\@\%]\w+)/g) {
						push @ctkProject::user_auto_vars, $1;
					}
				}
			}
			next
		} elsif ($status & $localVars) {
			if ($line =~ /^## ctk: Localvars/) {
				$status = 0;
			} else {
				if ($line =~ /Advertise\s*\(\s*(\w+)\s*=>\s*\$(\w+)/) {
					push @{$file_opt->{'subWidgetList'}}, {name => $1, ident => $2, public => '1'};
				} else {
					while ($line =~ /([\$\@\%]\w+)/g) {
						push @ctkProject::user_local_vars, $1;
					}
				}
			}
			next
		} elsif ($status & $uselib) {
			if ($line =~ /^## ctk: uselib/) {
				$status = 0;
			} else {
				if ($line =~ /^\s*use\s+lib\s*\'([^\']+)\'/) {
					push @ctkProject::libraries, $1;
				} else {}
			}
			next
		} elsif ($status & $nonvisual) {
			if ($line =~/## ctk: nonvisual end/) {
				my $wOrder ='';
				map {$wOrder .= $lines->[$_]."\n"} @nvO;
				my $wLine = "\$$nonvisualId = \$mw->${nonvisualClass}();";
				my @err = &main::parseTkCode($wLine,$wCount,$wOrder,1,$where);
				map {push @errors,$_ } @err if (@err);
				undef $wCount;
				$status = 0;
				$nonvisualClass = '';
				$nonvisualId = '';
			} else {
				push @nvO , $count - 1;
			}
			next
		} elsif($status & $testCode) {
			if ($line =~ /^## ctk: testCode/) {
					$status = 0
			}
			next;
		}elsif ($status & $CONFIGSPEC) {
			if ($line =~ /^## ctk: configSpec/) {
				$status = 0;
				next;
			} ## else {}
			$wConfigSpec .= $line
		} elsif ($status == $DELEGATES) {
			if ($line =~ /^## ctk: Delegates/) {
				$status = 0;
				next;
			} ## else {}

			$wDelegates .= $line
		} else {}

		if($line =~ /^\s*$/) {
			next
		} elsif($line =~ /^=/ ) {
			push @ctkProject::user_pod,$line;
			$status = 0; $status |= $pod;
			next
		} elsif($line =~ /^## ctk: public/) {
			$status = 0; $status |= $public;
			next
		} elsif($line =~ /^## ctk: methods/) {
			$status = 0; $status |= $user_methods;
			next
		} elsif($line =~ /^## ctk: Globalvars/) {
			$status = 0; $status |= $globalVars;
			next
		} elsif($line =~ /^## ctk: Localvars/) {
			$status = 0; $status |= $localVars;
			next
		} elsif($line =~ /^## ctk: callbacks/) {
			$status = 0; $status |= $user_subroutines;
			next
		} elsif($line =~ /^## ctk: description\s+(.+)/) {
			$file_opt->{'description'} = "$1";
			next
		} elsif($line =~ /^## ctk: title\s+(.+)/) {
			$file_opt->{'title'} = "$1";
			next
		} elsif($line =~ /^## ctk: application\s+(.+)/) {
			($ctkApplication::applName,$ctkApplication::applFolder) = $1 =~ /\'([^\']*)\'\s+\'([^\']*)\'/;
			next
		} elsif($line =~ /^## ctk: strict\s+(\d+)/) {
			$file_opt->{'strict'}= $1;
			next
		} elsif($line =~ /^## ctk: modal\s+(\d+)/) {
			$file_opt->{'modal'}= $1;
			next
		} elsif($line =~ /^## ctk: autoExtract2Local\s+(\d+)/) {
			$file_opt->{'autoExtract2Local'} = $1;
			next
		} elsif($line =~ /^## ctk: autoExtractVariables\s+(\d+)/) {
			$file_opt->{'autoExtractVariables'} = $1;
			next
		} elsif($line =~ /^## ctk: fullcode\s+(\d+)/) {
			$file_opt->{'code'} = $1;
			next
		} elsif($line =~ /^## ctk: code\s+(\d+)/) {
			$file_opt->{'code'}= $1;
			next
		} elsif($line =~ /^## ctk: testCode\s+(\d+)/) {
			$main::opt_TestCode = $1;
			next
		} elsif($line =~ /^## ctk: subroutineName\s+([\w_]+)/) {
			$file_opt->{'subroutineName'}= $1;
			next
		} elsif($line =~ /^## ctk: modalDialogClassName\s+([\w_]+)/) {
			$file_opt->{'modalDialogClassName'}= $1;
			next
		} elsif($line =~ /^## ctk: baseClass\s+([\w:]+)([\w\s:]+)/) {
			$file_opt->{'baseClass'}= "$1$2";
			next
		} elsif($line =~ /^## ctk: isolGeom\s+(\d+)/) {
			$main::opt_isolate_geom = $1;
			next
		} elsif($line =~ /^## ctk: onDeleteWindow\s+(.+)/) {
			$file_opt->{'onDeleteWindow'}= "$1";
			next
		} elsif($line =~ /^## ctk: Toplevel\s+(.+)/) {
			$file_opt->{'Toplevel'}= "$1";
			next
		} elsif($line =~ /^## ctk: gcode/) {
			$status = 0; $status |= $gcode;
			next
		} elsif($line =~ /^## ctk: other code/) {
			$status = 0; $status |= $otherCode;
			next;
		} elsif($line =~ /^## ctk: test code/) {
			$status = 0; $status |= $testCode;
			next;
		} elsif($line =~ /^## ctk: uselib/) {
			$status = 0; $status |= $uselib;
			next;
		} elsif($line =~ /^## ctk: argList\s+(.*)/) {
			$file_opt->{'subroutineArgs'} = "$1";
			next;
		} elsif ($line =~ /^## ctk: ConfigSpec/) {
			$status = 0; $status |= $CONFIGSPEC;
			next
		} elsif ($line =~ /^## ctk: Delegates/) {
			$status = 0; $status |= $DELEGATES;
			next
		} elsif ($line =~ /^## ctk: nonvisual start (.+)/) {
			my $w = $1;
			if ($w =~ /^\s*([_\w]+)\s+([_\w]+)\s*/) {
				if (&main::nonVisual($1)) {
					$nonvisualClass = $1;
					$nonvisualId = $2
				} else {
					$nonvisualClass = $1;
					$nonvisualId = $2;
					if (exists $w_attr->{$nonvisualClass}) {
						push @errors,"line $count : Class name '$nonvisualClass' is not of type nonVisual, pls check.";
						&main::Log("Class name '$nonvisualClass' is not nonVisual, pls check.");
					} else {
						my $workWidget = ctkWidgetLib->new('widgets' => $w_attr,widgetlib => $main::widgetFolder);
						$w_attr->{$nonvisualClass} = $workWidget->createNonVisualClass($nonvisualClass);
						$w_attr->{$nonvisualClass}->{'file'} = "${nonvisualClass}_temp";
						$workWidget->save($nonvisualClass);
						$workWidget->destroy;
						push @errors,"line $count : new temporary non-visual class '$nonvisualClass' created for '$nonvisualId'.";
						&main::Log("Created temporary non-visual type '$nonvisualClass' for '$nonvisualId'.");
					}
				}
			} else {
				&main::Log("Missing or invalid non visual class name '$1'  $2");
				$nonvisualClass = 'unknownNonvisualWidgetClass';
				$nonvisualId = '';
			}
			@nvO = ();
			$status = 0; $status |= $nonvisual;
			$wCount = $count;
			next;
		} elsif($line =~ /^## ctk: end/) {
			$status = 0; $status |= $eof_Tkcode;
			if (@wX) {
				my $wLine = $lines->[$wX[0]];
				foreach (1..$#wX) {$wLine .= ' '.$lines->[$wX[$_]] }
				my $wOrder = $lines->[$wO[0]] if (@wO);
				foreach (1..$#wO) {$wOrder .= "\n".$lines->[$wO[$_]] }
				my @err = &main::parseTkCode($wLine,$wCount,$wOrder,0,$where);
				map {push @errors,$_ } @err if (@err);
				@wX = ();
				undef $wCount;
				@wO = ();
			} ## else {}
			if (@wY) {
				my $wLine = $lines->[$wY[0]];
				foreach (1..$#wX) {$wLine .= ' '.$lines->[$wY[$_]] }
				if ($wLine =~ /^\s*\$(\w+)\s*\-\>\s*(pack|grid|place)\s*\(([^)]*)\)/) {
					my $id = $1 ;
					my $geom = $2;
					my $geomOpt = $3;
					if (exists ctkProject->descriptor->{$id}) {
							$geomOpt =~ s/\'//g;
							ctkProject->descriptor->{$id}->geom("$geom($geomOpt)");	## save into ctkProject->descriptor->{$id}
					}  else {
						push @errors, "line $wyCount, unknown widget ident '$id', line discarded ";
					}
				} else {
					push @errors, "line $wyCount, could not parse '$wLine', line discarded ";
				}
				@wY = ();
				undef $wyCount;
			} ## else {}
			next
		} elsif ($status & $eof_Tkcode) {
			next;
		} elsif ($line =~ /^\s*\$mw\s*=/) {
			next ;
		} elsif($line =~ /^\s*[^\$]/) {
			push @wX, ($count-1) if(@wX) ; ## continuation line
			next;
			push @wY, ($count-1) if(@wY) ; ## continuation line
			next;
		} elsif($line =~ /^\s*\$\w+\s*=\s*\$\w+\s*\-\>\s*\w+\s*\(/) {			##  must be a Tk command fro widget def
			if (@wY) {
				my $wLine = $lines->[$wY[0]];
				foreach (1..$#wX) {$wLine .= ' '.$lines->[$wY[$_]] }
				if ($wLine =~ /^\s*\$(\w+)\s*\-\>\s*(pack|grid|place)\s*\(([^)]*)\)/) {
					my $id = $1 ;
					my $geom = $2;
					my $geomOpt = $3;
					if (exists ctkProject->descriptor->{$id}) {
							$geomOpt =~ s/\'//g;
							ctkProject->descriptor->{$id}->geom("$geom($geomOpt)");	## save into ctkProject->descriptor->{$id}
					}  else {
						push @errors, "line $wyCount, unknown widget ident '$id', line discarded ";
					}
				} else {
					push @errors, "line $wyCount, could not parse '$wLine', line discarded ";
				}
				@wY = ();
				undef $wyCount;
			} ## else {}
			if (@wX) {
				my $wLine = $lines->[$wX[0]];
				foreach (1..$#wX) {$wLine .= ' '.$lines->[$wX[$_]] }
				my $wOrder = $lines->[$wO[0]] if (@wO);
				foreach (1..$#wO) {$wOrder .= "\n".$lines->[$wO[$_]] }
				my @err = &main::parseTkCode($wLine,$wCount,$wOrder,0,$where);
				map {push @errors,$_ } @err if (@err);
				@wX = ();
				undef $wCount;
				@wO = ();
			} ## else {}
			$wX[0] = $count-1;
			$wCount = $count-1;
		} elsif($line =~ /^\s*\$(\w+)\s*\-\>\s*(pack|grid|place)\s*\(([^)]*)\)/) {			##  must be a Tk command for geometry
			if (@wX) {
				my $wLine = $lines->[$wX[0]];
				foreach (1..$#wX) {$wLine .= ' '.$lines->[$wX[$_]] }
				my $wOrder = $lines->[$wO[0]] if (@wO);
				foreach (1..$#wO) {$wOrder .= "\n".$lines->[$wO[$_]] }
				my @err = &main::parseTkCode($wLine,$wCount,$wOrder,0,$where);
				map {push @errors,$_ } @err if (@err);
				@wX = ();
				undef $wCount;
				@wO = ();
			} ## else {}
			if (@wY) {
				my $wLine = $lines->[$wY[0]];
				foreach (1..$#wX) {$wLine .= ' '.$lines->[$wY[$_]] }
				if ($wLine =~ /^\s*\$(\w+)\s*\-\>\s*(pack|grid|place)\s*\(([^)]*)\)/) {
					my $id = $1 ;
					my $geom = $2;
					my $geomOpt = $3;
					if (exists ctkProject->descriptor->{$id}) {
							$geomOpt =~ s/\'//g;
							ctkProject->descriptor->{$id}->geom("$geom($geomOpt)")	## save into ctkProject->descriptor->{$id});
					}  else {
						push @errors, "line wyCount, unknown widget ident '$id', line discarded ";
					}
				} else {
					push @errors, "line $wyCount, could not parse '$wLine', line discarded ";
				}
				@wY = ();
				undef $wyCount;
			} else {
				$wY[0] = $count-1;
				$wyCount = $count-1;
			}
		} else {
			push @wO, ($count-1) if(@wX) ; ## order
			## skip other perl statements
		}
	}

	if (@wX) {
		my $wLine = $lines->[$wX[0]];
		foreach (1..$#wX) {$wLine .= ' '.$lines->[$wX[$_]] }
		my $wOrder = $lines->[$wO[0]] if (@wO);
		foreach (1..$#wO) {$wOrder .= "\n".$lines->[$wO[$_]] }
		my @err = &main::parseTkCode($wLine,$wCount,$wOrder,0,$where);
		map {push @errors,$_ } @err if (@err);
		@wX = ();
		undef $wCount;
		@wO = ();
	} ## else {}

	if (@wY) {
		my $wLine = $lines->[$wY[0]];
		foreach (1..$#wX) {$wLine .= ' '.$lines->[$wY[$_]] }
		if ($wLine =~ /^\s*\$(\w+)\s*\-\>\s*(pack|grid|place)\s*\(([^)]*)\)/) {
			my $id = $1 ;
			my $geom = $2;
			my $geomOpt = $3;
			if (exists ctkProject->descriptor->{$id}) {
							$geomOpt =~ s/\'//g;
							ctkProject->descriptor->{$id}->geom("$geom($geomOpt)")	## save into ctkProject->descriptor->{$id});
			}  else {
						push @errors, "line wyCount, unknown widget ident '$id', line discarded ";
			}
				@wY = ();
				undef $wyCount;
		} else {
			push @errors, "line $wyCount, could not parse '$wLine', line discarded ";
		}
	} else {
		$wY[0] = $count-1;
		$wyCount = $count-1;
	}

	ctkTargetComposite->parseAndSaveDelegates($wDelegates) if ($wDelegates);
	ctkTargetComposite->parseAndSaveConfigSpec($wConfigSpec) if ($wConfigSpec);

	if(@errors) {
		&main::trace(@errors);
		if(@errors > 10){
			splice(@errors,10);
			push @errors, "Too many errors - skipped\n";
		}
		&std::ShowErrorDialog(join("\n",@errors));
		$rv = 0
	} else {
		$rv = 1
	}
	return $rv
}

## sub import {}

BEGIN { 1 }
END {1 }

1; ## -----------------------------------
