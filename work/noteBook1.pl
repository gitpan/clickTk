$rDescriptor = {
  'w_Frame_015' => bless( {
    'parent' => 'w_Frame_001',
    'geom' => 'pack(-anchor=>nw, -side=>top, -fill=>both, -expand=>1)',
    'order' => undef,
    'id' => 'w_Frame_015',
    'type' => 'Frame',
    'opt' => ''
  }, 'ctkDescriptor' ),
  'wr_023' => bless( {
    'parent' => 'wr_018',
    'geom' => 'grid(-row=>1, -column=>1, -sticky=>ne)',
    'order' => undef,
    'id' => 'wr_023',
    'type' => 'LabEntry',
    'opt' => '-background , #ffffff , -justify , left , -label , Size___2 , -relief , sunken , -labelPack , [-side , left , -anchor , n ] , -textvariable , \\$option5 , -state , normal , -width , 6'
  }, 'ctkDescriptor' ),
  'w_Button_019' => bless( {
    'parent' => 'w_Frame_015',
    'geom' => 'pack(-anchor=>nw, -side=>left, -pady=>2, -fill=>x, -expand=>1)',
    'order' => undef,
    'id' => 'w_Button_019',
    'type' => 'Button',
    'opt' => '-background , #ffffff , -command , \\&do_exit_0 , -state , normal , -text , Cancel'
  }, 'ctkDescriptor' ),
  'w_Frame_001' => bless( {
    'parent' => 'mw',
    'geom' => 'pack(-side=>top, -anchor=>nw, -fill=>both, -expand=>1)',
    'order' => undef,
    'id' => 'w_Frame_001',
    'type' => 'Frame',
    'opt' => '-relief , flat'
  }, 'ctkDescriptor' ),
  'w_Entry_007' => bless( {
    'parent' => 'w_Frame_005',
    'geom' => 'pack(-anchor=>nw, -side=>left, -fill=>x, -expand=>1)',
    'order' => undef,
    'id' => 'w_Entry_007',
    'type' => 'Entry',
    'opt' => '-borderwidth , 1 , -justify , left , -relief , sunken , -textvariable , \\$sub , -state , normal'
  }, 'ctkDescriptor' ),
  'wr_019' => bless( {
    'parent' => 'wr_018',
    'geom' => 'grid(-row=>0, -sticky=>nw, -column=>0)',
    'order' => undef,
    'id' => 'wr_019',
    'type' => 'Checkbutton',
    'opt' => '-relief , flat , -variable , \\$option1 , -state , normal , -justify , left , -text , Option___1 , -onvalue , 1'
  }, 'ctkDescriptor' ),
  'wr_018' => bless( {
    'parent' => 'wr_NoteBookFrame_005',
    'geom' => 'pack(-side=>top, -anchor=>nw, -fill=>both, -expand=>1)',
    'order' => undef,
    'id' => 'wr_018',
    'type' => 'Frame',
    'opt' => '-borderwidth , 2 , -relief , flat'
  }, 'ctkDescriptor' ),
  'w_Frame_017' => bless( {
    'parent' => 'w_Frame_001',
    'geom' => 'pack(-anchor=>sw, -side=>bottom, -fill=>x, -expand=>1)',
    'order' => undef,
    'id' => 'w_Frame_017',
    'type' => 'Frame',
    'opt' => ''
  }, 'ctkDescriptor' ),
  'w_NoteBook_002' => bless( {
    'parent' => 'w_Frame_001',
    'geom' => 'pack(-anchor=>nw, -side=>top, -pady=>5, -fill=>both, -expand=>1, -padx=>5)',
    'order' => undef,
    'id' => 'w_NoteBook_002',
    'type' => 'NoteBook',
    'opt' => '-background , #80ffff , -foreground , #ffffff , -focuscolor , #8080ff , -backpagecolor , #0080ff , -inactivebackground , #0080c0'
  }, 'ctkDescriptor' ),
  'wr_021' => bless( {
    'parent' => 'wr_018',
    'geom' => 'grid(-row=>2, -column=>0, -sticky=>nw)',
    'order' => undef,
    'id' => 'wr_021',
    'type' => 'Checkbutton',
    'opt' => '-relief , flat , -variable , \\$option3 , -state , normal , -justify , left , -text , Option___3 , -onvalue , 3'
  }, 'ctkDescriptor' ),
  'mw' => bless( {
    'parent' => undef,
    'geom' => undef,
    'order' => undef,
    'id' => 'mw',
    'type' => 'Frame',
    'opt' => undef
  }, 'ctkDescriptor' ),
  'w_NoteBookFrame_003' => bless( {
    'parent' => 'w_NoteBook_002',
    'geom' => undef,
    'order' => undef,
    'id' => 'w_NoteBookFrame_003',
    'type' => 'NoteBookFrame',
    'opt' => '-anchor , nw , -label , \'Record view\' , -justify , left , -createcmd , sub{print"\\ncreatecmd1 @_" } , -state , normal'
  }, 'ctkDescriptor' ),
  'w_Frame_005' => bless( {
    'parent' => 'w_NoteBookFrame_003',
    'geom' => 'pack(-side=>top, -anchor=>nw, -pady=>5, -padx=>5)',
    'order' => undef,
    'id' => 'w_Frame_005',
    'type' => 'Frame',
    'opt' => '-relief , flat'
  }, 'ctkDescriptor' ),
  'w_Label_020' => bless( {
    'parent' => 'w_Frame_017',
    'geom' => 'pack(-anchor=>nw, -side=>left, -fill=>x, -expand=>1)',
    'order' => undef,
    'id' => 'w_Label_020',
    'type' => 'Label',
    'opt' => '-background , #c0c0c0 , -justify , left , -relief , flat , -text , \'Status and messages.\''
  }, 'ctkDescriptor' ),
  'w_Button_018' => bless( {
    'parent' => 'w_Frame_015',
    'geom' => 'pack(-side=>left, -anchor=>nw, -pady=>2, -fill=>x, -expand=>1)',
    'order' => undef,
    'id' => 'w_Button_018',
    'type' => 'Button',
    'opt' => '-background , #ffffff , -command , sub{ &do_exit_1 } , -state , normal , -text , OK , -relief , raised'
  }, 'ctkDescriptor' ),
  'wr_NoteBookFrame_005' => bless( {
    'parent' => 'w_NoteBook_002',
    'geom' => undef,
    'order' => undef,
    'id' => 'wr_NoteBookFrame_005',
    'type' => 'NoteBookFrame',
    'opt' => '-raisecmd , sub{print"\\nraisecmd3 @_"} , -justify , left , -label , Options , -createcmd , sub{ print "\\ncreatecmd3 @_"  } , -state , normal'
  }, 'ctkDescriptor' ),
  'w_Entry_011' => bless( {
    'parent' => 'w_Frame_009',
    'geom' => 'pack(-side=>left, -anchor=>nw, -fill=>x, -expand=>1)',
    'order' => undef,
    'id' => 'w_Entry_011',
    'type' => 'Entry',
    'opt' => '-borderwidth , 1 , -justify , left , -relief , sunken , -textvariable , \\$subclasse , -state , normal'
  }, 'ctkDescriptor' ),
  'wr_022' => bless( {
    'parent' => 'wr_018',
    'geom' => 'grid(-row=>0, -sticky=>e, -column=>1)',
    'order' => undef,
    'id' => 'wr_022',
    'type' => 'LabEntry',
    'opt' => '-background , #ffffff , -label , Size___1 , -labelPack , [-side , left , -anchor , n ] , -width , 6 , -state , normal , -justify , left , -relief , sunken , -textvariable , \\$option4'
  }, 'ctkDescriptor' ),
  'w_Label_010' => bless( {
    'parent' => 'w_Frame_009',
    'geom' => 'pack(-side=>left, -anchor=>nw, -fill=>x, -expand=>1)',
    'order' => undef,
    'id' => 'w_Label_010',
    'type' => 'Label',
    'opt' => '-relief , flat , -background , #c0c0c0 , -width , 32 , -justify , left , -text , subclasses'
  }, 'ctkDescriptor' ),
  'w_NoteBookFrame_004' => bless( {
    'parent' => 'w_NoteBook_002',
    'geom' => undef,
    'order' => undef,
    'id' => 'w_NoteBookFrame_004',
    'type' => 'NoteBookFrame',
    'opt' => '-raisecmd , sub{print"\\nraisecmd2 @_"} , -justify , left , -label , \'Browse view\' , -createcmd , sub{print"\\ncreatecmd2 @_"} , -state , normal'
  }, 'ctkDescriptor' ),
  'w_Label_006' => bless( {
    'parent' => 'w_Frame_005',
    'geom' => 'pack(-side=>left, -anchor=>nw, -fill=>x, -expand=>1)',
    'order' => undef,
    'id' => 'w_Label_006',
    'type' => 'Label',
    'opt' => '-relief , flat , -background , #c0c0c0 , -width , 32 , -justify , left , -text , subroutine'
  }, 'ctkDescriptor' ),
  'wr_020' => bless( {
    'parent' => 'wr_018',
    'geom' => 'grid(-row=>1, -column=>0, -sticky=>nw)',
    'order' => undef,
    'id' => 'wr_020',
    'type' => 'Checkbutton',
    'opt' => '-state , normal , -justify , left , -relief , flat , -text , Option___2 , -variable , \\$option2 , -onvalue , 2'
  }, 'ctkDescriptor' ),
  'w_ScrolledListbox_014' => bless( {
    'parent' => 'w_NoteBookFrame_004',
    'geom' => 'pack(-anchor=>nw, -side=>top, -fill=>both, -expand=>1, -padx=>5)',
    'order' => '$w_ScrolledListbox_014->insert(\'end\',@records);',
    'id' => 'w_ScrolledListbox_014',
    'type' => 'ScrolledListbox',
    'opt' => 'Listbox , -background , #ffffff , -borderwidth , 1 , -selectmode , single , -relief , sunken , -scrollbars , se'
  }, 'ctkDescriptor' ),
  'wr_024' => bless( {
    'parent' => 'wr_018',
    'geom' => 'grid(-row=>2, -column=>1, -sticky=>ne)',
    'order' => undef,
    'id' => 'wr_024',
    'type' => 'LabEntry',
    'opt' => '-background , #ffffff , -justify , left , -label , Size___3 , -relief , sunken , -labelPack , [-side , left , -anchor , n ] , -textvariable , \\$option6 , -width , 6 , -state , normal'
  }, 'ctkDescriptor' ),
  'w_Frame_009' => bless( {
    'parent' => 'w_NoteBookFrame_003',
    'geom' => 'pack(-side=>top, -anchor=>nw, -pady=>5, -padx=>5)',
    'order' => undef,
    'id' => 'w_Frame_009',
    'type' => 'Frame',
    'opt' => '-relief , flat'
  }, 'ctkDescriptor' )
};
$rTree = [
  'mw',
  'mw.w_Frame_001',
  'mw.w_Frame_001.w_NoteBook_002',
  'mw.w_Frame_001.w_Frame_015',
  'mw.w_Frame_001.w_Frame_017',
  'mw.w_Frame_001.w_NoteBook_002.w_NoteBookFrame_003',
  'mw.w_Frame_001.w_NoteBook_002.w_NoteBookFrame_004',
  'mw.w_Frame_001.w_NoteBook_002.wr_NoteBookFrame_005',
  'mw.w_Frame_001.w_Frame_015.w_Button_018',
  'mw.w_Frame_001.w_Frame_015.w_Button_019',
  'mw.w_Frame_001.w_Frame_017.w_Label_020',
  'mw.w_Frame_001.w_NoteBook_002.wr_NoteBookFrame_005.wr_018',
  'mw.w_Frame_001.w_NoteBook_002.w_NoteBookFrame_003.w_Frame_005',
  'mw.w_Frame_001.w_NoteBook_002.w_NoteBookFrame_003.w_Frame_009',
  'mw.w_Frame_001.w_NoteBook_002.w_NoteBookFrame_004.w_ScrolledListbox_014',
  'mw.w_Frame_001.w_NoteBook_002.wr_NoteBookFrame_005.wr_018.wr_019',
  'mw.w_Frame_001.w_NoteBook_002.wr_NoteBookFrame_005.wr_018.wr_020',
  'mw.w_Frame_001.w_NoteBook_002.wr_NoteBookFrame_005.wr_018.wr_021',
  'mw.w_Frame_001.w_NoteBook_002.wr_NoteBookFrame_005.wr_018.wr_022',
  'mw.w_Frame_001.w_NoteBook_002.wr_NoteBookFrame_005.wr_018.wr_023',
  'mw.w_Frame_001.w_NoteBook_002.wr_NoteBookFrame_005.wr_018.wr_024',
  'mw.w_Frame_001.w_NoteBook_002.w_NoteBookFrame_003.w_Frame_005.w_Label_006',
  'mw.w_Frame_001.w_NoteBook_002.w_NoteBookFrame_003.w_Frame_005.w_Entry_007',
  'mw.w_Frame_001.w_NoteBook_002.w_NoteBookFrame_003.w_Frame_009.w_Label_010',
  'mw.w_Frame_001.w_NoteBook_002.w_NoteBookFrame_003.w_Frame_009.w_Entry_011'
];
$rUser_subroutines = [
  'sub init {',
  '	$option1 = 1;',
  '	$option2 = 0;',
  '	$option3 = 0;',
  '	$option4 = 512;',
  '	$option5 = 1024;',
  '	$option6 = 4096;',
  '	$sub = \'_testInit\';',
  '	$subclasse = \'thisTest\';',
  '	@records=(qw/testInit testError testUseCase_1 testUseCase_2 testRecovery_1 testDie_0/);',
  '}',
  'sub do_exit_1 {',
  '	print "\\noption___1 = $option1";',
  '	print "\\noption___2 = $option2";',
  '	print "\\noption___3 = $option3";',
  '	print "\\nsize___1 = $option4";',
  '	print "\\nsize___2 = $option5";',
  '	print "\\nsize___3 = $option6";',
  '	print "\\n";',
  '	print "\\nsub = $sub";',
  '	print "\\n";',
  '	print "\\nsubclasse = $subclasse";',
  '	print "\\n";',
  '	exit 1',
  '}',
  'sub do_exit_0 {',
  '	print "\\ncancelled";',
  '	exit 0',
  '}'
];
$rUser_methods_code = [];
$rUser_gcode = [];
$rOther_code = [];
$rUser_pod = [];
$rUser_auto_vars = [
  '$option1',
  '$option2',
  '$option3',
  '$option4',
  '$option5',
  '$option6',
  '$sub',
  '$subclasse',
  '@records'
];
$rUser_local_vars = [];
$rFile_opt = {
  'strict' => '0',
  'subroutineArgs' => '-title , \'Test Notebook\' ',
  'Toplevel' => '1',
  'modal' => '0',
  'subroutineArgsName' => '%args',
  'autoExtractVariables' => '1',
  'subroutineName' => 'dlgNotebook',
  'title' => '',
  'subWidgetList' => [],
  'modalDialogClassName' => 'DialogBox',
  'description' => '',
  'autoExtract2Local' => '1',
  'code' => '0',
  'onDeleteWindow' => 'sub{1}',
  'baseClass' => ''
};
$rProjectName = \'noteBook1.pl';
$ropt_isolate_geom = \'0';
$rHiddenWidgets = [];
$rLibraries = [];
$rApplName = \'';
$rApplFolder = \'';
$opt_TestCode = \'1';
$rBaseClass = [];
