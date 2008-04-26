=head1 ctkParser

	This package provides some (RDP) parser mainly to analyze
	options strings.

=head2 Data members

		None

=head2 Class data

		None.

=head2 Methods

	new
	destroy

	parseString
	parseWidgetOptions
	parseWidgetDefinition  (not yet implemented)


=head2 Programming notes

	All methods may also be used as class methods.

=head1 Methods

=cut

package ctkParser;

use strict;
use base (qw/ctkBase/);

use vars qw($VERSION);

$VERSION = 1.03;


sub new {
	my $class = shift;
	my $self = {};
	return bless $self, $class
}

sub destroy {
	my $self = shift;
	$self = {};
}


=head2 string2Array

=cut

sub string2Array {
	my $self = shift;
	my ($opt) = @_;
	my $rv = [];
	if ($opt =~/^\s*\[\s*([^]]*)\s*\]\s*$/) {
		my @wA = $self->split_opt($1);
		my $w = $self->quotatY(\@wA);
		$rv = eval "[$w]";
	} else {}

	return wantarray ? @$rv : $rv
}

=head2 quotatX

=cut

sub quotatX {
	my $self = shift;
	my ($opt,$type) = @_;
	my $rv ;
	my $opt_list ='';
	my $c;
	my $prefix = '';

	&main::trace("quotatX opt_list ",@$opt,"type = $type");

	die "Missing mandatory argument type" unless (defined($type));

	return '' unless (@$opt);

	my $class = shift @$opt if ($type =~ /^Scrolled/);

	$prefix = "'$class' , " if(defined($class));

	$opt_list = $self->quotatY($opt);

	unshift @$opt, $class if(defined($class));
	$rv = "$prefix$opt_list";
	&main::trace("rv='$rv'");
	return $rv;
}

=head2 quotatZZ

	Parse the given optlist :

		- quotate values
		- resolve list values
		- return list or string of options depending on context.

=cut

sub quotatZZ {					## U MO03801
	my $self = shift;
	my ($opt) = @_;
	my $rv ;
	my $opt_list ='';
	my $c;
	my $prefix;

	&main::trace("quotatZZ opt_list ",@$opt);

	return '' unless (@$opt);

	for (my $i = 0; $i < @$opt; $i++) {
		$c = $opt->[$i];
		if ($i % 2) {
			if ($c =~ /\^s*$/) {
				$opt_list .= "'' , ";
				push @$rv , '';
			} elsif ($c =~ /^\d+$/) {
				$opt_list .= "$c , ";
				push @$rv, $c;
			} elsif ($c =~ /^sub\s*\{/) {
				$opt_list .= "$c , ";
				push @$rv, $c;
			} elsif ($c =~ /^\s*\\*[\$\&]\w+/) {
				$opt_list .= "$c , ";
				push @$rv ,$c;
			} elsif ($c =~ /^\s*\[([^\]])*\]\s*$/)  {	## array def like labelPack => [...]
				$c = $1; $c =~s/\s*=>\s*/,/g;$c =~s/^\s+//;$c =~s/\s+$//;
				my @w = split /,/,$c;
				$c = $self->quotatZZ(\@w);
				$c = '['.$c.']';
				$opt_list .= "$c , ";
				push @$rv ,$c;
			} elsif ($c =~ /^\s*\'([^\']+)\'\s*$/)  {	## already quotated
				$opt_list .= "$c , ";
				push @$rv ,$c;
			} else {
				$opt_list .= "'$c' , ";
				push @$rv ,"'$c'";
			}
		} else {
			$opt_list .= "$c , ";
			push @$rv ,$c;
		}
	}
	$opt_list =~ s/,\s*$//;
	return (wantarray) ? @$rv : "$opt_list";
}

=head2 quotatZ

	Make the given  optlist operational in the clickTk run time environmnt.
	
		- parse the given optlist by means of main::quotatZZ
		- scan the received optlist:
			- resolve list of option :
				- replace <widget name> with $widgets->{<widget name>}
			- resolve scalar variables:
				- replace ref name with $widgets->{<ref name>} if
				  it exists.

=cut

