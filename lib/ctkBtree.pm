#!/usr/lib/perl
##              -w -d:ptkdb

=pod    ctkBtree

=head1 ctkBtree - Btree

	ctkBtree implements a b-tree with hashes of hashes.

=head2 Syntax

	my $bt = ctkBtree->new().
	my $stack = $bt->getStack()

	$bt->traverse_DF_in(callback);
	$bt->traverse_DF_pre(callback);
	$bt->traverse_DF_post(callback);
	$bt->traverse_BF(callback);

	$bt->traverse_DF2_pre(hash1,hash2,callback_1, callback_2, callback);

	where callback may be

			callback := refToSub | arglist

				refToSub := 'sub{' code '}' | \&subroutineName

					code := any perl code

				arglist := refToSub (args)

					args := any valid perl argument list 

=head2 Programming notes

=over 

=item Callbacks and events of traverse_DF2_pre

	Method traverse_DF2_pre invokes the following callbacks on corresponding events

	- onExist1  passed node ident exists only in hash1

	- onExist2  passed node ident exists only in hash2

	- onExist   passed node ident exists on both hash1 and hash2

=item Restrictions

	- node ident must be scalar (strings)
	- hash must contain only scalars and hashes
	- node ident must be unique key inside any sibling 
	- sibling are always accessed in ascending order

=back

=head2 Maintenance

	Author:	Marco
	date:	21.09.2006
	History
			21.09.2006 First draft

=cut

package ctkBtree;

use Time::localtime;

our $VERSION = 1.02;

our $debug = 0;

sub getStack { 
	my $self = shift;
	return wantarray ? @{$self->{_stack}} : $self->{_stack}
}

sub stack {
	my $self = shift;
	my $v = shift;
	my $s = $self->getStack;
	push (@$s,$v) if (defined $v);
	return 1
}

sub unstack {
	my $self = shift;
	my $rv;
	my $s = $self->getStack;
	$rv =  pop(@$s) if(@$s);
	return $rv
}

