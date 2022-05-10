import traceback
import adsk.core
import os, sys
from pathlib import Path
from . import PackageCommand
from ..Utilities import addin_utility, fusion_ui, constant, pkg_command_utility
from ..Utilities.localization import _LCLZ

TERMINAL_TYPES = {
    'Collapsing_Ball': constant.TERMINAL_TYPE_COLLAPSING,
    'Non_Collapsing_Ball': constant.TERMINAL_TYPE_NON_COLLAPSING
}

class PackageCommandBGA(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_BGA'
        self.cmd_name = _LCLZ('CmdNameBGA', 'BGA Generator')
        self.cmd_description = _LCLZ('CmdDescBGA', 'Generate BGA Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 330
        self.dialog_height = 670 
   
    def get_defalt_ui_data(self):
        #default parameters
        ui_data = {}
        ui_data['cmd_id'] = self.cmd_id
        ui_data['type'] = constant.PKG_TYPE_BGA
        ui_data['terminalType'] = TERMINAL_TYPES['Collapsing_Ball']
        ui_data['horizontalPadCount'] = 11
        ui_data['verticalPadCount'] = 11
        ui_data['verticalPinPitch'] = 0.05
        ui_data['horizontalPinPitch'] = 0.05
        ui_data['bodyLengthMax'] = 0.62
        ui_data['bodyLengthMin'] = 0.58
        ui_data['bodyWidthMax'] = 0.62
        ui_data['bodyWidthMin'] = 0.58
        ui_data['padWidthMax'] = 0.03
        ui_data['padWidthMin'] = 0.03
        ui_data['bodyHeightMax'] = 0.1
        ui_data['bodyHeightMin'] = 0.1
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY.get('MappingTypeToBodyMax')
        ui_data['fabricationTolerance'] = 0.005
        ui_data['placementTolerance'] = 0.003
        
        ui_data['hasCustomFootprint'] = False
        ui_data['customPadDiameter'] = 0.025
        
        return ui_data

    def validate_ui_input(self, inputs: adsk.core.CommandInputs):

        status = super().validate_ui_input(inputs)
        #input field related check
        pkg_command_utility.ensure_positive_value('horizontalPinPitch', inputs, status)

        #calculation related check
        pad_width = addin_utility.get_float_data(self,'padWidthMax')
        if addin_utility.get_float_data(self,'verticalPinPitch') <  pad_width or addin_utility.get_float_data(self,'horizontalPinPitch') < pad_width:
            status.add_error(_LCLZ("BgaError1", "Balls will intersect as 'b' is greater than 'd' or 'e'."))

        return status

    def update_ui_data(self, inputs):
        
        # update date from UI inputs
        input_data = self.get_inputs()
        for param in self.ui_data:
            if param in input_data:
                self.ui_data[param] = input_data[param]

        self.ui_data['silkscreenMappingTypeToBody'] = list(constant.SILKSCREEN_MAPPING_TO_BODY.values())[inputs.itemById('silkscreenMappingTypeToBody').selectedItem.index]
        self.ui_data['terminalType'] = list(TERMINAL_TYPES.values())[inputs.itemById('terminalType').selectedItem.index]
    
    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects()

        # Create a package tab input.
        tab1_cmd_inputs = inputs.addTabCommandInput('tab_1', _LCLZ('package', 'Package'))
        tab1_inputs = tab1_cmd_inputs.children

        # Create image input.
        labeled_image = tab1_inputs.addImageCommandInput('BGAImage', '', 'Resources/img/BGA-Labeled.png')
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

        # Create dropdown input with  list style.
        component_family = tab1_inputs.addDropDownCommandInput('terminalType', _LCLZ('terminalType', 'Terminal Type'), adsk.core.DropDownStyles.TextListDropDownStyle)
        for t in TERMINAL_TYPES:
            component_family.listItems.add(_LCLZ(t, TERMINAL_TYPES.get(t)), True if TERMINAL_TYPES.get(t) == self.ui_data['terminalType'] else False, '')
        component_family.isVisible = not self.only_3d_model_generator
        component_family.maxVisibleItems = len(TERMINAL_TYPES)

        tab1_inputs.addIntegerSpinnerCommandInput('horizontalPadCount', _LCLZ('#Rows', '# Rows'), 1 , 50 , 1, int(self.ui_data['horizontalPadCount']))
        tab1_inputs.addIntegerSpinnerCommandInput('verticalPadCount', _LCLZ('#Cols', '# Cols'), 1 , 50 , 1, int(self.ui_data['verticalPadCount']))

        row_pitch = tab1_inputs.addValueInput('verticalPinPitch', 'd', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['verticalPinPitch']))
        row_pitch.tooltip = _LCLZ('rowPitch', 'Row Pitch')
        col_pitch = tab1_inputs.addValueInput('horizontalPinPitch', 'e', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['horizontalPinPitch']))
        col_pitch.tooltip = _LCLZ('colPitch', 'Col Pitch')

        # table
        table = tab1_inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.hasGrid = False
        table.tablePresentationStyle = 2
        table.maximumVisibleRows = 5
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))
        fusion_ui.add_row_to_table(table, 'padWidth', 'b', adsk.core.ValueInput.createByReal(self.ui_data['padWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['padWidthMax']), _LCLZ('ballDiameter', 'Ball Diameter'))
        fusion_ui.add_row_to_table(table, 'bodyLength', 'D', adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMax']), _LCLZ('bodyLength', 'Body Length'))
        fusion_ui.add_row_to_table(table, 'bodyWidth', 'E', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyWidth', 'Body Width'))
        fusion_ui.add_row_to_table(table, 'bodyHeight', 'A', None, adsk.core.ValueInput.createByReal(self.ui_data['bodyHeightMax']), _LCLZ('bodyHeight', 'Body Height'))

        # Create dropdown input with test list style.
        map_silkscreen = tab1_inputs.addDropDownCommandInput('silkscreenMappingTypeToBody', _LCLZ('mapSilkscreen', 'Map Silkscreen to Body'), adsk.core.DropDownStyles.TextListDropDownStyle)
        map_silkscreen_list = map_silkscreen.listItems
        for t in constant.SILKSCREEN_MAPPING_TO_BODY:
            map_silkscreen_list.add(_LCLZ(t, constant.SILKSCREEN_MAPPING_TO_BODY.get(t)), True if constant.SILKSCREEN_MAPPING_TO_BODY.get(t) == self.ui_data['silkscreenMappingTypeToBody'] else False, '')
        map_silkscreen.maxVisibleItems = len(constant.SILKSCREEN_MAPPING_TO_BODY)
        map_silkscreen.isVisible = not self.only_3d_model_generator

        # Create a custom footprint tab input.
        tab2_cmd_inputs = inputs.addTabCommandInput('tab_2', _LCLZ('footprint', 'Footprint'))
        custom_footprint_inputs = tab2_cmd_inputs.children
        tab2_cmd_inputs.isVisible = not self.only_3d_model_generator

        # Create image input.
        enable_custom_footprint = custom_footprint_inputs.addBoolValueInput('hasCustomFootprint', _LCLZ('hasCustomFootprint', 'Custom Footprint'), True, '', self.ui_data['hasCustomFootprint'])
        custom_footprint_image = custom_footprint_inputs.addImageCommandInput('customBGAImage', '', "Resources/img/Bga-Custom-Footprint.png")
        custom_footprint_image.isFullWidth = True
        custom_footprint_image.isVisible = True
        custom_pad_diameter = custom_footprint_inputs.addValueInput('customPadDiameter', 'b1',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadDiameter']))
        custom_pad_diameter.isEnabled = True if enable_custom_footprint.value else False
        custom_pad_diameter.tooltip = _LCLZ('customPadDiameter', 'Custom Pad Diameter')

        #create the tab of Manufacturing settings.
        tab3_cmd_inputs = inputs.addTabCommandInput('tab_3', _LCLZ('Manufacturing', 'Manufacturing'))
        manufacturing_inputs = tab3_cmd_inputs.children
        tab3_cmd_inputs.isVisible = not self.only_3d_model_generator
        # fabrication Tolerance 
        manufacturing_inputs.addValueInput('fabricationTolerance', _LCLZ('fabricationTolerance', 'Fabrication Tolerance'),  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['fabricationTolerance']))
        # placement Tolerance
        manufacturing_inputs.addValueInput('placementTolerance', _LCLZ('placementTolerance', 'PlacementTolerance'),  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['placementTolerance']))
        #Update when using the custom footprint mode
        if self.ui_data['hasCustomFootprint'] : 
            tab3_cmd_inputs.isVisible = False


    def on_input_changed(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs, changed_input: adsk.core.CommandInput, input_values: dict ):
        if changed_input.id == 'hasCustomFootprint':
            inputs.itemById('customPadDiameter').isEnabled = changed_input.value
            inputs.itemById('tab_3').isVisible = not changed_input.value


# register the calculator into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_BGA, PackageCommandBGA) 
           