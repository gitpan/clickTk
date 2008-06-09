#!/usr/lib/perl
##              -w -d:ptkdb

=pod

=head1 ctkPreview

	Set up the preview widget.

=head2 Programming notes

=over

=item

=back

=head2 Maintenance

	Author:	MARCO
	date:	03.12.2007
	History
			03.12.2007 version 1.01

=cut

package ctkPreview;

use strict;
use base (qw/ctkBase/);

our $VERSION = 1.01;

our $debug = 0;

our $wPreview;

our $opt_useToplevel;

our $initialGeometryPreview = '=500x500+420+10';

our $view_pointerxy = 0;

our %widgets =();

our $xy;

our $suppressCallbacks = 1;

sub clearWidgets {
	my $self = shift;
	%widgets = ();
}
=head2 unbind_xy_move

=cut

sub unbind_xy_move {
	my $self = shift;
	my ($widget) = @_;
	$widget->bind('<Motion>','')
}

=head2 bind_xy_move

=cut

sub bind_xy_move {
	my $self = shift;
	my ($widget) = @_;
	&main::trace("bind_xy_move");
	if ($view_pointerxy) {
		$widget->bind('<Motion>',
					sub{
						my($x,$y)=$wPreview->pointerxy;
						$x-=$wPreview->rootx;
						$y-=$wPreview->rooty;
						$xy="x=$x y=$y"
						}
				)
	} else {
		$self->unbind_xy_move($widget);
	}
}


=head2 clear_preview

=cut

sub init {
	my $self =shift;
	&main::trace("init");
	$wPreview->destroy if(defined($wPreview));
	undef $wPreview;
	$self->clear();
	$self->repaint()
}

=head2 switch2Frame

=cut

sub switch2Frame {
	my $self =shift;
	&main::trace("switch2Frame");
	$opt_useToplevel = 0;
	$self->init()
}

sub clear {
	my $self =shift;
	&main::trace("clear");
	my $w_attr = &main::getW_attr;
	my $widgets = &main::getWidgets;

	if (Tk::Exists($wPreview)) {
		# TODO: unbind here ???
		map {
			$main::b->detach($_) if(defined($_) && $_->can('class') && $w_attr->{$_->class}->{balloon})
		} values %$widgets;
		map {$_->destroy} $wPreview->children;
		$self->unbind_xy_move($wPreview);
	}
	map {delete $widgets->{$_}} keys %$widgets;
	$xy = '';
	unless(defined($wPreview)) {
		if ($opt_useToplevel) {
			$wPreview = &main::getmw()->Toplevel(-title => &std::_title('preview'));
			$wPreview->protocol ('WM_DELETE_WINDOW',sub{ctkPreview->switch2Frame});
			$wPreview->geometry($initialGeometryPreview);
		} else {
			$wPreview=$main::main_frame->Frame(-relief=>'flat',-borderwidth=>0)
								->pack(-side => 'top',-anchor => 'ne',-fill=>'both',-expand=>1);
		}
		## &main::bind_xy_move($wPreview);
	}
	$self->bind_xy_move($wPreview);
}

=head2 repaint

	Paint the preview
		DO call clear preview
		DO set my %tmp_vars = ($MW => $wPreview)
		DO scan @ctkProject::tree and adapt some arguments
		DO FOR all widgets on @ctkProject::tree
			DO set up standard constructor
			DO set up widget (eval stdConstructor)
			DO set up geometry options
			DO set up balloon
			DO set up bindings (click, double-click, right click)
			DO execute geometry manager
			DO set $widgets{path} := tmp_vars{$id}
		END
		DO set  $widgets{$MW} := $wPreview

=cut

