$rDescriptor = {
  'w_command_015' => bless( {
    'parent' => 'w_Menu_014',
    'geom' => '',
    'opt' => '-label, w_command_015',
    'id' => 'w_command_015',
    'type' => 'command'
  }, 'ctkDescriptor' ),
  'w_Frame_004' => bless( {
    'parent' => 'mw',
    'geom' => 'pack(-side,left,-fill,both,-expand,1,-anchor,nw)',
    'opt' => '-relief, flat, -background, #ffffff, -label, w_Frame_004',
    'id' => 'w_Frame_004',
    'type' => 'Frame'
  }, 'ctkDescriptor' ),
  'w_Frame_003' => bless( {
    'parent' => 'mw',
    'geom' => 'pack(-anchor=>ne, -expand=>1, -side=>right, -fill=>both)',
    'opt' => '-relief=>flat, -background=>#ffffff, -label=>w_Frame_003',
    'id' => 'w_Frame_003',
    'type' => 'Frame'
  }, 'ctkDescriptor' ),
  'w_Frame_001' => bless( {
    'parent' => 'mw',
    'geom' => 'pack(-anchor=>nw, -expand=>1, -side=>top, -fill=>x)',
    'opt' => '-relief=>flat, -background=>#ffffff, -label=>w_Frame_001',
    'id' => 'w_Frame_001',
    'type' => 'Frame'
  }, 'ctkDescriptor' ),
  'w_Menubutton_013' => bless( {
    'parent' => 'w_Frame_001',
    'geom' => 'pack(-side,right,-anchor,ne)',
    'opt' => '-relief, flat, -text, w_Menubutton_013, -justify, left, -state, normal',
    'id' => 'w_Menubutton_013',
    'type' => 'Menubutton'
  }, 'ctkDescriptor' ),
  'mw' => bless( {
    'parent' => undef,
    'geom' => undef,
    'order' => undef,
    'id' => 'mw',
    'type' => 'Frame',
    'opt' => undef
  }, 'ctkDescriptor' ),
  'w_ScrolledROText_008' => bless( {
    'parent' => 'w_Frame_003',
    'geom' => 'pack()',
    'opt' => '\'ROText\',-scrollbars, \'se\', -relief, \'sunken\'',
    'id' => 'w_ScrolledROText_008',
    'type' => 'ScrolledROText'
  }, 'ctkDescriptor' ),
  'w_Label_017' => bless( {
    'parent' => 'w_Frame_007',
    'geom' => 'pack(-side,right,-fill,x,-expand,1,-anchor,se)',
    'opt' => '-relief, \'ridge\', -text, \'Statusbar 2\', -justify, \'left\'',
    'id' => 'w_Label_017',
    'type' => 'Label'
  }, 'ctkDescriptor' ),
  'w_command_012' => bless( {
    'parent' => 'w_Menu_011',
    'geom' => '',
    'opt' => '-label, w_command_012',
    'id' => 'w_command_012',
    'type' => 'command'
  }, 'ctkDescriptor' ),
  'w_Menubutton_010' => bless( {
    'parent' => 'w_Frame_001',
    'geom' => 'pack(-side,left,-anchor,nw)',
    'opt' => '-relief, flat, -text, w_Menubutton_010, -justify, left, -state, normal',
    'id' => 'w_Menubutton_010',
    'type' => 'Menubutton'
  }, 'ctkDescriptor' ),
  'w_Frame_007' => bless( {
    'parent' => 'mw',
    'geom' => 'pack(-side,bottom,-fill,x,-expand,1,-anchor,sw)',
    'opt' => '-relief, \'raised\', -label, \'w_Frame_007\'',
    'id' => 'w_Frame_007',
    'type' => 'Frame'
  }, 'ctkDescriptor' ),
  'w_Menu_011' => bless( {
    'parent' => 'w_Menubutton_010',
    'geom' => '',
    'opt' => '',
    'id' => 'w_Menu_011',
    'type' => 'Menu'
  }, 'ctkDescriptor' ),
  'w_packAdjust_006' => bless( {
    'parent' => 'w_Frame_004',
    'geom' => '',
    'opt' => '-side, \'left\'',
    'id' => 'w_packAdjust_006',
    'type' => 'packAdjust'
  }, 'ctkDescriptor' ),
  'w_ScrolledListbox_009' => bless( {
    'parent' => 'w_Frame_004',
    'geom' => 'pack(-side,top,-fill,both,-expand,1,-anchor,nw)',
    'opt' => '\'Listbox\',-relief, \'flat\', -background, \'#ffffff\', -scrollbars, \'se\', -selectmode, \'single\'',
    'id' => 'w_ScrolledListbox_009',
    'type' => 'ScrolledListbox'
  }, 'ctkDescriptor' ),
  'w_Label_016' => bless( {
    'parent' => 'w_Frame_007',
    'geom' => 'pack(-side,left,-fill,x,-expand,1,-anchor,nw)',
    'opt' => '-relief, \'ridge\', -background, \'#ffffff\', -text, \'Statusbar 1\', -justify, \'left\'',
    'id' => 'w_Label_016',
    'type' => 'Label'
  }, 'ctkDescriptor' ),
  'w_Menu_014' => bless( {
    'parent' => 'w_Menubutton_013',
    'geom' => '',
    'opt' => '',
    'id' => 'w_Menu_014',
    'type' => 'Menu'
  }, 'ctkDescriptor' )
};
$rTree = [
  'mw',
  'mw.w_Frame_001',
  'mw.w_Frame_001.w_Menubutton_010',
  'mw.w_Frame_001.w_Menubutton_013',
  'mw.w_Frame_001.w_Menubutton_013.w_Menu_014',
  'mw.w_Frame_001.w_Menubutton_013.w_Menu_014.w_command_015',
  'mw.w_Frame_001.w_Menubutton_010.w_Menu_011',
  'mw.w_Frame_001.w_Menubutton_010.w_Menu_011.w_command_012',
  'mw.w_Frame_007',
  'mw.w_Frame_007.w_Label_016',
  'mw.w_Frame_007.w_Label_017',
  'mw.w_Frame_004',
  'mw.w_Frame_004.w_packAdjust_006',
  'mw.w_Frame_004.w_ScrolledListbox_009',
  'mw.w_Frame_003',
  'mw.w_Frame_003.w_ScrolledROText_008'
];
$rUser_subroutines = [];
$rUser_methods_code = [];
$rUser_gcode = [];
$rOther_code = [];
$rUser_pod = [];
$rUser_auto_vars = [];
$rUser_local_vars = [];
$rFile_opt = {
  'Toplevel' => 1,
  'pod' => '
=head2 Description

	...

=head2 Syntax

	....

=head2 Notes

	None.

=head2 Maintenance

	Version: 1.01
	Author:  marco
	History: 22.05.2005 first draft

=cut

',
  'strict' => 0,
  'title' => '',
  'description' => ' ',
  'code' => 1
};
$rProjectName = \undef;
$ropt_isolate_geom = \undef;
$rHiddenWidgets = [];
$rLibraries = [];
$rApplName = \'';
$rApplFolder = \'';
$opt_TestCode = \1;
