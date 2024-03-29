$rDescriptor = {
  'mw' => bless( {}, 'ctkDescriptor' ),
  'rLeftFrame' => bless( {
    'parent' => 'mw',
    'geom' => 'pack(-anchor=>nw, -side=>left, -fill=>both, -expand=>1)',
    'id' => 'rLeftFrame',
    'type' => 'Frame',
    'opt' => '-borderwidth=>1, -label=>\'Left frame\', -relief=>solid'
  }, 'ctkDescriptor' ),
  'rRightFrame' => bless( {
    'parent' => 'mw',
    'geom' => 'pack(-anchor=>ne, -side=>right, -fill=>both, -expand=>1)',
    'id' => 'rRightFrame',
    'type' => 'Frame',
    'opt' => '-borderwidth=>1, -label=>\'Right frame\', -relief=>solid'
  }, 'ctkDescriptor' ),
  'rBottomFrame' => bless( {
    'parent' => 'mw',
    'geom' => 'pack(-anchor=>s, -side=>bottom, -fill=>x, -expand=>1)',
    'id' => 'rBottomFrame',
    'type' => 'Frame',
    'opt' => '-borderwidth=>1, -label=>\'Bottom frame\', -relief=>solid'
  }, 'ctkDescriptor' ),
  'rTopFrame' => bless( {
    'parent' => 'mw',
    'geom' => 'pack(-anchor=>nw, -side=>top, -fill=>x, -expand=>1)',
    'id' => 'rTopFrame',
    'type' => 'Frame',
    'opt' => '-borderwidth=>1, -label=>\'Top frame\', -relief=>solid'
  }, 'ctkDescriptor' )
};
$rTree = [
  'mw',
  'mw.rTopFrame',
  'mw.rBottomFrame',
  'mw.rLeftFrame',
  'mw.rRightFrame'
];
$rUser_subroutines = [
  'sub init { 1 }'
];
$rUser_methods_code = [];
$rUser_gcode = [];
$rOther_code = [];
$rUser_pod = [];
$rUser_auto_vars = [];
$rUser_local_vars = [];
$rFile_opt = {
  'pod' => '=head1 Description

	This widget provides the basics for a dialog with four frames:
		- top frame (title, toolbar, ...
		- bottom frame for status informations
		- left and right frame for application\'s subwidgets

=cut
',
  'isolate_geom' => 0,
  'modal' => '0',
  'description' => 'Standard dialog with 4 frames.',
  'Toplevel' => 1,
  'strict' => '1',
  'title' => 'Standard dialog with 4 frames.',
  'code' => '0',
  'gcode' => ''
};
$rProjectName = \undef;
$ropt_isolate_geom = \undef;
$rHiddenWidgets = [];
$rLibraries = [];
$rApplName = \'';
$rApplFolder = \'';
$opt_TestCode = \1;