sub repaint {
	my $self =shift;
	my @err = ();
	my $MW = &main::getMW;
	my $widgets = &main::getWidgets;
	&main::trace("repaint");
	$self->clear();
	my %tmp_vars=($MW => $wPreview); # those variables exist only for 'redraw' window
	my $stdConstructor ;
	my $scrolledConstructor;

	foreach my $path (@ctkProject::tree[1..$#ctkProject::tree]) {
		my $id=&main::path_to_id($path);
		next unless defined $id;
		next unless exists ctkProject->descriptor->{$id};
		next if (&main::nonVisual(&main::getType($id)));
		&main::trace("path='$path'","id='$id'");
		my $d=ctkProject->descriptor->{$id};
		my $x=$tmp_vars{$d->parent};
		my @arg=&main::split_opt($d->opt);
		if (grep /^-image/,@arg) {				## temp 24.07.2005 MO01001
			if (grep /^text/,@arg) {
				for (my $i = 0;$i < scalar(@arg) ; $i+= 2) {
					if ($arg[$i] =~ /-text/) {
						splice @arg,$i,2;
						last
					}
				}
			} ## else {}
			for (my $i = 0;$i < scalar(@arg) ; $i+= 2) {	## i MO1001 temp 24.07.2005
				if ($arg[$i] =~ /-image/) {
					for (my $i = 0;$i < scalar(@arg) ; $i+= 2) {
						if ($arg[$i] =~ /-text/) {
							splice @arg,$i,2;
							last
						}
					}
					my $w = $arg[$i+1];
					$w =~ s/^\$//;
					if (exists $tmp_vars{$w}) {
						$arg[$i+1] = $tmp_vars{$w};
					} else {
						$arg[$i] = '-text';
						$arg[$i+1] ="<image $arg[$i+1]>";
					}
					last;
				} ## else{}
			}

		} ## else{}
		for (my $i = 0;$i < scalar(@arg) ; $i++) {
				if ($arg[$i] =~/^-font$/) {
					my $w = &main::string2Array($arg[$i+1]);
					$arg[$i+1] = $w if (@$w);
					last
				}
		}
		if(grep(/(-command|-\w+cmd)/,@arg)) {
			my (%arg)=@arg;
			foreach my $par(qw/command createcmd raisecmd/){ 	## overwrite callbacks option to edit the callbacks itself (mam)
				if ($suppressCallbacks) {
					$arg{"-$par"}=sub{1} if(exists $arg{"-$par"});
				} else {
					$arg{"-$par"}=[\&main::callback,$arg{"-$par"}] if(exists $arg{"-$par"});
				}
			}
			(@arg)=(%arg);
		}

##		set up standard constructor (for scrolled or non-scrolled widgets)

		if ($d->type =~ /^Scrolled([a-zA-Z]+)/) {
			$stdConstructor = "\$tmp_vars{$id} = \$x->Scrolled('$1',\@narg)";
		} else {
			$stdConstructor = "\$tmp_vars{$id} = \$x->$d->{type}(\@arg)";
		}
		&main::trace("stdConstructor = '$stdConstructor'");

##
##		check class for special handling :
##		some widget class need pre- or post-processing
##

		if (($d->type eq 'ScrolledText') or
				 ($id =~ /ScrolledText/ && $d->type eq 'Scrolled')) {
			my @narg =('-scrollbars',' ');
			for (my $i = 0 ;$i < scalar(@arg) ; $i+= 2) {
				&main::trace("i=$i,arg='$arg[$i]'");
				if($arg[$i] =~ /-scrollbars/) {
					$narg[1] = $arg[$i+1];
				} else {
					push @narg, $arg[$i];
					push @narg,$arg[$i+1];
				}
			}
			&main::trace(@narg);
			eval $stdConstructor;
			push @err, $@ if ($@);
			$tmp_vars{$id}->menu(undef);
		} elsif(($d->type eq 'ScrolledROText') or ($id =~ /ScrolledROText/ && $d->type eq 'Scrolled')) {
			my @narg =('-scrollbars',' ');
			for (my $i = 0 ;$i < scalar(@arg) ; $i+= 2) {
				&main::trace("i=$i,arg='$arg[$i]'");
				if($arg[$i] =~ /-scrollbars/) {
					$narg[1] = $arg[$i+1];
				} else {
					push @narg, $arg[$i];
					push @narg,$arg[$i+1];
				}
			}
			&main::trace(@narg);
			eval $stdConstructor; ## $tmp_vars{$id} = $x->Scrolled('Text',@narg);
			push @err, $@ if ($@);
			$tmp_vars{$id}->menu(undef);
		} elsif(($d->type eq 'ScrolledTextUndo') or ($id =~ /ScrolledTextUndo/ && $d->type eq 'Scrolled')) {
			my @narg =('-scrollbars',' ');
			for (my $i = 0 ;$i < scalar(@arg) ; $i+= 2) {
				&main::trace("i=$i,arg='$arg[$i]'");
				if($arg[$i] =~ /-scrollbars/) {
					$narg[1] = $arg[$i+1];
				} else {
					push @narg, $arg[$i];
					push @narg,$arg[$i+1];
				}
			}
			&main::trace(@narg);
			eval $stdConstructor; ## $tmp_vars{$id} = $x->Scrolled('Text',@narg);
			push @err, $@ if ($@);
			$tmp_vars{$id}->menu(undef);
		} elsif(($d->type eq 'ScrolledTextEdit') or ($id =~ /ScrolledTextEdit/ && $d->type eq 'Scrolled')) {
			my @narg =('-scrollbars',' ');
			for (my $i = 0 ;$i < scalar(@arg) ; $i+= 2) {
				&main::trace("i=$i,arg='$arg[$i]'");
				if($arg[$i] =~ /-scrollbars/) {
					$narg[1] = $arg[$i+1];
				} else {
					push @narg, $arg[$i];
					push @narg,$arg[$i+1];
				}
			}
			&main::trace(@narg);
			eval $stdConstructor; ## $tmp_vars{$id} = $x->Scrolled('Text',@narg);
			push @err, $@ if ($@);
			$tmp_vars{$id}->menu(undef);
			$tmp_vars{$id}->SetGUICallbacks([sub{1}]);
		} elsif($d->type eq 'TextEdit')  {
			eval $stdConstructor; ## $tmp_vars{$id} = $x->Scrolled('Text',@narg);
			push @err, $@ if ($@);
			$tmp_vars{$id}->menu(undef);
			$tmp_vars{$id}->SetGUICallbacks([sub{1}]);
		} elsif(($d->type eq 'ScrolledListbox') or ($id =~ /ScrolledListbox/ && $d->type eq 'Scrolled') ) {
			my @narg =('-scrollbars',' ');
			&main::trace('@arg=',@arg);
			for (my $i = 0 ;$i < scalar(@arg) ; $i+= 2) {
				if($arg[$i] =~ /-scrollbars/) {
					$narg[1] = $arg[$i+1];
				} else {
					push @narg, $arg[$i];
					push @narg,$arg[$i+1];
				}
			}
			&main::trace(@narg);
			eval $stdConstructor;
			push @err, $@ if ($@);
		} elsif($d->type eq 'BrowseEntry') {
			my $w;
			my (%arg)=@arg;
			if (exists $arg{-choices}) {
				$w = $arg{-choices};
				$arg{-choices} = eval $w ;
			} else {
				$arg{-choices} = [qw/dummy_1 dummy_2 dummy_3/]		## dummy
			}
			$w = &main::convertToList(delete $arg{'-labelPack'},\@err);
			$tmp_vars{$id} = $x->BrowseEntry((%arg), -labelPack=>$w);
		} elsif($d->type eq 'LabEntry'){
			my (%arg)=@arg;
			my $w = &main::convertToList(delete $arg{'-labelPack'},\@err);
			$w = [] unless defined($w);
			$tmp_vars{$id} = $x->LabEntry(%arg,-labelPack=>$w);
		} elsif($d->type eq 'Listbox') {
			eval $stdConstructor;
			push @err, $@ if ($@);
			$tmp_vars{$id}->insert('end', qw/item_1 item_2 item_3/);
		} elsif($d->type eq 'Optionmenu') {
			$tmp_vars{$id} = $x->Optionmenu(-options=>[qw/item_1 item_2 item_3/]);
		} elsif($d->type eq 'NoteBookFrame')  {
				$tmp_vars{$id} = $x->add($id,@arg);
		} elsif($d->type eq 'Menu')  {
			# For cascade-based Menu use root menu widget in place of $x:
			my $root_menu=$x;
			$root_menu=$tmp_vars{ctkProject->descriptor->{$d->parent}->parent} if (ctkProject->descriptor->{$d->parent}->type eq 'cascade');
			$tmp_vars{$id} = $root_menu->Menu(@arg);
			$root_menu->configure(-menu=>$tmp_vars{$id});
			##    $x->configure(-menu=>$tmp_vars{$id});
		} else {
			eval $stdConstructor;
			push @err, $@ if ($@);
			## &std::ShowDialog(-title=>"Error:",-text=>"ERROR: widget of type ".$d->type." can't be displayed!");
			## &main::Log("ERROR: widget of type ".$d->type." can't be displayed!");
		}

		unless (defined($tmp_vars{$id})) {
			&main::log("Could not repaint '$id', skipped");
			next
		}

		if (&main::haveGeometry($d->type)) {

			next if (&main::isHidden($id));

			my ($geom,$geom_opt)=(split '[)(]',$d->geom);
			map {s/^\s+//;s/\s+$//}($geom,$geom_opt);
			my $balloonmsg;

			$balloonmsg=&main::gen_WidgetCode($path);
			$balloonmsg =~ s/ -> / ->\n/g;
			&main::trace("id='$id'",ref($tmp_vars{$id}),"balloonmsg='$balloonmsg'"," ");


			$main::b->attach($tmp_vars{$id},-balloonmsg=>$balloonmsg) if ($main::view_balloons &&
									&main::getW_attr ->{$d->type}->{balloon});
			$tmp_vars{$id}->Tk::bind('<Button-3>', sub{&main::set_selected(ctkWidgetTreeView->info('data',$path));$main::popup->Post(&main::getmw->pointerxy)});
			$tmp_vars{$id}->Tk::bind('<Button-1>', sub{&main::set_selected(ctkWidgetTreeView->info('data',$path))});
			$tmp_vars{$id}->Tk::bind('<Double-1>', sub{&main::set_selected(ctkWidgetTreeView->info('data',$path));&main::edit_widgetOptions});

			$self->bind_xy_move($tmp_vars{$id});

			if($geom eq 'pack') {
				$tmp_vars{$id}->pack(&main::split_opt($geom_opt));
			} elsif($geom eq 'grid') {
				$tmp_vars{$id}->grid(&main::split_opt($geom_opt));
			} elsif($geom eq 'place') {
				$tmp_vars{$id}->place(&main::split_opt($geom_opt));
			} elsif($geom eq 'form') {
				my @w = &main::split_opt($geom_opt);
				my $wx = &main::quotatZ(\@w,\%tmp_vars);
				if (defined $wx) {
					$tmp_vars{$id}->form(@$wx);
				} else {
					push @err, $@ if ($@);
				}

			} else {
				die "Unexpected geometry manager '$geom'"
			}
		}
		$widgets->{$path}=$tmp_vars{$id};
	}
	$widgets->{$MW}=$wPreview;
	if (@err) {
		&std::ShowWarningDialog("Syntax error occurred while repainting preview:\n\n".join ("\n",@err));
		@err =();
	}
}

1; ## -----------------------------------

