#!/usr/lib/perl
##              -w -d:ptkdb

=pod

=head1 ctkWidgetOption

	This class models the options of a widget.

=head2 Programming notes

=over

=item None.

=back

=head2 Maintenance

	Author:	MARCO
	Date:	01.01.2007
	History
			05.12.2007 refactoring

=cut

package ctkWidgetOption;

use base (qw/ctkParser/);

our $VERSION = 1.01;

our $debug = 0;

sub new {
	my $class = shift;
	my (%args) = @_;
	$class = ref($class) || $class ;
	## my $self = $class->SUPER::new(%args);
	my $self = {};
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

=head2 preprocessOptions

	Eliminate positional option for scrolled widgets 
	like scrolled('listbox', <options>)

=cut

sub preprocessOptions {
	my $self = shift;
	my ($opt) = @_;
	return $opt unless ($opt);

	$opt =~ s/^\s*\'*[A-Za-z_][A-Za-z0-9_]*\'*\s*,//;
	return $opt
}

=head2 split_opt

	input: options string
	output: array of pairs (-param=>value,-param2=>value2,...)

	input  := (option)
	option := name ',' | '=>' value
	name   := \w+
	value  := [\w\s]+

	output := (name,option)

=cut

sub split_opt {
	my $self = shift;
	my $opt=shift ;
	my @rv;
	if ($opt) { 		## must return empty array if no options are passed to
		&main::trace("split_opt  opt = '$opt'");
		$opt = $self->preprocessOptions($opt);

		@rv = $self->parseString($opt);
		@rv = $self->parseWidgetOptions(@rv);

		&main::trace('split_opt rv = '.join ' ',@rv);
	} else {
		@rv = ();
	}
	return wantarray ? @rv : scalar(@rv);
}

=head2 quotate

	

=cut

sub quotate {
	my $self = shift;
	my $opt_list = shift;
	my $rv ;
	&main::trace("quotate  opt_list = '$opt_list'");

	my ($prefix,$suffix) = $opt_list =~ /^\s*([^\(]*\().*(\)[^\)]*)/;
	$prefix = "'Text'," if($opt_list =~ /^\s*.*Text.\s*,/);
	$prefix = "'Listbox'," if($opt_list =~ /^\s*.Listbox.\s*,/);
	&main::trace("prefix = '$prefix'") if(defined($prefix));
	$opt_list =~ s/^\s*([^\(]*\()//;
	$opt_list =~ s/(\)[^\)]*)//;

	if($opt_list !~ /^\s*$/) {
		my (%opt)=$self->split_opt($opt_list);
		foreach my $k(keys %opt) {
			$opt{$k} = "'$opt{$k}'" unless ($opt{$k} =~ /^\'[^\']*\'$/ ||
						$opt{$k} =~ /^\d+$/ ||
						$opt{$k} =~ /^\[[^\]]+\]$/ ||
						$k =~ /(image|variable|command|cmd|choices)$/);
		}
		$rv =  $prefix. join(', ',map{"$_=>$opt{$_}"} keys %opt) . $suffix;
	} else {$rv = "$prefix$suffix"}
	&main::trace("rv='$rv'");
	return $rv;
}

sub Trace { shift->trace(@_);}
sub trace {
	shift->log(@_) if ($debug);
}

sub Log { shift->log(@_)}
sub log {
	my $self = shift;
	map {print "\n\t".$self->getDateAndTime()." $_"} @_;
}

sub getDateAndTime {
	my $self = shift;
	my $now = shift;
	$now = localtime unless(defined($now));

	my $rv = sprintf('%04d %02d %02d - %02d:%02d:%02d',
				  $now->year+1900, $now->mon+1,$now->mday,
				  $now->hour, $now->min, $now->sec) ;
	return $rv;
}

## sub import {}

BEGIN { 1 }
END {1 }

1; ## -----------------------------------
