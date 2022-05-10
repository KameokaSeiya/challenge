import adsk.core
from . import PackageCommand
from ..Utilities import addin_utility, fusion_ui, constant
from ..Utilities.localization import _LCLZ



CHIP_ARRAY_4SIDE_FLAT_FAMILY_TYPES = {
    'DIODE': constant.COMP_FAMILY_DIODE,
    'INDUCTOR': constant.COMP_FAMILY_INDUCTOR,
    'NONPOLARIZED_CAPACITOR': constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR,
    'RESISTOR': constant.COMP_FAMILY_RESISTOR
}

PIN_NUM_OPTIONS = [4,6,8,10,12,14,16]

LEAD_SHAPE_TYPE = {
    'Concave' : 'Concave',
    'Flat'    : 'Flat'
    }
        
class PackageCommandChipArray4SideFlatConcave(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_chiparray_4side_flat'
        self.cmd_name = _LCLZ('CmdNameChipArray4SideFlatConcave', 'Chip Array, 4 Side Flat/Concave Generator')
        self.cmd_description = _LCLZ('CmdDescChipArray4SideFlatConcave', 'Generate Chip Array, 4 Side Flat/Concave Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 310
        self.dialog_height = 770 

    def get_defalt_ui_data(self):
        #default parameters
        ui_data = {}
        ui_data['type'] = constant.PKG_TYPE_CHIPARRAY4SIDEFLAT
        ui_data['cmd_id'] = self.cmd_id
        ui_data['componentFamily'] = CHIP_ARRAY_4SIDE_FLAT_FAMILY_TYPES['RESISTOR']
        ui_data['horizontalPadCount'] = PIN_NUM_OPTIONS[3]
        ui_data['leadShapeType'] = LEAD_SHAPE_TYPE.get('Concave')
        ui_data['padShape'] = constant.SMD_PAD_SHAPE.get('Rectangle')
        ui_data['roundedPadCornerSize'] = 40
        ui_data['densityLevel'] = constant.DENSITY_LEVEL_SMD['Nominal (N)']
       
        ui_data['verticalPinPitch'] = 0.08
        ui_data['padWidthMax'] = 0.05
        ui_data['padWidthMin'] = 0.03
        ui_data['oddPadWidthMax'] = 0.045
        ui_data['oddPadWidthMin'] = 0.025
        ui_data['padHeightMax'] = 0.055
        ui_data['padHeightMin'] = 0.025
        ui_data['oddPadHeightMax'] = 0.065
        ui_data['oddPadHeightMin'] = 0.035
        ui_data['bodyLengthMax'] = 0.42
        ui_data['bodyLengthMin'] = 0.38
        ui_data['bodyWidthMax'] = 0.23
        ui_data['bodyWidthMin'] = 0.19
        ui_data['bodyHeightMax'] = 0.07
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY.get('MappingTypeToBodyMax')
        ui_data['fabricationTolerance'] = 0.005
        ui_data['placementTolerance'] = 0.003

        ui_data['hasCustomFootprint'] = False
        ui_data['customPadLength'] = 0.102
        ui_data['customPadWidth'] = 0.043
        ui_data['customPadToPadGap'] = 0.118
        ui_data['customPadToPadGap1'] = 0.318
        ui_data['customOddPadLength'] = 0.097
        ui_data['customOddPadWidth'] = 0.053
        return ui_data

    def update_ui_data(self, inputs):

        # update date from UI inputs
        input_data = self.get_inputs()
        for param in self.ui_data:
            if param in input_data:
                self.ui_data[param] = input_data[param]
        
        # update the density level
        self.ui_data['densityLevel'] = list(constant.DENSITY_LEVEL_SMD.values())[inputs.itemById('densityLevel').selectedItem.index]
        self.ui_data['silkscreenMappingTypeToBody'] = list(constant.SILKSCREEN_MAPPING_TO_BODY.values())[inputs.itemById('silkscreenMappingTypeToBody').selectedItem.index]
        self.ui_data['padShape'] = list(constant.SMD_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index]
        self.ui_data['leadShapeType'] = list(LEAD_SHAPE_TYPE.values())[inputs.itemById('leadShapeType').selectedItem.index]
        self.ui_data['componentFamily'] = list(CHIP_ARRAY_4SIDE_FLAT_FAMILY_TYPES.values())[inputs.itemById('componentFamily').selectedItem.index]
        # update the pin num. convert from str to int
        self.ui_data['horizontalPadCount'] = int(input_data['horizontalPadCount'])
    
    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects()

        # Create a package tab input.
        tab1_cmd_inputs = inputs.addTabCommandInput('tab_1', _LCLZ('package', 'Package'))
        tab1_inputs = tab1_cmd_inputs.children
        
        # Create image input.
        labeled_image = tab1_inputs.addImageCommandInput('ChipArray4SideFlatImage', '', 'Resources/img/ChipArray-4side-FlatConcave-Labeled.png')
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

        # Create dropdown input with  list style.
        component_family = tab1_inputs.addDropDownCommandInput('componentFamily', _LCLZ('componentFamily', 'Component Family'), adsk.core.DropDownStyles.TextListDropDownStyle)
        component_family_list = component_family.listItems
        for t in CHIP_ARRAY_4SIDE_FLAT_FAMILY_TYPES:
            component_family_list.add(_LCLZ(t, CHIP_ARRAY_4SIDE_FLAT_FAMILY_TYPES.get(t)), True if CHIP_ARRAY_4SIDE_FLAT_FAMILY_TYPES.get(t) == self.ui_data['componentFamily'] else False, '')
        component_family.maxVisibleItems = len(CHIP_ARRAY_4SIDE_FLAT_FAMILY_TYPES)

        pin_num = tab1_inputs.addDropDownCommandInput('horizontalPadCount', _LCLZ('#Pins', '# Pins'), adsk.core.DropDownStyles.TextListDropDownStyle)
        for n in PIN_NUM_OPTIONS:
            pin_num.listItems.add(str(n), True if n == self.ui_data['horizontalPadCount'] else False, '')
        pin_num.maxVisibleItems = len(PIN_NUM_OPTIONS)

        # Create lead shape dropdown input 
        lead_shape = tab1_inputs.addDropDownCommandInput('leadShapeType', _LCLZ('leadShape', 'Lead Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        lead_shape.listItems.add(_LCLZ('Concave', LEAD_SHAPE_TYPE.get('Concave')), True if LEAD_SHAPE_TYPE.get('Concave') == self.ui_data['leadShapeType'] else False, '')        
        lead_shape.listItems.add(_LCLZ('Flat', LEAD_SHAPE_TYPE.get('Flat')), True if LEAD_SHAPE_TYPE.get('Flat') == self.ui_data['leadShapeType'] else False, '')
        lead_shape.maxVisibleItems = 2

        # Create dropdown input with test list style.
        pad_shape = tab1_inputs.addDropDownCommandInput('padShape', _LCLZ('padShape', 'Pad Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        pad_shape_list = pad_shape.listItems
        pad_shape_list.add(_LCLZ('Rectangle', constant.SMD_PAD_SHAPE.get('Rectangle')), True if constant.SMD_PAD_SHAPE.get('Rectangle') == self.ui_data['padShape'] else False, "")        
        pad_shape_list.add(_LCLZ('RoundedRectangle', constant.SMD_PAD_SHAPE.get("RoundedRectangle")), True if constant.SMD_PAD_SHAPE.get("RoundedRectangle") == self.ui_data['padShape'] else False, "")
        pad_shape.isVisible = not self.only_3d_model_generator
        pad_shape.maxVisibleItems = 2

        # create round corner size input
        rounded_corner = tab1_inputs.addIntegerSpinnerCommandInput('roundedPadCornerSize', _LCLZ('padRoundness', 'Pad Roundness (%)'), 1, 100 , 1, int(self.ui_data['roundedPadCornerSize']))
        rounded_corner.isVisible = True if constant.SMD_PAD_SHAPE.get('RoundedRectangle') == self.ui_data['padShape'] else False

        pin_pitch = tab1_inputs.addValueInput('verticalPinPitch', 'e', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['verticalPinPitch']))
        pin_pitch.tooltip = _LCLZ('pinPitch', 'Pin Pitch')
        
        # table
        table = tab1_inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.hasGrid = False
        table.tablePresentationStyle = 2
        table.maximumVisibleRows = 8
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))
        fusion_ui.add_row_to_table(table, 'padWidth', 'L', adsk.core.ValueInput.createByReal(self.ui_data['padWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['padWidthMax']), _LCLZ('terminalLength', 'Terminal Length'))
        fusion_ui.add_row_to_table(table, 'oddPadWidth', 'L1', adsk.core.ValueInput.createByReal(self.ui_data['oddPadWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['oddPadWidthMax']), _LCLZ('oddTerminalLength', 'Odd Terminal Length'))
        fusion_ui.add_row_to_table(table, 'padHeight', 'b', adsk.core.ValueInput.createByReal(self.ui_data['padHeightMin']), adsk.core.ValueInput.createByReal(self.ui_data['padHeightMax']),  _LCLZ('terminalWidth', 'Terminal Width'))
        fusion_ui.add_row_to_table(table, 'oddPadHeight', 'b1', adsk.core.ValueInput.createByReal(self.ui_data['oddPadHeightMin']), adsk.core.ValueInput.createByReal(self.ui_data['oddPadHeightMax']), _LCLZ('oddTerminalWidth', 'Odd Terminal Width'))
        fusion_ui.add_row_to_table(table, 'bodyWidth', 'E', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyWidth', 'Body Width'))
        fusion_ui.add_row_to_table(table, 'bodyLength', 'D', adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMax']), _LCLZ('bodyLength', 'Body Length'))
        fusion_ui.add_row_to_table(table, 'bodyHeight', 'A', None, adsk.core.ValueInput.createByReal(self.ui_data['bodyHeightMax']), _LCLZ('bodyHeight', 'Body Height'))

        # Create dropdown input with test list style.
        map_silkscreen = tab1_inputs.addDropDownCommandInput('silkscreenMappingTypeToBody', _LCLZ('mapSilkscreen', 'Map Silkscreen to Body'), adsk.core.DropDownStyles.TextListDropDownStyle)
        map_silkscreen_list = map_silkscreen.listItems
        for t in constant.SILKSCREEN_MAPPING_TO_BODY:
            map_silkscreen_list.add(_LCLZ(t, constant.SILKSCREEN_MAPPING_TO_BODY.get(t)), True if constant.SILKSCREEN_MAPPING_TO_BODY.get(t) == self.ui_data['silkscreenMappingTypeToBody'] else False, '')
        map_silkscreen.isVisible = not self.only_3d_model_generator
        map_silkscreen.maxVisibleItems = len(constant.SILKSCREEN_MAPPING_TO_BODY)

        # Create a custom footprint tab input.
        tab2_cmd_inputs = inputs.addTabCommandInput('tab_2', _LCLZ('footprint', 'Footprint'))
        custom_footprint_inputs = tab2_cmd_inputs.children
        tab2_cmd_inputs.isVisible = not self.only_3d_model_generator

        # Create image input.
        enable_custom_footprint = custom_footprint_inputs.addBoolValueInput('hasCustomFootprint', _LCLZ('hasCustomFootprint', 'Custom Footprint'), True, '', self.ui_data['hasCustomFootprint'])
        custom_footprint_image = custom_footprint_inputs.addImageCommandInput('customChipArray4SideFlatImage', '', 'Resources/img/ChipArray4SideFlat-Custom-Footprint.png')
        custom_footprint_image.isFullWidth = True
        custom_footprint_image.isVisible = True
        custom_pad_length = custom_footprint_inputs.addValueInput('customPadLength', 'l',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadLength']))
        custom_pad_length.isEnabled = True if enable_custom_footprint.value else False
        custom_pad_length.tooltip = _LCLZ("customPadLength", 'Custom Pad Length')
        custom_pad_width = custom_footprint_inputs.addValueInput('customPadWidth', 'c',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadWidth']))
        custom_pad_width.isEnabled = True if enable_custom_footprint.value else False
        custom_pad_width.tooltip = _LCLZ('customPadWidth', 'Custom Pad Width')
        custom_odd_pad_length = custom_footprint_inputs.addValueInput('customOddPadLength', 'l1',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customOddPadLength']))
        custom_odd_pad_length.isEnabled = True if enable_custom_footprint.value else False
        custom_odd_pad_length.tooltip = _LCLZ('customOddPadLength', 'Custom Odd Pad Length')
        custom_odd_pad_width = custom_footprint_inputs.addValueInput('customOddPadWidth', 'c1',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customOddPadWidth']))
        custom_odd_pad_width.isEnabled = True if enable_custom_footprint.value else False
        custom_odd_pad_width.tooltip = _LCLZ('customOddPadWidth', 'Custom Odd Pad Width')
        custom_pad_gap = custom_footprint_inputs.addValueInput('customPadToPadGap', 'g',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadToPadGap']))
        custom_pad_gap.isEnabled = True if enable_custom_footprint.value else False
        custom_pad_gap.tooltip = _LCLZ('customPadGap', 'Custom Pad To Pad Gap')
        custom_pad_gap1 = custom_footprint_inputs.addValueInput('customPadToPadGap1', 'g1',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadToPadGap1']))
        custom_pad_gap1.isEnabled = True if enable_custom_footprint.value else False
        custom_pad_gap1.tooltip = _LCLZ('customPadGap1', 'Custom Pad To Pad Gap 1')


        #to reflect the model param e
        pin_pitch = custom_footprint_inputs.addValueInput('pinPitch', 'e',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['verticalPinPitch']))
        pin_pitch.isEnabled = False
        pin_pitch.tooltip = _LCLZ('pinPitchNote', 'Read-only, edit in the package tab')

        #create the tab of Manufacturing settings.
        tab3_cmd_inputs = inputs.addTabCommandInput('tab_3', _LCLZ('Manufacturing', 'Manufacturing'))
        manufacturing_inputs = tab3_cmd_inputs.children
        tab3_cmd_inputs.isVisible = not self.only_3d_model_generator

        # Create dropdown input for density level
        density_level = manufacturing_inputs.addDropDownCommandInput('densityLevel', _LCLZ('densityLevel', 'Density Level'), adsk.core.DropDownStyles.TextListDropDownStyle)
        density_level_list = density_level.listItems
        for t in constant.DENSITY_LEVEL_SMD:
            density_level_list.add(_LCLZ(t, t), True if constant.DENSITY_LEVEL_SMD.get(t) == self.ui_data['densityLevel'] else False, '')
        density_level.maxVisibleItems = len(constant.DENSITY_LEVEL_SMD)

        # fabrication Tolerance 
        manufacturing_inputs.addValueInput('fabricationTolerance', _LCLZ('fabricationTolerance', 'Fabrication Tolerance'),  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['fabricationTolerance']))
        # placement Tolerance
        manufacturing_inputs.addValueInput('placementTolerance', _LCLZ('placementTolerance', 'PlacementTolerance'),  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['placementTolerance']))
        #Update when using the custom footprint mode
        if self.ui_data['hasCustomFootprint'] : 
            tab3_cmd_inputs.isVisible = False

    def on_input_changed(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs, changed_input: adsk.core.CommandInput, input_values: dict ):

        if changed_input.id == 'hasCustomFootprint':
            inputs.itemById('customPadLength').isEnabled = changed_input.value
            inputs.itemById('customPadWidth').isEnabled = changed_input.value
            inputs.itemById('customOddPadLength').isEnabled = changed_input.value
            inputs.itemById('customOddPadWidth').isEnabled = changed_input.value
            inputs.itemById('customPadToPadGap').isEnabled = changed_input.value
            inputs.itemById('customPadToPadGap1').isEnabled = changed_input.value
            inputs.itemById('tab_3').isVisible = not changed_input.value

        if changed_input.id == 'padShape':
            if list(constant.SMD_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index] == constant.SMD_PAD_SHAPE.get("RoundedRectangle"):
                inputs.itemById('roundedPadCornerSize').isVisible = True
            else:
                inputs.itemById('roundedPadCornerSize').isVisible = False    
            
        if changed_input.id == 'leadShapeType':
            #set regenrate model for non parametric updates.
            lead_shape = list(LEAD_SHAPE_TYPE.values())[inputs.itemById('leadShapeType').selectedItem.index]
            self.reset_regenerate_flag('leadShapeType', lead_shape)
                             
        if not self.only_3d_model_generator:
            #update e value only when footprint tab visible
            if changed_input.id == 'verticalPinPitch' :
                inputs.itemById('pinPitch').value = inputs.itemById('verticalPinPitch').value  

# register the calculator into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_CHIPARRAY4SIDEFLAT, PackageCommandChipArray4SideFlatConcave) 
           