sub quotatZ {
	my $self = shift;
	my ($opt,$widgets) = @_;
	my $rv ;
	my @wy = &main::quotatZZ($opt);
	map {
		my $w = $_;
		if ($w =~ /^\[/) {
				$w =~ s/[\[\]]//g;
				my @v = split /\s*,\s*/, $w ;
				map {
					if (/^\$/) {
						s/^\$//;
						$_ = "\$widgets->{$_}" if (exists $widgets->{$_})
					} ## else {}
				} @v;
				$_ = '['.join(',',@v).']'
		} else {
				if ($w =~/^\$/) {
					$w =~ s/^\$//;
					$_ = "\$widgets->{$w}" if (exists $widgets->{$w})
				} ## else {}
		}
	} @wy;				## replace variable's name with corresponding widget
	my $wx = join ',',@wy;
	$rv = eval "[ $wx ]";
	if ($@) {
		&main::log("main::quotatZ, syntax error on form options string",$wx,$@),
		$rv = undef
		}
	return $rv;
}

=head2 quotatY

	Parse the given optlist :

		- quotate values
		- resolve list values
		- return string of options .

=cut

sub quotatY {
	my $self = shift;
	my ($opt) = @_;
	my $rv ;
	my $opt_list ='';
	my $c;
	my $prefix;

	&main::trace("quotatY opt_list ",@$opt);

	return '' unless (@$opt);

	for (my $i = 0; $i < @$opt; $i++) {
		$c = $opt->[$i];
		if ($i % 2) {
			if ($c =~ /\^s*$/) {
				$opt_list .= "'' , "
			} elsif ($c =~ /^\d+$/) {
				$opt_list .= "$c , "
			} elsif ($c =~ /^sub\s*\{/) {
				$opt_list .= "$c , "
			} elsif ($c =~ /^\s*\\*[\$\&]\w+/) {
				$opt_list .= "$c , "
			} elsif ($c =~ /^\s*\\*[\@%]\w+/) {
				$opt_list .= "$c , "
			} elsif ($c =~ /^\s*\[([^\]]+)\]\s*$/)  {	## array def like labelPack => [...]
				$c = $1; $c =~s/\s*=>\s*/,/g;$c =~s/^\s+//;$c =~s/\s+$//;
				my @w = split /\s*,\s*/,$c;
				$c = $self->quotatY(\@w);
				$c = '['.$c.']';
				$opt_list .= "$c , "
			} elsif ($c =~ /^\s*\'([^\']+)\'\s*$/)  {	## already quotated
				$opt_list .= "$c , "
			} else {
				$opt_list .= "'$c' , "
			}
		} else {
			$opt_list .= "$c , "
		}
	}
	$opt_list =~ s/,\s*$//;
	$rv = "$opt_list";
	&main::trace("rv='$rv'");
	return $rv;
}


=head2 convertToList

	The given option's string is converted to an array, whereby all
	options values are quotate by means of a call to quotatY.

	Arguments
		string to be converted
		ref to array of error's messages
	Return

	The return value is , depending on the context, an array or
	a ref to array.

	TODO : recognize and recurse on options value lists, support qw/ list /


=cut

sub convertToList {
	my $self = shift;
	my ($s,$err) = @_;
	my $rv = [];

	$s =~s/\'//g; $s =~ s/^\s*\[//; $s =~ s/\s*\]\s*$//;$s =~s/=>/,/g;
	my @w = split /\s*,\s*/,$s;
	$s = &main::quotatY(\@w);
	$rv = eval "[$s]";
	push @$err, $@ if ($@);
	return wantarray ? @$rv : $rv
}


=head2 parseString

	Notation see 'parse Tk definition'

	string := substring [separator substring]
	separator := ',' | '=>' | '(' | ')' | '=' | '->'
	substring := nonquotedString | quotedString | list | quotedWords
	nonquotedString := [\S+]
	quotedString := quotedString1 | quotedString2
	quotedString1 := "'" [^\'] "'"
	quotedString2 := '"' [^\"] '"'
	list := '[' [^]]+ ']'
	quotedWords = qw '(' [^)]+ ')'		## not yet implemented

	Example :

	string = "-text => 'This is a substring!' -bg , #FFFFFF"
	string = "-fg , white , -command => ['main::doExit',$mw,$rc]"
	string = '-fg , white , -command => ["main::doExit",$mw,$rc]'
	string = '$w = $mw->Button(-command => ["main::doExit",$mw,$rc])->pack()'

=cut

sub parseString {
my $self = shift;
my $string = shift;
my @rv;
my $substring ;
my $READNEXT = 1;
my $QUOTEDSTRING1 = 2;
my $QUOTEDSTRING2 = 4;
my $LIST = 8;
my $NONQUOTEDSTRING = 16;

my $state = $READNEXT;
my $c;

	for (my $i = 0; $i < length ($string) ; $i++) {
		$c = substr($string,$i,1);
		if ($state == $READNEXT) {
			if ($c eq ' ') {
				next
			} elsif ($c eq "'") {
				$state = $QUOTEDSTRING2
			} elsif ($c eq '"') {
				$state = $QUOTEDSTRING1
			} elsif ($c eq "[") {
				$substring .= $c;
				$state = $LIST;
			} elsif ($c eq ",") {
				push @rv, $substring if defined($substring);
				undef $substring ;
			} elsif ($c eq "=" ) {
				push @rv, $substring if defined($substring);
				undef $substring;
				$i++ if (substr ($string,$i+1,1) eq '>');
			} elsif ($c eq "-" && substr ($string,$i+1,1) eq '>') {
				push @rv, $substring if defined($substring);
				undef $substring;
				$i++;
			} elsif ($c eq "(" ) {
				push @rv, $substring if defined($substring);
				undef $substring;
			} elsif ($c eq ")" ) {
				push @rv, $substring if defined($substring);
				undef $substring;
			} else {
				$substring = $c;
				$state = $NONQUOTEDSTRING
			}
		}elsif ($state == $QUOTEDSTRING1) {
			if ($c eq '"') {
				$state = $READNEXT
			} else { $substring .= $c }
		}elsif ($state == $QUOTEDSTRING2) {
			if ($c eq "'") {
				$state = $READNEXT
			} else { $substring .= $c }
		}elsif ($state == $LIST) {
			if ($c eq ']') {
				$substring .= $c;
				$state = $READNEXT
			} else { $substring .= $c }
		}elsif ($state == $NONQUOTEDSTRING) {
			if ($c =~ /[,()]/) {
				push @rv , $substring;
				undef $substring;
				$state = $READNEXT
			} elsif($c eq ' ' ) {
				push @rv , $substring;
				undef $substring;
				$state = $READNEXT
			} elsif($c eq '=' ) {
				push @rv , $substring;
				undef $substring;
				$i++ if (substr($string,$i+1,1) eq '>');
				$state = $READNEXT
			} elsif($c eq '-' && substr($string,$i+1,1) eq '>') {
				push @rv , $substring;
				undef $substring;
				$i++;
				$state = $READNEXT
			} else {
				$substring .= $c
			}
		} else {
			die "Unexpected state '$state',cannot proceed parseString"
		}
	}
	push @rv, $substring if defined($substring);
	return wantarray ? @rv : scalar(@rv);
}


=head2 Method parseWidgetOptions

	Method parseWidgetOptions converts a token list into
	an useable options list.

	In fact the method parseString do not recognize
	compound options like anonymous subroutines.

=over

=item Input

	Token list

=item Output

	Valid options list (array)

=item Precondition

	Method parseString successfully done (lexer)

=back

=cut

sub parseWidgetOptions {
	my $self = shift;
	my (@token) = @_;
	my @rv =();
	my $anon;

	my $state;
	my $ANON = 1;
	my $READNEXT = 0;
	## my $XXX ; ## add here other states

	for (my $i = 0, $state = $READNEXT; $i < @token; $i++) {
		my $c = $token[$i];
		if ($state == $READNEXT) {
			if ($c =~ /^\s*sub\s*$/) {
				$anon = $c;
				$state = $ANON
			} else {
				push @rv, $c
			}
		} elsif ($state == $ANON) {
			$anon .= $c;
			if ($c =~ /^\s*\}\s*$/) {
				push @rv,$anon;
				undef $anon;
				$state = $READNEXT
				} ## else
		## } elsif ($state == $XXX) { ## add here other productions
		} else {
			die "parseWidgetOptions: unknown state '$state'"
		}
	}
	return wantarray ? @rv : scalar(@rv);
}

