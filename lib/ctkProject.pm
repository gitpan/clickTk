#!/usr/lib/perl
##              -w -d:ptkdb

=pod

=head1 ctkProject

	Class ctkProject models a project file as used in the clickTk
	session.

=head2 Syntax

	my $prj = ctkProject->new();

	$prj->open ;

	$prj->save;

	$prj->close;

=head2 Programming notes

=over

=item Still under construction

=back

=head2 Maintenance

	Author:	marco
	date:	28.10.2006
	History
			28.10.2006 MO03101 mam First draft
			26.11.2007 version 1.02 refactoring
			14.12.2007 version 1.03 refactoring

=cut

package ctkProject;

use strict;

use ctkFile;
use base (qw/ctkBase ctkFile/);

use Time::localtime;

our $VERSION = 1.03;

our $debug = 0;

our $noname;

our $projectFolder;

our @tree = ($main::getMW);       # design tree list ('.' separated entry)

our %descriptor=();    # (id->descriptor)

our $objCount = 0;      # counter for unique object id

our $changes;          # Modifications flag

our @baseClass; 
our @libraries;
our @other_code;		## other code provided by programmer, do not manipulate it!
our @user_auto_vars;
our @user_gcode;
our @user_local_vars;
our @user_methods_code;
our @user_pod;
our @user_subroutines =("sub init { 1 }\n");

our $opt_modalDialogClassName ;	## name of the parent class of modal dialogs

my $FS = ctkFile->FS;


sub noname { return $noname }
sub descriptor { return \%descriptor }

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
	$self->init();
	return 1
}

sub init {
	my $self = shift;
	@baseClass =();
	@libraries = ();
	@other_code =();
	@user_auto_vars =();
	@user_gcode =();
	@user_local_vars =();
	@user_methods_code =();
	@user_pod =();
	@user_subroutines=("sub init { 1 }\n");
}

=head2 index_of

=cut


sub index_of {
	my $self = shift;
	my ($id) = @_;
	&main::trace("index_of");
	my $i=0;
	while ($tree[$i] !~ /(^|\.)$id$/) { $i++ };
	&main::trace("id '$id' returns i='$i'");
	return $i;
}

sub getType { 
	my $self= shift;
	my ($id) = @_;
	my $rv;
	if (defined($id)){
		&main::trace("getType ('$id')");
		$rv = $self->descriptor->{&main::path_to_id($id)}->type;
	} else {
		my $id = &main::getSelected();			## i MO03605
		if (defined $id) {						## i MO03605
			&main::trace('getType ('.'\''.$id.'\')');
			$rv= $self->descriptor->{&main::path_to_id($id)}->type;
		} else {
			&std::ShowErrorDialog("'getType' is missing valid args 'sel' and selected.\nProcess goes on with 'UNDEF', but data may be corrupted.");
		}
	}
	&main::trace("rv = '$rv'");
	return $rv
}

sub generate_unique_id {
	my $self = shift;
	my $type = shift;
	&main::trace("generate_unique_id type =$type");
	my $id;
	do {
		$objCount++;
		## $id = sprintf("%s%s%s%.3d",$identPrefix,$type,'_',$ctkProject::objCount);
		$id = sprintf("%s%.3d",$main::identPrefix,$objCount);
	} while(exists $self->descriptor->{$id});

	&main::trace("id='$id'");
	return $id;
}

=head2 empty_file_opt

=cut

sub empty_file_opt {
	my $self = shift;
	&main::trace("empty_file_opt");
	my (%fo) = ('description' => '',
				'title' => '',
				'code' => 0,
				'strict' => 0,
				'modal' => 0,
				'subroutineName' => $ctkTargetSub::subroutineName,
				'subroutineArgs' => $ctkTargetSub::opt_defaultSubroutineArgs,
				'subroutineArgsName' => $ctkTargetSub::subroutineArgsName,
				'modalDialogClassName' => $opt_modalDialogClassName,
				'autoExtractVariables' => 1,
				'autoExtract2Local' => 1,
				'baseClass' => '',
				'subWidgetList' => [],
				'onDeleteWindow' => 'sub{1}',
				'Toplevel' => '1'
				);
	return wantarray ? (%fo) : \%fo;
}

=head2 existsFolder

=cut

sub existsFolder {
	my $self = shift;
	my ($path) = @_;
	my $rv = (-d "$path$FS$projectFolder") ? 1:0;
	return $rv
}

=head2 name

=cut

