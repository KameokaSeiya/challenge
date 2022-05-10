import adsk.core
import re
from . import PackageCommand
from ..Utilities import addin_utility, fusion_ui, constant
from ..Utilities.localization import _LCLZ



LEN_TYPES = {
    'RECT_FLAT_TOP': constant.LENS_TYPE_FLAT_TOP,
    'RECT_DOMED_TOP': constant.LENS_TYPE_DOMED_TOP
}

class PackageCommandChipLed(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_Chip_led'
        self.cmd_name = _LCLZ('CmdNameChipLed', 'Chip LED Generator')
        self.cmd_description = _LCLZ('CmdDescChipLed', 'Generate Chip LED Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 320
        self.dialog_height = 690 
   
    def get_defalt_ui_data(self):
        #default parameters
        ui_data = {}
        ui_data['type'] = constant.PKG_TYPE_CHIP_LED
        ui_data['cmd_id'] = self.cmd_id
        ui_data['horizontalPadCount'] = 2 # for metadata only
        ui_data['bodyColor'] = constant.BODY_COLOR.get('Red')
        ui_data['customBodyColor'] = 'FF0000'
        ui_data['padShape'] = constant.SMD_PAD_SHAPE.get('Rectangle')
        ui_data['roundedPadCornerSize'] = 40
        ui_data['densityLevel'] = constant.DENSITY_LEVEL_SMD['Nominal (N)']
        ui_data['lensType'] = LEN_TYPES['RECT_FLAT_TOP']
        ui_data['padWidthMax'] = 0.03
        ui_data['padWidthMin'] = 0.025
        ui_data['bodyWidthMax'] = 0.16
        ui_data['bodyWidthMin'] = 0.14
        ui_data['bodyLengthMax'] = 0.08
        ui_data['bodyLengthMin'] = 0.07
        ui_data['baseHeightMax'] = 0.025
        ui_data['bodyHeightMax'] = 0.08
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY.get('MappingTypeToBodyMax')
        ui_data['fabricationTolerance'] = 0.005
        ui_data['placementTolerance'] = 0.003
        ui_data['domeDiameter'] = 0.07
   
        ui_data['hasCustomFootprint'] = False
        ui_data['customPadLength'] = 0.061
        ui_data['customPadWidth'] = 0.085
        ui_data['customPadToPadGap'] = 0.082
        return ui_data

    def validate_ui_input(self, inputs: adsk.core.CommandInputs):

        status = super().validate_ui_input(inputs)
        #calculation related check
        if addin_utility.get_float_data(self,'bodyWidthMax') < float('{:.6f}'.format(2 * self.ui_data['padWidthMax']))  :
            status.add_error(_LCLZ("ChipLedError", "The value of D should be greater than terminal size combined i.e. 2 * L."))

        if list(constant.BODY_COLOR.keys())[inputs.itemById('bodyColor').selectedItem.index] == "Custom":
            if not self.ui_data['customBodyColor'] :
                status.add_error(_LCLZ("ChipLedError1", "Custom Body Color can't be empty."))

            custom_color = self.ui_data['customBodyColor']
            reg_exp = "^#?[a-fA-F0-9]{3}([a-fA-F0-9]{3})?$"
            result = re.match(reg_exp, custom_color)

            if not result:
                status.add_error(_LCLZ("ChipLedError2", "Enter Custom Body Color in hex format."))

        return status 

    def update_ui_data(self, inputs):
        
        # update date from UI inputs
        input_data = self.get_inputs()
        for param in self.ui_data:
            if param in input_data:
                self.ui_data[param] = input_data[param]
        
        # update ui parameters
        self.ui_data['densityLevel'] = list(constant.DENSITY_LEVEL_SMD.values())[inputs.itemById('densityLevel').selectedItem.index]
        self.ui_data['silkscreenMappingTypeToBody'] = list(constant.SILKSCREEN_MAPPING_TO_BODY.values())[inputs.itemById('silkscreenMappingTypeToBody').selectedItem.index]
        self.ui_data['padShape'] = list(constant.SMD_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index]
        self.ui_data['lensType'] = list(LEN_TYPES.values())[inputs.itemById('lensType').selectedItem.index]
        self.ui_data['customBodyColor'] = 'FF0000'
        if list(constant.BODY_COLOR.keys())[inputs.itemById('bodyColor').selectedItem.index] == "Custom":
            self.ui_data['customBodyColor'] = inputs.itemById('customBodyColor').text
            self.ui_data['bodyColor'] = self.ui_data['customBodyColor']
        else:   
            self.ui_data['bodyColor'] = list(constant.BODY_COLOR.values())[inputs.itemById('bodyColor').selectedItem.index]
    
    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects()

        # Create a package tab input.
        tab1_cmd_inputs = inputs.addTabCommandInput('tab_1', _LCLZ('package', 'Package'))
        chip_inputs = tab1_cmd_inputs.children
        
        # Create image input.
        labeled_image = chip_inputs.addImageCommandInput('ChipLEDImage', '', 'Resources/img/Chip-Led-Labeled.png')
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

        chip_inputs.addTextBoxCommandInput('ledColorNote', '', _LCLZ('ledColorNote', '* Enter value in Hex for custom body color.'), 2, True)

        # Create dropdown input with  list style.
        body_color = chip_inputs.addDropDownCommandInput('bodyColor', _LCLZ('bodyColor', 'Body Color'), adsk.core.DropDownStyles.TextListDropDownStyle)
        for t in constant.BODY_COLOR:
            body_color.listItems.add(_LCLZ(t, t), True if (constant.BODY_COLOR.get(t) == self.ui_data['bodyColor'] or self.ui_data['customBodyColor'] == self.ui_data['bodyColor']) else False, '')
        body_color.maxVisibleItems = len(constant.BODY_COLOR)

        # custom color input
        custom_color = chip_inputs.addTextBoxCommandInput('customBodyColor', _LCLZ('customBodyColor', 'Custom Body Color'), self.ui_data['customBodyColor'], 1 , False)
        custom_color.isVisible = True if self.ui_data['customBodyColor'] == self.ui_data['bodyColor'] else False

        # Create dropdown input with test list style.
        pad_shape = chip_inputs.addDropDownCommandInput('padShape', _LCLZ('padShape', 'Pad Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        pad_shape_list = pad_shape.listItems
        pad_shape_list.add(_LCLZ('Rectangle', constant.SMD_PAD_SHAPE.get('Rectangle')), True if constant.SMD_PAD_SHAPE.get('Rectangle') == self.ui_data['padShape'] else False, "")        
        pad_shape_list.add(_LCLZ('RoundedRectangle', constant.SMD_PAD_SHAPE.get("RoundedRectangle")), True if constant.SMD_PAD_SHAPE.get("RoundedRectangle") == self.ui_data['padShape'] else False, "")
        pad_shape.isVisible = not self.only_3d_model_generator
        pad_shape.maxVisibleItems = 2

        # create round corner size input
        rounded_corner = chip_inputs.addIntegerSpinnerCommandInput('roundedPadCornerSize', _LCLZ('padRoundness', 'Pad Roundness (%)'), 1, 100 , 1, int(self.ui_data['roundedPadCornerSize']))
        rounded_corner.isVisible = True if constant.SMD_PAD_SHAPE.get('RoundedRectangle') == self.ui_data['padShape'] else False

        # Create dropdown input of lens shape
        lens_shape = chip_inputs.addDropDownCommandInput('lensType', _LCLZ('lensShape', 'Lens Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        for t in LEN_TYPES:
            lens_shape.listItems.add(_LCLZ(t, LEN_TYPES[t]), True if LEN_TYPES[t] == self.ui_data['lensType'] else False, '')
        lens_shape.maxVisibleItems = len(LEN_TYPES)

        # create dome diameter input
        dome_diameter = chip_inputs.addValueInput('domeDiameter', 'd',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['domeDiameter']))
        dome_diameter.isVisible = True if LEN_TYPES['RECT_DOMED_TOP'] == self.ui_data['lensType'] else False
        dome_diameter.tooltip = _LCLZ('domeDiameter', 'Dome Diameter')

        # table
        table = chip_inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.hasGrid = False
        table.tablePresentationStyle = 2
        table.maximumVisibleRows = 6
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))
        fusion_ui.add_row_to_table(table, 'padWidth', 'L', adsk.core.ValueInput.createByReal(self.ui_data['padWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['padWidthMax']), _LCLZ('terminalLength', 'Terminal Length'))
        fusion_ui.add_row_to_table(table, 'bodyWidth', 'D', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyLength', 'Body Length'))
        fusion_ui.add_row_to_table(table, 'bodyLength', 'E', adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMax']), _LCLZ('bodyWidth', 'Body Width'))
        fusion_ui.add_row_to_table(table, 'bodyHeight', 'A', None, adsk.core.ValueInput.createByReal(self.ui_data['bodyHeightMax']), _LCLZ('bodyHeight', 'Body Height' ))
        fusion_ui.add_row_to_table(table, 'baseHeight', 'A1', None, adsk.core.ValueInput.createByReal(self.ui_data['baseHeightMax']), _LCLZ('baseHeight', 'Base Height'))
        
        # Create dropdown input with test list style.
        map_silkscreen = chip_inputs.addDropDownCommandInput('silkscreenMappingTypeToBody', _LCLZ('mapSilkscreen', 'Map Silkscreen to Body'), adsk.core.DropDownStyles.TextListDropDownStyle)
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
        custom_footprint_image = custom_footprint_inputs.addImageCommandInput('customChipImage', '', 'Resources/img/SOD-Custom-Footprint.png') #Custom footprint image is same as SOD
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

        if changed_input.id == 'hasCustomFootprint':
            inputs.itemById('customPadLength').isEnabled = changed_input.value
            inputs.itemById('customPadWidth').isEnabled = changed_input.value
            inputs.itemById('customPadToPadGap').isEnabled = changed_input.value
            inputs.itemById('tab_3').isVisible = not changed_input.value
                    
        if changed_input.id == 'padShape':
            if list(constant.SMD_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index] == constant.SMD_PAD_SHAPE.get("RoundedRectangle"):
                inputs.itemById('roundedPadCornerSize').isVisible = True
            else:
                inputs.itemById('roundedPadCornerSize').isVisible = False
        
        # update the custom body color
        if changed_input.id == 'bodyColor':
            if list(constant.BODY_COLOR.keys())[inputs.itemById('bodyColor').selectedItem.index] == 'Custom':
                inputs.itemById('customBodyColor').isVisible = True
            else:
                inputs.itemById('customBodyColor').isVisible = False
        # update the dome diameter
        if changed_input.id == 'lensType':
            lens_type = list(LEN_TYPES.values())[inputs.itemById('lensType').selectedItem.index]
            if lens_type == LEN_TYPES['RECT_DOMED_TOP']:
                inputs.itemById('domeDiameter').isVisible = True
            else:
                inputs.itemById('domeDiameter').isVisible = False
            #set regenrate model for non parametric updates.  
            self.reset_regenerate_flag('lensType', lens_type)
                  
# register the calculator into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_CHIP_LED, PackageCommandChipLed) 
           