sub new {
	my $class = shift;
	my (%args) = @_;
	$class = ref($class) || $class ;
	## my $self = $class->SUPER::new(%args);
	my $self = {'_stack', []};
	$debug = delete $args{-debug} if exists $args{-debug};
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

sub _process {
	my $self = shift;
	my ($node,$c) = @_;
	my $rv;
	if (ref $c eq 'CODE') {
		&$c($self,$node)
	} elsif (ref $c eq 'ARRAY') {
		my $x = shift @$c;
		$rv = &$x ($self,$node,@$c);
	} else {
		die "Unexpected callback $c"
	}
	return $rv
}

sub traverse_DF_in {
	my $self = shift;
	my ($h,$c) = @_;
	$c = sub {1} unless defined($c);
	map {
		$self->stack($_);
		$self->traverse_DF_in($h->{$_},$c);
		$self->_process($_,$c);
		$self->unstack($_)
	} sort keys %$h;
	return undef
}

sub traverse_DF_pre {
	my $self = shift;
	my ($h,$c) = @_;
	$c = sub {1} unless defined($c);
	map {
		$self->stack($_);
		$self->_process($_,$c);
		$self->traverse_DF_pre($h->{$_},$c);
		$self->unstack($_);
	} sort keys %$h;
	return undef
}

sub BF_traverse {
	my $self = shift;
	my ($h,$c) = @_;
	$c = sub {1} unless defined($c);
	map {
		$self->stack($_);
		$self->_process($_,$c);
		$self->unstack($_)
	} sort keys %$h;
	map {
		$self->stack($_);
		$self->BF_traverse($h->{$_},$c);
		$self->unstack($_)
	} sort keys %$h;
	return undef
}

sub traverse_DF2_pre {
	my $self = shift;
	my ($h1,$h2,$c1,$c2,$c) = @_;
	$c1 = sub {1} unless defined($c1);
	$c2 = sub {1} unless defined($c2);
	$c = sub {1} unless defined($c);
	my $eos = 1;
	my @ak1 =  sort keys %$h1;
	my @ak2 =  sort keys %$h2;
	map {$eos = length($_) if(length($eos) < length($_))} (@ak1,@ak2);
	$eos = chr(255) x $eos;
	my $k1= $eos;
	my $k2= $eos;
	$k1 = shift @ak1 if (@ak1);
	$k2 = shift @ak2 if (@ak2);
	while (($k1 ne $eos) || ($k2 ne $eos)) {
		if ($k1 lt $k2) {
			$self->stack($k1);
			$self->onExist1($k1);
			$self->_process($k1,$c1);
			$self->traverse_DF2_pre($h1->{$k1},{},$c1,$c2,$c);
			$self->unstack;
			$k1 = shift @ak1;
			$k1 = $eos unless defined $k1;
		} elsif ($k1 gt $k2) {
			$self->stack($k2);
			$self->onExist2($k2);
			$self->_process($k2,$c2);
			$self->traverse_DF2_pre({},$h2->{$k2},$c1,$c2,$c);
			$self->unstack;
			$k2 = shift @ak2;
			$k2 = $eos unless defined $k2;
		} elsif ($k1 eq $k2) {
			$self->stack($k1);
			$self->onExist($k1);
			$self->_process($k2,$c);
			$self->traverse_DF2_pre($h1->{$k1},$h2->{$k2},$c1,$c2,$c);
			$self->unstack;
			$k1 = shift @ak1;
			$k1 = $eos unless defined $k1;
			$k2 = shift @ak2;
			$k2 = $eos unless defined $k2;
		} else {
			die "$k1 $k2 ??????"
		}
	}
	return undef
}

sub traverse_DF2x_pre {
	my $self = shift;
	my ($h1,$h2,$c1,$c2,$c) = @_;
	$c1 = sub {1} unless defined($c1);
	$c2 = sub {1} unless defined($c2);
	$c = sub {1} unless defined($c);
	my $eos = 1;
	my @ak1 =  sort keys %$h1;
	my @ak2 =  sort keys %$h2;
	map {$eos = length($_) if(length($eos) < length($_))} (@ak1,@ak2);
	$eos = chr(255) x $eos;
	my $k1= $eos;
	my $k2= $eos;
	$k1 = shift @ak1 if (@ak1);
	$k2 = shift @ak2 if (@ak2);
	while (($k1 ne $eos) || ($k2 ne $eos)) {
		if ($k1 lt $k2) {
			$self->stack($k1);
			$self->onExist1($k1);
			$self->_process($k1,$c1);
			##$self->traverse_DF2_pre($h1->{$k1},{},$c1,$c2,$c);
			$self->unstack;
			$k1 = shift @ak1;
			$k1 = $eos unless defined $k1;
		} elsif ($k1 gt $k2) {
			$self->stack($k2);
			$self->onExist2($k2);
			$self->_process($k2,$c2);
			## $self->traverse_DF2_pre({},$h2->{$k2},$c1,$c2,$c);
			$self->unstack;
			$k2 = shift @ak2;
			$k2 = $eos unless defined $k2;
		} elsif ($k1 eq $k2) {
			$self->stack($k1);
			$self->onExist($k1);
			$self->_process($k2,$c);
			$self->traverse_DF2_pre($h1->{$k1},$h2->{$k2},$c1,$c2,$c);
			$self->unstack;
			$k1 = shift @ak1;
			$k1 = $eos unless defined $k1;
			$k2 = shift @ak2;
			$k2 = $eos unless defined $k2;
		} else {
			die "$k1 $k2 ??????"
		}
	}
	return undef
}

sub onExist1 {
	my $self = shift;
	my ($node) = @_;
	$self->trace("Event onExist1 node '$node'");
}

sub onExist2 {
	my $self = shift;
	my ($node) = @_;
	$self->trace("Event onExist2 node '$node'");
}

sub onExist {
	my $self = shift;
	my ($node) = @_;
	$self->trace("Event onExist node '$node'");
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
	my ($now) = shift;
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
