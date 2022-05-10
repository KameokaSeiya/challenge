import adsk.core
import re
from ..Commands import PackageCommand
from ..Utilities import addin_utility,fusion_ui, constant, pkg_command_utility
from ..Utilities.localization import _LCLZ

LEAD_SHAPE_TYPE = {
    'Round' : 'Round',
    'Rectangle' : 'Rectangle'
}

class PackageCommandRadialLed(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_Radial_Round_Led'
        self.cmd_name = _LCLZ('CmdNameRadialLed', 'Radial Round Led Generator')
        self.cmd_description = _LCLZ('CmdDescRadialLed', 'Generate Radial Round Led Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 330
        self.dialog_height = 700 

    def get_defalt_ui_data(self):
        ui_data = {}
        ui_data['cmd_id'] = self.cmd_id
        ui_data['type'] = constant.PKG_TYPE_RADIAL_ROUND_LED
        ui_data['bodyColor'] = constant.BODY_COLOR.get('Red')
        ui_data['horizontalPadCount'] = 2      
        ui_data['verticalPinPitch'] = 0.254
        ui_data['padToHoleRatio'] = 1.5
        ui_data['bodyHeightMax'] = 0.86
        ui_data['bodyHeightMin'] = 0
        ui_data['bodyWidthMax'] = 0.565
        ui_data['bodyWidthMin'] = 0.565
        ui_data['bodyLengthMax'] = 0.565
        ui_data['bodyLengthMin'] = 0.565
        ui_data['terminalThicknessMax'] = 0.05
        ui_data['terminalWidthMax'] = 0.06
        ui_data['terminalWidthMin'] = 0.06
        ui_data['densityLevel'] = 1 # max 2, normal 1, min, 0
        ui_data['padShape'] = 'Round'
        ui_data['leadShape'] = LEAD_SHAPE_TYPE['Rectangle']
        ui_data['customBodyColor'] = 'FF0000'
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY.get('MappingTypeToBodyMax')
        ui_data['bodyOffset'] = 0
        ui_data['hasCustomFootprint'] = False
        ui_data['customPadDiameter'] = 0.158
        ui_data['customHoleDiameter'] = 0.098
        return ui_data

    def validate_ui_input(self, inputs: adsk.core.CommandInputs):

        status = super().validate_ui_input(inputs)
        #input field related check
        pkg_command_utility.ensure_positive_value('terminalWidthMax', inputs, status)
        pkg_command_utility.ensure_positive_value('terminalThicknesshMax', inputs, status)

        #calculation related check
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
        self.ui_data['densityLevel'] = list(constant.DENSITY_LEVEL_TH.values())[inputs.itemById('densityLevel').selectedItem.index]
        self.ui_data['silkscreenMappingTypeToBody'] = list(constant.SILKSCREEN_MAPPING_TO_BODY.values())[inputs.itemById('silkscreenMappingTypeToBody').selectedItem.index]
        self.ui_data['padShape'] = list(constant.PTH_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index]
        self.ui_data['leadShape'] = list(LEAD_SHAPE_TYPE.values())[inputs.itemById('leadShape').selectedItem.index]
        self.ui_data['bodyColor'] = list(constant.BODY_COLOR.values())[inputs.itemById('bodyColor').selectedItem.index]
        self.ui_data['customBodyColor'] = 'FF0000'
        if list(constant.BODY_COLOR.keys())[inputs.itemById('bodyColor').selectedItem.index] == "Custom":
            self.ui_data['customBodyColor'] = inputs.itemById('customBodyColor').text
            self.ui_data['bodyColor'] = self.ui_data['customBodyColor']
        else:   
            self.ui_data['bodyColor'] = list(constant.BODY_COLOR.values())[inputs.itemById('bodyColor').selectedItem.index]
        self.ui_data['bodyLengthMax'] = self.ui_data['bodyWidthMax']
        self.ui_data['bodyLengthMin'] = self.ui_data['bodyWidthMin']

    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects() 

        # Create a package tab input.
        tab1_cmd_inputs = inputs.addTabCommandInput('tab_1', _LCLZ('package', 'Package'))
        tab1_inputs = tab1_cmd_inputs.children
 
        # Create image input.
        labeled_image = tab1_inputs.addImageCommandInput('radialLedImage', '', "Resources/img/Radial-Led-Round-Labeled.png")
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

        tab1_inputs.addTextBoxCommandInput('ledColorNote', '', _LCLZ('ledColorNote', '* Enter value in Hex for custom body color.'), 2, True)
        tab1_inputs.addTextBoxCommandInput('radialLedNote', '', _LCLZ('radialLedNote', '* c is not applicable for rounded lead shape.'), 1, True)

        # Create dropdown input with  list style.
        body_color = tab1_inputs.addDropDownCommandInput('bodyColor', _LCLZ('bodyColor', 'Body Color'), adsk.core.DropDownStyles.TextListDropDownStyle)
        for t in constant.BODY_COLOR:
            body_color.listItems.add(_LCLZ(t, t), True if (constant.BODY_COLOR.get(t) == self.ui_data['bodyColor'] or self.ui_data['customBodyColor'] == self.ui_data['bodyColor']) else False, '')
        body_color.maxVisibleItems = len(constant.BODY_COLOR)

        # custom color input
        custom_color = tab1_inputs.addTextBoxCommandInput('customBodyColor', _LCLZ('customBodyColor', 'Custom Body Color'), self.ui_data['customBodyColor'], 1 , False)
        custom_color.isVisible = True if self.ui_data['customBodyColor'] == self.ui_data['bodyColor'] else False

        # Create lead shape dropdown input 
        lead_shape = tab1_inputs.addDropDownCommandInput('leadShape', _LCLZ('leadShape', 'Lead Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        lead_shape_list = lead_shape.listItems
        for t in LEAD_SHAPE_TYPE:        
            lead_shape_list.add(_LCLZ(t, LEAD_SHAPE_TYPE.get(t)), True if LEAD_SHAPE_TYPE[t] == self.ui_data['leadShape'] else False, '')
        lead_shape.maxVisibleItems = len(LEAD_SHAPE_TYPE)

        # Create dropdown input with test list style.
        pad_shape = tab1_inputs.addDropDownCommandInput('padShape', _LCLZ('padShape', 'Pad Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        pad_shape_list = pad_shape.listItems
        pad_shape_list.add(_LCLZ('Round', constant.PTH_PAD_SHAPE.get('Round')), True if constant.PTH_PAD_SHAPE.get("Round") == self.ui_data['padShape'] else False, "")
        pad_shape_list.add(_LCLZ('Square', constant.PTH_PAD_SHAPE.get('Square')), True if constant.PTH_PAD_SHAPE.get("Square") == self.ui_data['padShape'] else False, "")
        pad_shape.isVisible = not self.only_3d_model_generator
        pad_shape.maxVisibleItems = 2

        pin_pitch = tab1_inputs.addValueInput('verticalPinPitch', 'e', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['verticalPinPitch']))
        pin_pitch.tooltip = _LCLZ('pinPitch', 'Pin Pitch')

        terminal_width = tab1_inputs.addValueInput('terminalWidthMax', 'b', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['terminalWidthMax']))
        terminal_width.tooltip = _LCLZ('leadWidth', 'Lead Width')

        terminal_thickness = tab1_inputs.addValueInput('terminalThicknessMax', 'c', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['terminalThicknessMax']))
        terminal_thickness.isVisible = True if LEAD_SHAPE_TYPE['Rectangle'] == self.ui_data['leadShape'] else False
        terminal_thickness.tooltip = _LCLZ('leadThickness', 'Lead Thickness')

        # table
        table = tab1_inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.hasGrid = False
        table.tablePresentationStyle = 2
        table.maximumVisibleRows = 5
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))
        fusion_ui.add_row_to_table(table, 'bodyWidth', 'D', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyDiameter', 'Body Diameter'))
        fusion_ui.add_row_to_table(table, 'bodyHeight', 'A', None, adsk.core.ValueInput.createByReal(self.ui_data['bodyHeightMax']), _LCLZ('bodyHeight', 'Body Height'))

        #body offset from PCB
        body_offset = tab1_inputs.addValueInput('bodyOffset', 'A1', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['bodyOffset']))
        body_offset.tooltip =_LCLZ('bodyOffset', 'Body Offset')

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
        custom_footprint_image = custom_footprint_inputs.addImageCommandInput('customRadialImage', '', 'Resources/img/Radial-Custom-Footprint.png')
        custom_footprint_image.isFullWidth = True
        custom_footprint_image.isVisible = True
        custom_pad_diameter = custom_footprint_inputs.addValueInput('customPadDiameter', 'p',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadDiameter']))
        custom_pad_diameter.isEnabled = True if enable_custom_footprint.value else False
        custom_pad_diameter.tooltip = _LCLZ('customPadDiameter', 'Custom Pad Diameter')
        custom_hole_diameter = custom_footprint_inputs.addValueInput('customHoleDiameter', 'b1',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customHoleDiameter']))
        custom_hole_diameter.isEnabled = True if enable_custom_footprint.value else False
        custom_hole_diameter.tooltip = _LCLZ('customHoleDiameter', 'Custom Hole Diameter')
        
        #create the tab of Manufacturing settings.
        tab3_cmd_inputs = inputs.addTabCommandInput('tab_3', _LCLZ('Manufacturing', 'Manufacturing'))
        manufacturing_inputs = tab3_cmd_inputs.children
        tab3_cmd_inputs.isVisible = not self.only_3d_model_generator

        # Create dropdown input with test list style.
        density_level = manufacturing_inputs.addDropDownCommandInput('densityLevel', _LCLZ('producibilityLevel', 'Producibility Level'), adsk.core.DropDownStyles.TextListDropDownStyle)
        density_level_list = density_level.listItems
        for t in constant.DENSITY_LEVEL_TH:
            density_level_list.add(_LCLZ(t, t), True if constant.DENSITY_LEVEL_TH.get(t) == self.ui_data['densityLevel'] else False, '')
        density_level.maxVisibleItems = len(constant.DENSITY_LEVEL_TH)

        # Pad to Hole Ratio
        manufacturing_inputs.addValueInput('padToHoleRatio', _LCLZ('padToHoleRatio', 'Pad to Hole Ratio'), '', adsk.core.ValueInput.createByReal(self.ui_data['padToHoleRatio']))

        #Update when using the custom footprint mode
        if self.ui_data['hasCustomFootprint'] : 
            tab3_cmd_inputs.isVisible = False

    def on_input_changed(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs, changed_input: adsk.core.CommandInput, input_values: dict ):
        # update the custom body color
        if changed_input.id == 'bodyColor':
            if list(constant.BODY_COLOR.keys())[inputs.itemById('bodyColor').selectedItem.index] == 'Custom':
                inputs.itemById('customBodyColor').isVisible = True
            else:
                inputs.itemById('customBodyColor').isVisible = False

        if changed_input.id == 'hasCustomFootprint':
            inputs.itemById('customPadDiameter').isEnabled = changed_input.value
            inputs.itemById('customHoleDiameter').isEnabled = changed_input.value
            inputs.itemById('tab_3').isVisible = not changed_input.value

        # update the terminal thickness acc to lead type
        if changed_input.id == 'leadShape':
            lead_shape = list(LEAD_SHAPE_TYPE.values())[inputs.itemById('leadShape').selectedItem.index]
            if lead_shape == LEAD_SHAPE_TYPE['Rectangle']:
                inputs.itemById('terminalThicknessMax').isVisible = True
            else:
                inputs.itemById('terminalThicknessMax').isVisible = False

            #set regenrate model for non parametric updates.  
            self.reset_regenerate_flag('leadShape', lead_shape)   


# register the command into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_RADIAL_ROUND_LED, PackageCommandRadialLed) 
