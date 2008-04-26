$rDescriptor = {
  'wr_001' => bless( {
    'parent' => 'mw',
    'geom' => 'pack(-side=>top, -anchor=>nw, -pady=>5, -fill=>x, -expand=>1, -padx=>5)',
    'order' => undef,
    'id' => 'wr_001',
    'type' => 'Listbox',
    'opt' => '-background , #ffffff , -selectmode , single , -relief , sunken'
  }, 'ctkDescriptor' ),
  'mw' => bless( {
    'parent' => undef,
    'geom' => undef,
    'order' => undef,
    'id' => 'mw',
    'type' => 'Frame',
    'opt' => undef
  }, 'ctkDescriptor' ),
  'wr_002' => bless( {
    'parent' => 'mw',
    'geom' => 'pack(-side=>top, -anchor=>nw, -pady=>5, -fill=>x, -expand=>1, -padx=>5)',
    'order' => undef,
    'id' => 'wr_002',
    'type' => 'Button',
    'opt' => '-background , #ffffff , -command , sub{1} , -state , normal , -text , Test'
  }, 'ctkDescriptor' )
};
$rTree = [
  'mw',
  'mw.wr_001',
  'mw.wr_002'
];
$rUser_subroutines = [
  'sub init { 1 }',
  'sub test_01 {',
  '	shift->_show()',
  '}'
];
$rUser_methods_code = [
  'sub _show {',
  '	my $rv = shift->Show();',
  '	return $rv',
  '}'
];
$rUser_gcode = [];
$rOther_code = [];
$rUser_pod = [];
$rUser_auto_vars = [
  '$xyz'
];
$rUser_local_vars = [];
$rFile_opt = {
  'modal' => '0',
  'subWidgets' => [
    {
      'public' => '1',
      'name' => 'List',
      'ident' => 'wr_001'
    },
    {
      'public' => '1',
      'name' => 'Test',
      'ident' => 'wr_002'
    }
  ],
  'autoExtractVariables' => '1',
  'subroutineName' => 'thisDialog',
  'description' => 'Test composite based on DialogBox',
  'autoExtract2Local' => '1',
  'baseClass' => 'Tk::DialogBox',
  'strict' => '1',
  'subroutineArgs' => '',
  'Toplevel' => '1',
  'title' => 'Extended DialogBox',
  'modalDialogClassName' => 'DialogBox',
  'code' => '3',
  'onDeleteWindow' => 'sub{exit(0)}'
};
$rLastfile = \'DialogBoxX.pl';
$ropt_isolate_geom = \'0';
$rHiddenWidgets = [];
$rLibraries = [];
$rApplName = \'';
$rApplFolder = \'';
$opt_TestCode = \'1';
