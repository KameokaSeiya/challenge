import adsk.core
from ..Commands import PackageCommand
from ..Utilities import addin_utility, fusion_ui, constant
from ..Utilities.localization import _LCLZ

  
class PackageCommandEcap(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_ecap'
        self.cmd_name = _LCLZ('CmdNameEcap', 'E-Cap Generator')
        self.cmd_description = _LCLZ('CmdDescEcap', 'Generate E-Cap Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 300
        self.dialog_height = 710 

    def get_defalt_ui_data(self):
        ui_data = {}
        ui_data['cmd_id'] = self.cmd_id
        ui_data['type'] = constant.PKG_TYPE_ECAP
        ui_data['horizontalPadCount'] = 2
        ui_data['padShape'] = constant.SMD_PAD_SHAPE.get('Rectangle')
        ui_data['roundedPadCornerSize'] = 40
        ui_data['densityLevel'] = constant.DENSITY_LEVEL_SMD['Nominal (N)']

        ui_data['optionalDimension'] = constant.DIMENSION_OPTIONS_LEAD_SPAN
        ui_data['padWidthMax'] = 0.37
        ui_data['padWidthMin'] = 0.33
        ui_data['terminalGapMax'] = 0.48
        ui_data['terminalGapMin'] = 0.42
        ui_data['horizontalLeadToLeadSpanMax'] = 1.22
        ui_data['horizontalLeadToLeadSpanMin'] = 1.08

        ui_data['padHeightMax'] = 0.11
        ui_data['padHeightMin'] = 0.07
        ui_data['bodyWidthMax'] = 1.05
        ui_data['bodyWidthMin'] = 1.01
        ui_data['bodyLengthMax'] = 1.05
        ui_data['bodyLengthMin'] = 1.01
        ui_data['bodyHeightMax'] = 1.05
       
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY.get('MappingTypeToBodyMax')
        ui_data['fabricationTolerance'] = 0.005
        ui_data['placementTolerance'] = 0.003
        # custom footprint parameters
        ui_data['hasCustomFootprint'] = False
        ui_data['customPadLength'] = 0.442
        ui_data['customPadWidth'] = 0.212
        ui_data['customPadToPadGap'] = 0.429
        return ui_data

    def update_ui_data(self, inputs):
        
        input_data = self.get_inputs()
        for param in self.ui_data:
            if param in input_data:
                self.ui_data[param] = input_data[param]
        
        # update the density level
        self.ui_data['densityLevel'] = list(constant.DENSITY_LEVEL_SMD.values())[inputs.itemById('densityLevel').selectedItem.index]
        self.ui_data['silkscreenMappingTypeToBody'] = list(constant.SILKSCREEN_MAPPING_TO_BODY.values())[inputs.itemById('silkscreenMappingTypeToBody').selectedItem.index]
        self.ui_data['padShape'] = list(constant.SMD_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index]
        self.ui_data['optionalDimension'] = list(constant.DIMENSION_OPTIONS.values())[inputs.itemById('optionalDimension').selectedItem.index]      
        self.ui_data['bodyLengthMax'] = self.ui_data['bodyWidthMax']
        self.ui_data['bodyLengthMin'] = self.ui_data['bodyWidthMin']


    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects() 

        # Create a package tab input.
        tab1_cmd_inputs = inputs.addTabCommandInput('tab_1', _LCLZ('package', 'Package'))
        tab1_inputs = tab1_cmd_inputs.children

        # Create image input.
        labeled_image = tab1_inputs.addImageCommandInput('EcapImage', '', "Resources/img/E-Cap-Labeled.png")
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

        # Create dropdown input of pad shape.
        pad_shape = tab1_inputs.addDropDownCommandInput('padShape', _LCLZ('padShape', 'Pad Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        pad_shape_list = pad_shape.listItems
        pad_shape_list.add(_LCLZ('Rectangle', constant.SMD_PAD_SHAPE.get('Rectangle')), True if constant.SMD_PAD_SHAPE.get('Rectangle') == self.ui_data['padShape'] else False, "")        
        pad_shape_list.add(_LCLZ('RoundedRectangle', constant.SMD_PAD_SHAPE.get("RoundedRectangle")), True if constant.SMD_PAD_SHAPE.get("RoundedRectangle") == self.ui_data['padShape'] else False, "")
        pad_shape.isVisible = not self.only_3d_model_generator
        pad_shape.maxVisibleItems = 2

        # create round corner size input
        rounded_corner = tab1_inputs.addIntegerSpinnerCommandInput('roundedPadCornerSize', _LCLZ('padRoundness', 'Pad Roundness (%)'), 1, 100 , 1, int(self.ui_data['roundedPadCornerSize']))
        rounded_corner.isVisible = True if constant.SMD_PAD_SHAPE.get('RoundedRectangle') == self.ui_data['padShape'] else False

        # Create a read only textbox input.
        tab1_inputs.addTextBoxCommandInput('readonly_textBox', '', _LCLZ('ecapNote', '* Select optional dimension from (D, D2, L). Different combinations may produce different footprint pad sizes.'), 3, True)

        dimension_option = tab1_inputs.addDropDownCommandInput('optionalDimension', _LCLZ('optionalDimension', 'Optional Dimension'), adsk.core.DropDownStyles.TextListDropDownStyle)
        for t in constant.DIMENSION_OPTIONS:
            dimension_option.listItems.add(_LCLZ(t, constant.DIMENSION_OPTIONS.get(t)), True if constant.DIMENSION_OPTIONS.get(t) == self.ui_data['optionalDimension'] else False, '')
        dimension_option.maxVisibleItems = len(constant.DIMENSION_OPTIONS)
        
        # table
        table = tab1_inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.hasGrid = False
        table.tablePresentationStyle = 2
        table.maximumVisibleRows = 7
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))
        fusion_ui.add_row_to_table(table, 'horizontalLeadToLeadSpan', 'D', adsk.core.ValueInput.createByReal(self.ui_data['horizontalLeadToLeadSpanMin']), adsk.core.ValueInput.createByReal(self.ui_data['horizontalLeadToLeadSpanMax']),  _LCLZ('leadSpan', 'Lead Span'))
        table.getInputAtPosition(1,1).isEnabled = False if self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_LEAD_SPAN else True
        table.getInputAtPosition(1,2).isEnabled = False if self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_LEAD_SPAN else True        
        fusion_ui.add_row_to_table(table, 'terminalGap', 'D2', adsk.core.ValueInput.createByReal(self.ui_data['terminalGapMin']), adsk.core.ValueInput.createByReal(self.ui_data['terminalGapMax']), _LCLZ('terminalGap', 'Terminal Gap'))
        table.getInputAtPosition(2,1).isEnabled = False if self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_TERMINAL_GAP else True
        table.getInputAtPosition(2,2).isEnabled = False if self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_TERMINAL_GAP else True   
        fusion_ui.add_row_to_table(table, 'padWidth', 'L', adsk.core.ValueInput.createByReal(self.ui_data['padWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['padWidthMax']), _LCLZ('terminalLength', 'Terminal Length'))
        table.getInputAtPosition(3,1).isEnabled = False if self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_TERMINAL_LEN else True
        table.getInputAtPosition(3,2).isEnabled = False if self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_TERMINAL_LEN else True 
        fusion_ui.add_row_to_table(table, 'padHeight', 'b', adsk.core.ValueInput.createByReal(self.ui_data['padHeightMin']), adsk.core.ValueInput.createByReal(self.ui_data['padHeightMax']), _LCLZ('terminalWidth', 'Terminal Width'))
        fusion_ui.add_row_to_table(table, 'bodyWidth', 'D1', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyLength', 'Body Length'))
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
        custom_footprint_image = custom_footprint_inputs.addImageCommandInput('customECAPImage', '', "Resources/img/SOD-Custom-Footprint.png")
        custom_footprint_image.isFullWidth = True
        custom_footprint_image.isVisible = True
        custom_pad_length = custom_footprint_inputs.addValueInput('customPadLength', 'l',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadLength']))
        custom_pad_length.isEnabled = True if enable_custom_footprint.value else False
        custom_pad_length.tooltip = _LCLZ("customPadLength", 'Custom Pad Length')
        custom_pad_width = custom_footprint_inputs.addValueInput('customPadWidth', 'c',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadWidth']))
        custom_pad_width.isEnabled = True if enable_custom_footprint.value else False
        custom_pad_width.tooltip = _LCLZ('customPadWidth', 'Custom Pad Width')
        custom_pad_gap = custom_footprint_inputs.addValueInput('customPadToPadGap', 'g',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadToPadGap']))
        custom_pad_gap.isEnabled = True if enable_custom_footprint.value else False
        custom_pad_gap.tooltip = _LCLZ('customPadGap', 'Custom Pad To Pad Gap')

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
        # call the base class function.
        super().on_input_changed(command, inputs, changed_input, input_values)
        
        if changed_input.id == 'optionalDimension':
            optional_dimension = list(constant.DIMENSION_OPTIONS.values())[inputs.itemById('optionalDimension').selectedItem.index]
            if optional_dimension == constant.DIMENSION_OPTIONS_LEAD_SPAN:
                inputs.itemById('horizontalLeadToLeadSpanMax').isEnabled = False
                inputs.itemById('horizontalLeadToLeadSpanMin').isEnabled = False
                inputs.itemById('terminalGapMax').isEnabled = True
                inputs.itemById('terminalGapMin').isEnabled = True
                inputs.itemById('padWidthMax').isEnabled = True
                inputs.itemById('padWidthMin').isEnabled = True
            elif optional_dimension == constant.DIMENSION_OPTIONS_TERMINAL_GAP:
                inputs.itemById('horizontalLeadToLeadSpanMax').isEnabled = True
                inputs.itemById('horizontalLeadToLeadSpanMin').isEnabled = True
                inputs.itemById('terminalGapMax').isEnabled = False
                inputs.itemById('terminalGapMin').isEnabled = False
                inputs.itemById('padWidthMax').isEnabled = True
                inputs.itemById('padWidthMin').isEnabled = True
            elif optional_dimension == constant.DIMENSION_OPTIONS_TERMINAL_LEN:
                inputs.itemById('horizontalLeadToLeadSpanMax').isEnabled = True
                inputs.itemById('horizontalLeadToLeadSpanMin').isEnabled = True
                inputs.itemById('terminalGapMax').isEnabled = True
                inputs.itemById('terminalGapMin').isEnabled = True
                inputs.itemById('padWidthMax').isEnabled = False
                inputs.itemById('padWidthMin').isEnabled = False

        # update the optional dimension 
        if changed_input.id == 'padWidthMax' or changed_input.id == 'padWidthMin' :
            optional_dimension = list(constant.DIMENSION_OPTIONS.values())[inputs.itemById('optionalDimension').selectedItem.index]
            if optional_dimension == constant.DIMENSION_OPTIONS_LEAD_SPAN:
                inputs.itemById('horizontalLeadToLeadSpanMax').value = inputs.itemById('padWidthMax').value *2 + inputs.itemById('terminalGapMax').value
                inputs.itemById('horizontalLeadToLeadSpanMin').value = inputs.itemById('padWidthMin').value *2 + inputs.itemById('terminalGapMin').value
            else:
                inputs.itemById('terminalGapMax').value = inputs.itemById('horizontalLeadToLeadSpanMax').value - inputs.itemById('padWidthMax').value *2
                inputs.itemById('terminalGapMin').value = inputs.itemById('horizontalLeadToLeadSpanMin').value - inputs.itemById('padWidthMin').value *2
        
        if changed_input.id == 'terminalGapMax' or changed_input.id == 'terminalGapMin' : 
            optional_dimension = list(constant.DIMENSION_OPTIONS.values())[inputs.itemById('optionalDimension').selectedItem.index]
            if optional_dimension == constant.DIMENSION_OPTIONS_LEAD_SPAN:
                inputs.itemById('horizontalLeadToLeadSpanMax').value = inputs.itemById('padWidthMax').value *2 + inputs.itemById('terminalGapMax').value
                inputs.itemById('horizontalLeadToLeadSpanMin').value = inputs.itemById('padWidthMin').value *2 + inputs.itemById('terminalGapMin').value
            else:
                inputs.itemById('padWidthMax').value = (inputs.itemById('horizontalLeadToLeadSpanMax').value - inputs.itemById('terminalGapMax').value)/2
                inputs.itemById('padWidthMin').value = (inputs.itemById('horizontalLeadToLeadSpanMin').value - inputs.itemById('terminalGapMin').value)/2
        
        if changed_input.id == 'horizontalLeadToLeadSpanMax' or changed_input.id == 'horizontalLeadToLeadSpanMin' : 
            optional_dimension = list(constant.DIMENSION_OPTIONS.values())[inputs.itemById('optionalDimension').selectedItem.index]
            if optional_dimension == constant.DIMENSION_OPTIONS_TERMINAL_LEN:
                inputs.itemById('padWidthMax').value = (inputs.itemById('horizontalLeadToLeadSpanMax').value - inputs.itemById('terminalGapMax').value)/2
                inputs.itemById('padWidthMin').value = (inputs.itemById('horizontalLeadToLeadSpanMin').value - inputs.itemById('terminalGapMin').value)/2
            else:
                inputs.itemById('terminalGapMax').value = inputs.itemById('horizontalLeadToLeadSpanMax').value - inputs.itemById('padWidthMax').value *2
                inputs.itemById('terminalGapMin').value = inputs.itemById('horizontalLeadToLeadSpanMin').value - inputs.itemById('padWidthMin').value *2


        if changed_input.id == 'padShape':
            pad_shape = list(constant.SMD_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index]
            if pad_shape == constant.SMD_PAD_SHAPE.get("RoundedRectangle"):
                inputs.itemById('roundedPadCornerSize').isVisible = True
            else:
                inputs.itemById('roundedPadCornerSize').isVisible = False

        if changed_input.id == 'hasCustomFootprint':
            inputs.itemById('customPadLength').isEnabled = changed_input.value
            inputs.itemById('customPadWidth').isEnabled = changed_input.value
            inputs.itemById('customPadToPadGap').isEnabled = changed_input.value
            inputs.itemById('tab_3').isVisible = not changed_input.value
            
# register the command into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_ECAP, PackageCommandEcap)