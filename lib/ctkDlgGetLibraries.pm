#!/usr/lib/perl
##              -w -d:ptkdb

=pod

=head1 ctkDlgGetLibraries

	set up and excute dialog to enter 'use lib' libraries

=head2 Programming notes

=over

=item

=back

=head2 Maintenance

	Author:	MARCO
	date:	01.01.2007
	History
			06.12.2007 refactoring

=cut

package ctkDlgGetLibraries;

our $VERSION = 1.01;

our $debug = 0;

sub dlg_libraries_onAdd {
	my $lb = shift;
	my @x = $lb->curselection;

	my @dirs = $lb->get('0','end');
	my $db = ctkDirDialog::dirDialogModal("",'./');
	my $answ = $db->Show();
	if ($answ =~ /ok/i) {
		my $s = &ctkDirDialog::getdirDialogResult();
		if ($s) {
			if (@x) {
				$lb->insert($x[0],$s) unless grep ($s eq $_, @dirs);
			} else {
				$lb->insert('end',$s) unless grep ($s eq $_, @dirs);
			}
		}
	}
	&ctkDirDialog::dirDialogOnDTCancel();
}

sub dlg_libraries_onDelete {
	my $lb = shift;
	my @x = $lb->curselection;
	$lb->delete($x[0]) if (@x);
}

sub dlg_libraries_onMoveUp {
	my $lb = shift;
	my @x = $lb->curselection;
	return unless(@x);
	return unless($x[0]);
	my $i =$x[0]; $i--;
	my $s = $lb->get($x[0]);
	$lb->delete($x[0]) if (@x);
	$lb->insert($i,$s);
}

sub dlg_libraries_onMoveDown {
	my $lb = shift;
	my @x = $lb->curselection;
	return unless(@x);
	return if ($x[0] >= ($lb->index('end') - 1));
	my $s = $lb->get($x[0]);
	my $i = $x[0]; $i++;
	$lb->delete($x[0]);
	$lb->insert($i,$s);
}

sub dlg_libraries {
	my $self = shift;
	my $hwnd = shift;
	my (%args) = @_;
	my $rv;

	&main::trace("dlg_libraries");
	$hwnd = &main::getmw() unless defined($hwnd);

	my ($wr_007,$wr_006,$wr_005,$wr_004,$wr_003,$wr_002,$wr_001);

	my $mw = $hwnd->ctkDialogBox(
		-title=> (exists $args{-title})? $args{-title}:'Get libraries',
		 -buttons=> (exists $args{-buttons}) ? $args{-buttons} : ['OK','Cancel']);
	$mw->protocol('WM_DELETE_WINDOW',sub{1});

	$wr_001 = $mw -> Frame ( -relief , 'flat'  ) -> pack(-anchor=>'nw', -side=>'top', -fill=>'both', -expand=>1);
	$wr_003 = $wr_001 -> Listbox ( -background , '#ffffff' , -selectmode , 'single' , -relief , 'sunken' , -width , 48 ) -> pack(-ipady=>2, -ipadx=>2, -anchor=>'nw', -side=>'top', -fill=>'both', -expand=>1);
	$wr_002 = $mw -> Frame ( -relief , 'flat'  ) -> pack(-anchor=>'nw', -side=>'top', -fill=>'x', -expand=>1);
	$wr_004 = $wr_002 -> Button ( -background , '#ffffff' , -command , [\&dlg_libraries_onAdd,$wr_003] , -state , 'normal' , -relief , 'raised' , -text , 'Add '  ) -> pack(-side=>'left', -anchor=>'nw', -ipadx=>2, -ipady=>2, -fill=>'x', -expand=>1);
	$wr_006 = $wr_002 -> Button ( -background , '#ffffff' , -command , [\&dlg_libraries_onMoveUp,$wr_003] , -state , 'normal' , -relief , 'raised' , -text , 'Up'  ) -> pack(-ipady=>2, -ipadx=>4, -anchor=>'nw', -side=>'left', -fill=>'x', -expand=>1);
	$wr_007 = $wr_002 -> Button ( -background , '#ffffff' , -command , [\&dlg_libraries_onMoveDown,$wr_003] , -state , 'normal' , -relief , 'raised' , -text , 'Down'  ) -> pack(-ipady=>2, -ipadx=>4, -anchor=>'nw', -side=>'left', -fill=>'x', -expand=>1);
	$wr_005 = $wr_002 -> Button ( -background , '#ffffff' , -command , [\&dlg_libraries_onDelete,$wr_003] , -state , 'normal' , -text , 'Delete'  ) -> pack(-side=>'left', -anchor=>'nw', -ipadx=>2, -ipady=>2, -fill=>'x', -expand=>1);

	@ctkProject::libraries = ($ctkApplication::applFolder) if (-d $ctkApplication::applFolder && @ctkProject::libraries == 0);
	$wr_003->insert('end',@ctkProject::libraries);

	$mw->bind('<Return>','');
	$rv =  $mw->Show();
		if ($rv =~/ok/i) {
			@ctkProject::libraries = $wr_003->get('0','end');
			&main::changes(1);
			$rv = 1
		} else {
			$rv = 0;
		}
	return $rv;

}		## end of dlg_libraries

1; ## -----------------------------------

