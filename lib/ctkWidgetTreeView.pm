#!/usr/lib/perl
##              -w -d:ptkdb

=pod

=head1 ctkWidgetTreeView

	Set up and maintain the View which shows the widget's tree.

=head2 Programming notes

=over

=item This class is not a mega widget.

	This is due to the fact that im not sure whether
	a Scrolled widget works fine in a composite.
	Somewhere I have read that it does not!
	TODO: do some test in this respect.

	This class simply encapsulates the activities
	based on the widgets tree.

=item options

	main::HListDefaultWidth,
	main::HListDefaultHeight
	main::HListSelectMode

=item Methods

	setupTree  (constructor)
	setSelected
	repaint
	add
	delete
	selectionSet

=back

=head2 Maintenance

	Author:	MARCO
	date:	01.01.2007
	History
			06.12.2007 refactoring
			28.02.2008 MO03605
			17.04.2008 version 1.03 (tearoff, updatePopup)

=cut

package ctkWidgetTreeView;

use strict;

use ctkBase;
use base (qw/ctkBase/);

our $VERSION = 1.03;

our $tf;

my $tearoff = 0;

=head2 setupTree

=cut

sub setup {
	my $self = shift;
	my ($parent,$MW,$pic) = @_ ;
	$self->trace("setupTree");

	my $rv= $parent->Scrolled('Tree',-scrollbars => "osoe",
			-drawbranch => 1,
			-header => 1,
			-indicator => 1,
			-itemtype   => 'imagetext',
			-separator  => '.',
			-selectmode => $main::HListSelectMode,
			-browsecmd  => [sub {},undef],
			-selectbackground => 'blue',
			-selectforeground => 'white',
			-command => [sub {},undef],
			## -opencmd => sub{1},
			## -closecmd => sub{1},
			-ignoreinvoke => 0,
			-bg => '#E5E5E5',
			-width =>  $main::HListDefaultWidth,
			-height => $main::HListDefaultHeight,
			-font => $parent->toplevel->Font(-family => 'Courier', -size => 10, -weight => 'normal')
			);

	$rv->pack(-side=>'left',-anchor => 'nw', -expand => 1, -fill=>'both');

	$rv->add("$MW",-text=>$MW,-data=>$MW);

	$rv->configure(
				-command  => sub{
						&main::set_selected($tf->info('data',$tf->infoSelection));
						&main::edit_widgetOptions
						},
				-browsecmd=> sub{
						&main::set_selected($tf->info('data',$tf->infoSelection));
						ctkMenu->updateMenu();
						my $editTreeState= &main::computeEditTreeState();
						ctkMenu->updatePopup($main::popup,$editTreeState);
						} );


	$parent->packAdjust(-side=>'left',-anchor => 'nw', -expand => 1, -fill => 'y');

	$rv->bind('<Button-3>',
		sub{
		&main::set_selected($tf->nearest($tf->pointery-$tf->rooty));
		my $editTreeState= &main::computeEditTreeState();
		ctkMenu->updatePopup($main::popup,$editTreeState);
		$main::popup->Post(&main::getmw->pointerxy);
		if ($main::popupmenuTearoff) {
			$main::popup->configure(-tearoffcommand => [sub {shift->trace("tearoffcommand")},$self]);
		}
		return undef
		});
	$tf = $rv;
	return $rv;
}

sub setSelected {	## u MO03605
	my $self = shift;
	$tf->anchorClear(); $tf->selectionClear();
	my $s = &main::getSelected;
	if ($s) {
		$tf->anchorSet($s);
		$tf->selectionSet($s);
	}
	return undef
}

sub repaint {
	my $self = shift;
	my ($deleteAll,$pic) = @_;
	&main::trace("tree_repaint");

	$pic = &main::get_picW unless defined($pic);
	$deleteAll = 1 unless defined($deleteAll);

	my $t = $tf->cget(-itemtype);
	my $hidden = $tf->ItemStyle($t , -foreground=>'#FF0000');

	$tf->delete('all') if ($deleteAll);
	my $type;
	my $picN;
	map {
		$picN = &main::getWidgetIconName(&main::path_to_id($_));
		if (&main::isHidden(&main::path_to_id($_))) {
			$tf->add($_,
				-style => $hidden,
				-text => &main::path_to_id($_),
				-data => $_,
				-image => $pic->{$picN}
			) unless $tf->info('exists',$_);
		} else {
			$tf->add($_,
				-text => &main::path_to_id($_),
				-data => $_,
				-image => $pic->{$picN}
			) unless $tf->info('exists',$_);
		}
	} @ctkProject::tree;
	$tf->autosetmode();
	## delete ctkProject->descriptor->{$MW};
	return 1;
}

sub info {
	my $self = shift;
	$tf->info(@_);
}


sub add {
	my $self = shift;
	$tf->add(@_);
}

sub delete {
	my $self = shift;
	$tf->delete(@_);
}

sub selectionSet {
	my $self = shift;
	$tf->selectionSet(@_)
}
1; ## -----------------------------------