sub name {
	my $self = shift;
	my ($file) = @_ ;
	my $rv;
	$file = $self->noname unless (defined($file));
	$file = "${main::applName}_00.pl" if ($file eq $self->noname && $main::applName);
	if ($file =~ /[\\\/]/) {
			$rv = &main::_name($file,$projectFolder);
	} else {
		$rv = $file
	}
	return $rv
}

=head2 fileName

=cut

sub fileName {
	my $self = shift;
	my ($file) = @_ ;
	&main::trace("fileName");
	$file = $self->noname unless(defined($file));
	return $file if ( $file =~ /^(\.[\\\/]){0,1}$projectFolder/);
	$file =~ s/\.pm$/.pl/;
	return ".$FS$projectFolder$FS$file";
}

=head2 getWidgetIdList

=cut

sub getWidgetIdList {
	my $self = shift;
	my @rv =();
	map {
		push @rv,&main::path_to_id($tree[$_]);
	} 1..$#tree;
	return wantarray ? @rv : \@rv;
}

=head2 isRef2Widget

=cut

sub isRef2Widget {
	my $self = shift;
	&main::trace("isRef2Widget");
	my $rv;
	my $list = $self->getWidgetIdList();
	unshift @$list,&main::path_to_id($tree[0]);
	map {
		my $id = $_;
		$id =~ s/^\$//;
		$rv ++ if grep( $id eq $_, @$list);
	} @_;
	&main::trace("rv = $rv");
	return $rv;
}

=head2 path_to_id

=cut

sub path_to_id {
	my $self = shift;
	my ($id) = @_;
	$id = &main::getSelected unless defined($id);
	&main::trace("path_to_id");
	return (split /\./,$id)[-1];
}

=head2 id_to_path

=cut

sub id_to_path {
	my $self = shift;
	my ($id) = @_;
	my @w;
	my $rv;
	unless($id) {
		&std::ShowErrorDialog("Missing expected widget ident,\ncannot determine parent widget.");
		return undef
	}
	@w = grep(/$id$/,@ctkProject::tree);
	if (@w > 1) {
		&std::ShowErrorDialog("Widget tree is damaged.\nMore than one widget id '$id' found.");
	} elsif (@w == 1) {
		$rv = $w[0]
	} else {
		$rv = undef
	}
	return $rv;
}

=head2 saveDataToFile

=cut