=head2 Parse Tk widget definition

	Notation :

		{}			iteration of 0..1 items
		[]			iteration of 0..n items
		()			iteration of 1..n items
		|			selection (inclusive or)
		& or none	sequence (mandatory)
		.			concatenation (subsequence)
		word		non terminal token \w+
		'x'			ascii char (terminal token)
		"x"			ascii char (terminal token)
		"\'"		ascii char (terminal token)
		\w,\d,		perl regexp elements
		/regexp/

	Definition

		def := (widgetDef | variable)  {'->' geometryDef} ';'
		widgetDef :=  variable '=' variable '->' className {'(' {widgetOptions} ')'} ';'

		variable := '$'.\w+
		classname := \w+

		widgetOptions = [optionsName '=>' | ',' value]
		optionsname := '-' \w

		value := baseValue | variable | reference | array
		simpleValue := numeric | string
		numeric := \d+
		string := delimiter (chars) delimiter
		delimiter := ''' | '"'
		chars := \S | '\'chars
		reference := '\' variable | 'sub' '{' code '}' | '\'.entry
		code := '&'.entry {'(' list ')'}
		entry {{\w+]}.'::'}.\w+
		array :=  staticArray | dynamicArray
		staticArray := '(' list  ')'
		dynamicArray := '[' list ']'

		list := [value [',' value]]

		geometryDef := geometryManager {'(' geometryOptions ')'}
		geometryOptions := [optionsName '=>' | ',' baseValue]

=cut

sub parseWidgetDefinition {
	my ($line) = @_;
	my %rv =();
	## TODO: see parseWidgetOptions
	return %rv
}
BEGIN {1}
END{1}
1; ## make perl happy ...

