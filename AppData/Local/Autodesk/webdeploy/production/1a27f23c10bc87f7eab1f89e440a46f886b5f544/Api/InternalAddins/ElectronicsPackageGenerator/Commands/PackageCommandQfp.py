import adsk.core
from ..Commands import PackageCommand
from ..Utilities import addin_utility,fusion_ui, constant
from ..Utilities.localization import _LCLZ

class PackageCommandQfp(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_Qfp'
        self.cmd_name = _LCLZ('CmdNameQfp', 'QFP Generator')
        self.cmd_description = _LCLZ('CmdDescQfp', 'Generate QFP Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.ui_data['cmd_id'] = self.cmd_id
        self.dialog_width = 310
        self.dialog_height = 770

    def get_defalt_ui_data(self):
        ui_data = {}
        ui_data['cmd_id'] = self.cmd_id
        ui_data['type'] = constant.PKG_TYPE_QFP
        ui_data['horizontalPadCount'] = 16
        ui_data['verticalPadCount'] = 16
        ui_data['roundedPadCornerSize'] = 40
        ui_data['horizontalLeadToLeadSpanMin'] = 1.27
        ui_data['horizontalLeadToLeadSpanMax'] = 1.31
        ui_data['verticalLeadToLeadSpanMin'] = 1.27
        ui_data['verticalLeadToLeadSpanMax'] = 1.31
        ui_data['padWidthMin'] = 0.078
        ui_data['padWidthMax'] = 0.103
        ui_data['padHeightMin'] = 0.017
        ui_data['padHeightMax'] = 0.027
        ui_data['verticalPinPitch'] = 0.05
        ui_data['bodyWidthMin'] = 0.98
        ui_data['bodyWidthMax'] = 1.02
        ui_data['bodyLengthMin'] = 0.98
        ui_data['bodyLengthMax'] = 1.02
        ui_data['bodyHeightMin'] = 0
        ui_data['bodyHeightMax'] = 0.12
        ui_data['bodyOffsetMin'] = 0.005
        ui_data['bodyOffsetMax'] = 0.005
        ui_data['hasThermalPad'] = False
        ui_data['thermalPadLength'] = 0.7
        ui_data['thermalPadWidth'] = 0.7
        ui_data['thermalPadSolderPasteOverride'] = False
        ui_data['thermalPadSolderPasteStencilApertureGapX'] = 0.053
        ui_data['thermalPadSolderPasteStencilApertureGapY'] = 0.053
        ui_data['thermalPadSolderPasteStencilApertureLength'] = 0.271
        ui_data['thermalPadSolderPasteStencilApertureWidth'] = 0.271
        ui_data['thermalPadSolderPasteStencilRowCount'] = 2
        ui_data['thermalPadSolderPasteStencilColCount'] = 2
        ui_data['thermalPadSolderPasteAreaCoverage'] = 60
        ui_data['customPadLength'] = 0.1850
        ui_data['customPadWidth'] = 0.028
        ui_data['customPadSpan1'] = 1.382
        ui_data['customPadSpan2'] = 1.382
        ui_data['hasCustomFootprint'] = False
        ui_data['densityLevel'] = 1 # max 2, normal 1, min, 0
        ui_data['padShape'] = 'Rectangle'
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY.get('MappingTypeToBodyMax')
        ui_data['fabricationTolerance'] = 0.005
        ui_data['placementTolerance'] = 0.003
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
        if not self.only_3d_model_generator:
            self.ui_data['thermalPadSolderPasteOverride'] = inputs.itemById('thermalPadSolderPasteOverride').isEnabledCheckBoxChecked 
                   
    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects() 

        # Create a package tab input.
        package_tab_cmd_inputs = inputs.addTabCommandInput('qfpPackageTab', _LCLZ('package', 'Package'))
        qfp_inputs = package_tab_cmd_inputs.children

        # Create image input.
        labeled_image = qfp_inputs.addImageCommandInput('qfpImage', '', "Resources/img/QFP-Labeled.png")
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

        qfp_inputs.addIntegerSpinnerCommandInput('horizontalPadCount', _LCLZ('#DPins', '# Pins (D Side)'), 1 , 100 , 1, int(self.ui_data['horizontalPadCount']))
        qfp_inputs.addIntegerSpinnerCommandInput('verticalPadCount', _LCLZ('#EPins', '# Pins (E side)'), 1 , 100 , 1, int(self.ui_data['verticalPadCount']))

        # Create dropdown input with test list style.
        pad_shape = qfp_inputs.addDropDownCommandInput('padShape', _LCLZ('padShape', 'Pad Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        pad_shape_list = pad_shape.listItems
        for t in constant.SMD_PAD_SHAPE:
            pad_shape_list.add(_LCLZ(t, constant.SMD_PAD_SHAPE.get(t)), True if constant.SMD_PAD_SHAPE.get(t) == self.ui_data['padShape'] else False, '')
        pad_shape.isVisible = not self.only_3d_model_generator
        pad_shape.maxVisibleItems = len(constant.SMD_PAD_SHAPE)

        # create round corner size input
        rounded_corner = qfp_inputs.addIntegerSpinnerCommandInput('roundedPadCornerSize', _LCLZ('padRoundness', 'Pad Roundness (%)'), 1, 100 , 1, int(self.ui_data['roundedPadCornerSize']))
        rounded_corner.isVisible = True if constant.SMD_PAD_SHAPE.get('RoundedRectangle') == self.ui_data['padShape'] else False

        pin_pitch = qfp_inputs.addValueInput('verticalPinPitch', 'e', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['verticalPinPitch']))
        pin_pitch.tooltip = _LCLZ('pinPitch', 'Pin Pitch')

        # table
        table = qfp_inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.maximumVisibleRows = 9
        table.hasGrid = False
        table.tablePresentationStyle = 2
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))
        fusion_ui.add_row_to_table(table, 'verticalLeadToLeadSpan', 'D', adsk.core.ValueInput.createByReal(self.ui_data['verticalLeadToLeadSpanMin']), adsk.core.ValueInput.createByReal(self.ui_data['verticalLeadToLeadSpanMax']), _LCLZ('leadSpan1', 'Lead Span 1'))
        fusion_ui.add_row_to_table(table, 'horizontalLeadToLeadSpan', 'E', adsk.core.ValueInput.createByReal(self.ui_data['horizontalLeadToLeadSpanMin']), adsk.core.ValueInput.createByReal(self.ui_data['horizontalLeadToLeadSpanMax']), _LCLZ('leadSpan2', 'Lead Span 2'))
        fusion_ui.add_row_to_table(table, 'padWidth', 'L', adsk.core.ValueInput.createByReal(self.ui_data['padWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['padWidthMax']), _LCLZ('terminalLength', 'Terminal Length'))
        fusion_ui.add_row_to_table(table, 'padHeight', 'b', adsk.core.ValueInput.createByReal(self.ui_data['padHeightMin']), adsk.core.ValueInput.createByReal(self.ui_data['padHeightMax']), _LCLZ('terminalWidth', 'Terminal Width'))
        fusion_ui.add_row_to_table(table, 'bodyLength', 'D1', adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMax']), _LCLZ('bodyLength', 'Body Length'))
        fusion_ui.add_row_to_table(table, 'bodyWidth', 'E1', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyWidth', 'Body Width'))
        fusion_ui.add_row_to_table(table, 'bodyHeight', 'A', None, adsk.core.ValueInput.createByReal(self.ui_data['bodyHeightMax']), _LCLZ('bodyHeight', 'Body Height'))
        fusion_ui.add_row_to_table(table, 'bodyOffset', 'A1', adsk.core.ValueInput.createByReal(self.ui_data['bodyOffsetMin']), None, _LCLZ('bodyOffset', 'Body Offset'))

        # Create dropdown input with test list style.
        map_silkscreen = qfp_inputs.addDropDownCommandInput('silkscreenMappingTypeToBody', _LCLZ('mapSilkscreen', 'Map Silkscreen to Body'), adsk.core.DropDownStyles.TextListDropDownStyle)
        map_silkscreen_list = map_silkscreen.listItems
        for t in constant.SILKSCREEN_MAPPING_TO_BODY:
            map_silkscreen_list.add(_LCLZ(t, constant.SILKSCREEN_MAPPING_TO_BODY.get(t)), True if constant.SILKSCREEN_MAPPING_TO_BODY.get(t) == self.ui_data['silkscreenMappingTypeToBody'] else False, '')
        map_silkscreen.isVisible = not self.only_3d_model_generator
        map_silkscreen.maxVisibleItems = len(constant.SILKSCREEN_MAPPING_TO_BODY)

        if not self.only_3d_model_generator:
            # Create a custom footprint tab input.
            footprint_tab_cmd_inputs = inputs.addTabCommandInput('qfpFootprintTab', _LCLZ('footprint', 'Footprint'))
            custom_footprint_inputs = footprint_tab_cmd_inputs.children
            enable_custom_footprint = custom_footprint_inputs.addBoolValueInput('hasCustomFootprint', _LCLZ('customFootprint', 'Custom Footprint'), True, '', self.ui_data['hasCustomFootprint'])

            # Create image input.
            custom_footprint_image = custom_footprint_inputs.addImageCommandInput('customQfpImage', '', "Resources/img/QFN-QFP-Custom-Footprint.png")
            custom_footprint_image.isFullWidth = True
            custom_footprint_image.isVisible = True

            custom_pad_length = custom_footprint_inputs.addValueInput('customPadLength', 'l',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadLength']))
            custom_pad_length.tooltip = _LCLZ("customPadLength", 'Custom Pad Length')
            custom_pad_width = custom_footprint_inputs.addValueInput('customPadWidth', 'c',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadWidth']))
            custom_pad_width.tooltip = _LCLZ('customPadWidth', 'Custom Pad Width')
            custom_pad_span = custom_footprint_inputs.addValueInput('customPadSpan1', 'z',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadSpan1']))
            custom_pad_span.tooltip = _LCLZ('customPadSpan1', 'Custom Pad Span 1')
            custom_pad_span1 = custom_footprint_inputs.addValueInput('customPadSpan2', 'z1',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadSpan2']))
            custom_pad_span1.tooltip = _LCLZ('customPadSpan2', 'Custom Pad Span 2')
            
            custom_pad_length.isEnabled = enable_custom_footprint.value
            custom_pad_width.isEnabled = enable_custom_footprint.value
            custom_pad_span.isEnabled = enable_custom_footprint.value
            custom_pad_span1.isEnabled = enable_custom_footprint.value

            #to reflect the model param e
            pin_pitch = custom_footprint_inputs.addValueInput('pinPitch', 'e',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['verticalPinPitch']))
            pin_pitch.isEnabled = False
            pin_pitch.tooltip = _LCLZ('pinPitchNote', 'Read-only, edit in the package tab')

        # Create a thermal settings tab input. 
        thermal_tab_cmd_inputs = inputs.addTabCommandInput('qfpThermalTab', _LCLZ('thermal', 'Thermal'))
        thermal_pad_inputs = thermal_tab_cmd_inputs.children
        # Create image input.
        labeled_image = thermal_pad_inputs.addImageCommandInput('qfpImage', '', "Resources/img/QFP-Labeled.png")
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True       
        fusion_ui.get_thermal_pad_settings(thermal_pad_inputs, self.ui_data, self.only_3d_model_generator)

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
            inputs.itemById('customPadSpan1').isEnabled = changed_input.value
            inputs.itemById('customPadSpan2').isEnabled = changed_input.value
            inputs.itemById('tab_3').isVisible = not changed_input.value
                        
        if changed_input.id == 'hasThermalPad':    
            inputs.itemById('thermalPadWidth').isEnabled = changed_input.value
            inputs.itemById('thermalPadLength').isEnabled = changed_input.value
            if not self.only_3d_model_generator: 
                inputs.itemById('thermalPadSolderPasteOverride').isVisible = changed_input.value
            #set regenrate model for non parametric updates.                 
            self.reset_regenerate_flag('hasThermalPad', changed_input.value)    
            
        if not self.only_3d_model_generator:
            #update e value only when footprint tab visible
            if changed_input.id == 'verticalPinPitch' :
                inputs.itemById('pinPitch').value = inputs.itemById('verticalPinPitch').value 

        if not self.only_3d_model_generator: 
            paste_calculation_params = ['thermalPadSolderPasteAreaCoverage', 'thermalPadSolderPasteStencilApertureLength', 'thermalPadSolderPasteStencilApertureWidth', 'thermalPadLength', 'thermalPadWidth', 'thermalPadSolderPasteStencilRowCount', 'thermalPadSolderPasteStencilColCount']
            for p in paste_calculation_params:
                if changed_input.id == p:
                    input_data = self.get_inputs()
                    fusion_ui.update_solder_paste_ui(changed_input.id, input_data)

        if changed_input.id == 'padShape':
            pad_shape = list(constant.SMD_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index]     
            if pad_shape == constant.SMD_PAD_SHAPE.get("RoundedRectangle"):
                inputs.itemById('roundedPadCornerSize').isVisible = True
            else:
                inputs.itemById('roundedPadCornerSize').isVisible = False

# register the command into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_QFP, PackageCommandQfp)