sub saveDataToFile {
	my $self = shift;
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

=head2 conflicts

	Scan the widgets definitions for existing conflicts

		conflict 1 	remove option -label from Frame with sub-widgets using grid 
					(endless loop in Perl)

			for each frame widget
			get all children id's
			get those geometry
			remove -label if at least one match 'grid'

	Arguments
		None

	Return
		array of conflicts description or
		number of conflicts

=cut

sub conflicts {
		my $self = shift;
		my @rv;

	foreach my $elm (@tree[1..scalar(@tree)-1]) {
		my $id = &main::path_to_id($elm);
		next unless ($self->descriptor->{$id}->type eq 'Frame');
		my (@children)=grep(/\.$id\.([^\.]+)$/,@tree);
		next unless @children;
		map {s/.*\.//} @children;
		map {$_ = $self->descriptor->{$_}->geom} @children;
		if ( grep (/grid/,@children) ) {
			my (%opt)=&main::split_opt($self->descriptor->{$id}->opt);
			if ($opt{'-label'}) {
				delete $opt{'-label'};
				push @rv,"Option -label of widget '$id' has been suppressed,\n because it is not compatible with geometry mgr 'grid' \nused by widget's children.";
				$self->descriptor->{$id}->opt(&main::buildWidgetOptions(\%opt,$self->descriptor->{$id}->type));
			}
		}
	}
	return wantarray ? @rv : scalar(@rv);
}

=head2 parseTkCode

	For each widget description line:

		1. get Id, Parent, Type, parameters, geometry
		2. check for Parent existence
		3. add line to tree descriptor
		4. add element to widget descriptor
		5. collect variables and callbacks
		6. add item to widget tree

	Arguments

		- widget constructor code (string)
		- line number within input batch (int)
		- assigned order (string)
		- nonvisual flag
		- 

	Return

		array of exceptions

	Global structures 

		%ctkProject::descriptor (id->descriptor)	
		@ctkProject::tree
		@ctkProject::user_auto_vars - user-defined variables to be pre-declared automatically
		use vars qw/$x/;

	Global widgets used:

		$tf - preview tree


=cut

sub parseTkCode {
	my $self = shift;
	my ($line,$count,$order,$nonvisual,$where) = @_;
	my @rv =();
	my $MW = &main::getMW();
	my $parser = ctkParser->new();

	&main::trace("parseTkCode '$line'");
	&main::trace("count '$count'") if (defined($count));
	&main::trace("nonvisual '$nonvisual'") if (defined($nonvisual));
	&main::trace("where '$where'") if (defined($where));

	$nonvisual = 0 unless defined $nonvisual;
	$where = 'push' unless (defined($where));
	
	my $pic = &main::get_picW;
	my $picN;

	$line =~ s/'(\w+)'/$1/g; # ignore self-generated quotes
	$line =~ s/'([\w\.\\\/]+)'/$1/g; # ignore self-generated quotes (file names)
	$line =~ s/'(#[\da-fA-F]+)'/$1/g; # ignore self-generated quotes

	my @token = $parser->parseWidgetOptions($parser->parseString($line));

	&main::trace("line = '$line'");

	for (my $i = 0; $i < @token; $i++) {
		&main::trace("$i,$token[$i]")
	}

	# 1. get Id, Parent, Type, parameters, geometry

	my ($id,$parent,$type,$opt,$geom,$menuConfig);


	$id     = shift @token; $id =~ s/^\$//;
	$parent = shift @token; $parent =~ s/^\$//;
	$type   = shift @token;

	unless ($nonvisual) {
		($id,$parent,$type,$opt,$geom) =
		$line =~ /^\s*\$(\S+)\s*=\s*\$(\S+)\s*->\s*([^(]+)\(([^)]+)\)\s*->\s*([^;]+);/;
		unless($id) {
			my $virtual_parent;
			($id,$virtual_parent,$type,$opt,$parent,$menuConfig) =
			$line =~ /^\s*\$([a-zA-Z_0-9]+)\s*=\s*\$([a-zA-Z_0-9]+)\s*->\s*([a-zA-Z_0-9]+)\s*\(([^)]*)\)\s*;\s*\$([a-zA-Z_0-9]+)->configure\(-menu=>\$([a-zA-Z_0-9]+)\s*\)/;
		}
		unless($id) {
			($id,$parent,$type,$opt) =
			$line =~ /^\s*\$(\S+)\s*=\s*\$(\S+)\s*->\s*([^(]+)\(([^)]+)\);\s*$/;
		}
		unless ($id) {
			my $w = "line ${count}: Could not parse code '$line', code discarded";
			main::Log($w);
			push @rv, $w;
			return wantarray ? @rv : \@rv
		}

	} else {
		unless (&main::nonVisual($type)) {
			my $w = "line ${count}: class <$type> for widget <$id> isn't a non-visual class.";
			main::Log($w);
			push @rv, $w;
			return wantarray ? @rv : \@rv
		}
	}

	# 2. check widget existence

	# 2.1 Parent exists ?

	if($parent ne $MW && ! defined $self->descriptor->{$parent}) {
		# error - report in Tk style:
		push @rv, "line ${count}: Wrong parent id <$parent> for widget <$id>";
		return wantarray ? @rv : \@rv	}

	# 2.2 ident exists ?
	if (exists $self->descriptor->{$id}) {
		push @rv, "line ${count}: Duplicated widget <$id> definition\n";
		return wantarray ? @rv : \@rv	}

	$objCount++;

	# 3. add line to tree descriptor

	my $parent_path = main::id_to_path($parent);
	$parent_path=$MW unless $parent_path;
	my $insert_path;
	my $new_path;

	if ($where eq 'push') {
		($insert_path)=(grep(/$parent\.[^.]+$/,@tree))[-1];
		$new_path = "$parent_path.$id";
		push(@tree,$new_path);
		main::trace('widget tree after push',@tree);
	} elsif ($where eq 'splice') {
		($insert_path)=(grep(/$parent\.[^.]+$/,@tree))[-1];
		$new_path = "$parent_path.$id";
		push(@tree,$new_path);
		main::trace('widget tree after splice',@tree);
	} else {
		push @rv,"unexpected where argument value '$where', operation discarded";
		return (wantarray) ? @rv : \@rv
	}

	$type =~ s/\s//g;

	# 4. add element to widget descriptor

	if ($type eq 'add'){
		$type = 'NoteBookFrame';
		$opt =~ s/^\s*\S+\s*,\s*//;
	}

	if ($nonvisual) {
			$self->descriptor->{$id}=&main::createDescriptor($id,$parent,$type,'','',$order);
	} else {

		if ($type =~ /^Scrolled/) {
			my ($w) = $opt =~ /^\s*([a-zA-Z][a-zA-Z0-9_]*)\s*\,/;
			if (defined($w)) {
				$self->descriptor->{$id}=&main::createDescriptor($id,$parent,"Scrolled$w",$opt,$geom,$order);
			} else {
				my $e = "Missing class name in options '$opt' for scrolled widget '$id'";
				&main::trace($e);
				push @rv, "line $count : $e\n";
				return wantarray ? @rv : \@rv
			}
		} elsif ($type =~ /^Menu$/) {
			$self->descriptor->{$id}=&main::createDescriptor($id,$parent,$type,$opt,$geom,$order);
		} else {
			$self->descriptor->{$id}=&main::createDescriptor($id,$parent,$type,$opt,$geom,$order);
		}

		# 5. collect variables and callbacks

		if($opt=~/variable/){
			# store user-defined variable in array
			my ($user_var)=($opt=~/\\\$(\w+)/);
			&main::trace("Variable '$user_var' detected parsing '$opt'");
			$self->assignVariables("\$$user_var") if ($user_var) ;
		}
		if ($opt=~/(-command|-\w*cmd)\s*=>\s*([^\-^\)]+)/) {
			my $w = $2;
			$w =~ s/^\s+//;
			$w =~ s/\s+$//;
			$w =~ s/[,\)]$//;
			&main::pushCallback($w);
		} else {
		}
	}

	## 6. add item to widget tree (obsolete bacause of next message main::changes(1), which forces repaint the tree)

	#$picN = &main::getWidgetIconName ($id);
	#main::trace("parent '$parent' add('$new_path' -text '$id' -after '$insert_path' -image $picN)");
	#if($insert_path) {
	#	$tf->add("$new_path",-text=>$id,-after => $insert_path ,-data=> "$new_path",-image => $picW->{$picN}); 
	#} else {
	#	$tf->add("$new_path",-text=>$id,-data=> "$new_path",-image => $picW->{$picN}); 
	#}

	return wantarray ? @rv : \@rv;
}

=head2 _extractVariables

=cut

sub _extractVariables {
	my $self = shift;
	&main::trace("extractVariables");

	my @rv =();
	my $parser = ctkParser->new();
	foreach my $element (@ctkProject::tree[1..$#tree]) {
		my $d = $self->descriptor->{&main::path_to_id($element)};
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

=head2 extractVariables

=cut

sub extractVariables {
	my $self = shift;
	my @rv =();
	&main::trace("extractVariables");
	return wantarray ? @rv : \@rv  unless($main::file_opt{'autoExtractVariables'});
	@rv = $self->_extractVariables();
	foreach (@user_local_vars, @user_auto_vars) { ## eliminate vars which are already explicitly declared
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

=head2 refreshVariables

=cut

sub refreshVariables {
	my $self = shift;
	my (@w) = @_;
	&main::trace("refreshVariables");
	my $rv;
	return undef unless (@w);

	map {
		my $id = $_;
		foreach (0..$#user_local_vars) {
			if ($id eq $user_local_vars[$_]) {
				splice @user_local_vars,$_,1;
				last
				}
		}
		foreach (0..$#user_auto_vars) {
			if ($id eq $user_auto_vars[$_]) {
				splice @user_auto_vars,$_,1;
				last
				}
		}
	} @w;
	$rv = $self->assignVariables(@w);
	return $rv
}

=head2 assignVariables

=cut

sub assignVariables {
	my $self = shift;
	my (@w) = @_;
	&main::trace("assignVariables");
	my $rv = 0;
	return $rv unless (@w);
	if ($main::file_opt{'autoExtract2Local'}) {
		map {
			my $var = $_;
			push @user_local_vars, $var
				unless(grep ($_ eq $var,@user_local_vars) || $self->isRef2Widget($var))
		} @w;
		$rv = scalar(@user_local_vars);
	} else {
		map {
			my $var = $_;
			push @user_auto_vars, $var
				unless(grep ($_ eq $var,@user_auto_vars) || $self->isRef2Widget($var))
		} @w;
		$rv = scalar(@user_auto_vars)
	}
	return $rv ;
}

## sub import {}

BEGIN { 1 }
END {1 }

1; ## -----------------------------------
