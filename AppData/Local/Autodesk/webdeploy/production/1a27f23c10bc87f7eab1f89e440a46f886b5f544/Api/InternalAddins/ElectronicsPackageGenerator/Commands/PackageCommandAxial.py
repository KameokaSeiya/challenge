import adsk.core
from pathlib import Path
from ..Commands import PackageCommand
from ..Calculators import pkg_calculator_axial
from ..Utilities import addin_utility, fusion_ui, constant
from ..Utilities.localization import _LCLZ

AXIAL_FAMILY_TYPES = {
    'RESISTOR': constant.COMP_FAMILY_RESISTOR,
    'NONPOLARIZED_CAPACITOR': constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR,
    'POLARIZED_CAPACITOR': constant.COMP_FAMILY_POLARIZED_CAPACITOR,
    'DIODE': constant.COMP_FAMILY_DIODE,
    'FUSE': constant.COMP_FAMILY_FUSE,
    'INDUCTOR': constant.COMP_FAMILY_INDUCTOR
}

class PackageCommandAxial(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_Axial'
        self.cmd_name = _LCLZ('CmdNameAxial', 'Axial Generator')
        self.cmd_description = _LCLZ('CmdDescAxial', 'Generate Axial Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 390
        self.dialog_height = 720 

    def get_defalt_ui_data(self):
        ui_data = {}
        ui_data['cmd_id'] = self.cmd_id
        ui_data['type'] = constant.PKG_TYPE_AXIAL_RESISTOR
        ui_data['componentFamily'] = AXIAL_FAMILY_TYPES['RESISTOR']  
        ui_data['horizontalPadCount'] = 2      
        ui_data['verticalPinPitch'] = 1.176
        ui_data['padToHoleRatio'] = 1.5
        ui_data['bodyHeightMax'] = 0.25
        ui_data['bodyHeightMin'] = 0
        ui_data['bodyWidthMax'] = 0.85
        ui_data['bodyWidthMin'] = 0.85
        ui_data['bodyLengthMax'] = 0.25
        ui_data['bodyLengthMin'] = 0.25
        ui_data['terminalWidthMax'] = 0.063
        ui_data['pitchOverride'] = False
        ui_data['densityLevel'] = 1 # max 2, normal 1, min, 0
        ui_data['padShape'] = 'Round'
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY.get('MappingTypeToBodyMax')
        ui_data['hasCustomFootprint'] = False
        ui_data['customPadDiameter'] = 0.143
        ui_data['customHoleDiameter'] = 0.083
        return ui_data

    def validate_ui_input(self, inputs: adsk.core.CommandInputs):

        status = super().validate_ui_input(inputs)
        #calculation related check
        if addin_utility.get_float_data(self,'bodyHeightMax') <  addin_utility.get_float_data(self,'bodyLengthMax') :
            status.add_error(_LCLZ( "AxialError1","A should always be greater than E.")) 
        #if self.ui_data['bodyWidthMax'] + 2 * self.get_bend_radius() > self.get_pin_pitch() :
        #    status.add_error(_LCLZ( "AxialError2","There is no space for bending of pins, please check e and D parameters."))
            
        return status 

    def update_ui_data(self, inputs):
        # update date from UI inputs
        input_data = self.get_inputs()
        for param in self.ui_data:
            if param in input_data:
                self.ui_data[param] = input_data[param]
        
        # update the density level
        self.ui_data['densityLevel'] = list(constant.DENSITY_LEVEL_TH.values())[inputs.itemById('densityLevel').selectedItem.index]
        self.ui_data['silkscreenMappingTypeToBody'] = list(constant.SILKSCREEN_MAPPING_TO_BODY.values())[inputs.itemById('silkscreenMappingTypeToBody').selectedItem.index]
        self.ui_data['padShape'] = list(constant.PTH_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index]
        self.ui_data['componentFamily'] = list(AXIAL_FAMILY_TYPES.values())[inputs.itemById('componentFamily').selectedItem.index]
        self.ui_data['pitchOverride'] = inputs.itemById('pitchOverride').isEnabledCheckBoxChecked

    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects() 

        # Create a package tab input.
        tab1_cmd_inputs = inputs.addTabCommandInput('tab_1', _LCLZ('package', 'Package'))
        tab1_inputs = tab1_cmd_inputs.children

        # Create image input.
        labeled_image = tab1_inputs.addImageCommandInput('axialImage', '', "Resources/img/Axial-Labeled.png")
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

        # Create a read only textbox input.
        tab1_inputs.addTextBoxCommandInput('readonly_textBox', '', _LCLZ('axialNote', '* Pin pitch is automatically calculated based on the size of body, terminal and producibility level to make the footprint IPC compliant. However you can provide custom value by overriding pin pitch to create non IPC compliant footprint.'), 4, True)

        # Create dropdown input with test list style.
        component_family = tab1_inputs.addDropDownCommandInput('componentFamily', _LCLZ('componentFamily', 'Component Family'), adsk.core.DropDownStyles.TextListDropDownStyle)
        component_family_list = component_family.listItems
        for t in AXIAL_FAMILY_TYPES:
            component_family_list.add(_LCLZ(t, AXIAL_FAMILY_TYPES.get(t)), True if AXIAL_FAMILY_TYPES.get(t) == self.ui_data['componentFamily'] else False, '')
        component_family.maxVisibleItems = len(AXIAL_FAMILY_TYPES)

        # Create dropdown input with test list style.
        pad_shape = tab1_inputs.addDropDownCommandInput('padShape', _LCLZ('padShape', 'Pad Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        pad_shape_list = pad_shape.listItems
        pad_shape_list.add(_LCLZ('Round', constant.PTH_PAD_SHAPE.get('Round')), True if constant.PTH_PAD_SHAPE.get("Round") == self.ui_data['padShape'] else False, "")
        pad_shape_list.add(_LCLZ('Square', constant.PTH_PAD_SHAPE.get('Square')), True if constant.PTH_PAD_SHAPE.get("Square") == self.ui_data['padShape'] else False, "")
        pad_shape.maxVisibleItems = 2
        pad_shape.isVisible = not self.only_3d_model_generator

        # Create group input.
        groupCmdInput = tab1_inputs.addGroupCommandInput('pitchOverride', _LCLZ('overridePitch', 'Override Pin Pitch'))
        groupCmdInput.isExpanded = True
        groupCmdInput.isEnabledCheckBoxDisplayed = True
        groupCmdInput.isEnabledCheckBoxChecked = self.ui_data['pitchOverride']
        groupChildInputs = groupCmdInput.children

        pin_pitch = groupChildInputs.addValueInput('verticalPinPitch', 'e', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['verticalPinPitch']))
        pin_pitch.tooltip = _LCLZ('pinPitch', 'Pin Pitch')

        # table
        table = tab1_inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.hasGrid = False
        table.tablePresentationStyle = 2
        table.maximumVisibleRows = 5
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))
        fusion_ui.add_row_to_table(table, 'terminalWidth', 'b', None, adsk.core.ValueInput.createByReal(self.ui_data['terminalWidthMax']), _LCLZ('leadDiameter', 'Lead Diameter'))
        fusion_ui.add_row_to_table(table, 'bodyWidth', 'D', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyLength', 'Body Length'))
        fusion_ui.add_row_to_table(table, 'bodyLength', 'E', adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMax']), _LCLZ('bodyDiameter', 'Body Diameter'))
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
        custom_footprint_image = custom_footprint_inputs.addImageCommandInput('customAxialImage', '', 'Resources/img/Axial-Custom-Footprint.png')
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
        if changed_input.id == 'componentFamily':
            selected_component_family = list(AXIAL_FAMILY_TYPES.values())[inputs.itemById('componentFamily').selectedItem.index]
            pkg_type = self.ui_data['type']
            if selected_component_family == constant.COMP_FAMILY_RESISTOR or selected_component_family == constant.COMP_FAMILY_INDUCTOR:
                self.ui_data['type'] = constant.PKG_TYPE_AXIAL_RESISTOR
            elif selected_component_family == constant.COMP_FAMILY_DIODE or selected_component_family == constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR:
                #set regenrate model for non parametric updates.    
                self.reset_regenerate_flag('componentFamily', selected_component_family)
                self.ui_data['type'] = constant.PKG_TYPE_AXIAL_DIODE
            elif selected_component_family == constant.COMP_FAMILY_FUSE:
                self.ui_data['type'] = constant.PKG_TYPE_AXIAL_FUSE
            elif selected_component_family == constant.COMP_FAMILY_POLARIZED_CAPACITOR:
                self.ui_data['type'] = constant.PKG_TYPE_AXIAL_POLARIZED_CAPACITOR  
            # regenerate 3d model for package type change. 
            self.reset_regenerate_flag('type', pkg_type)

        if changed_input.id == 'hasCustomFootprint':
            inputs.itemById('customPadDiameter').isEnabled = changed_input.value
            inputs.itemById('customHoleDiameter').isEnabled = changed_input.value
            inputs.itemById('tab_3').isVisible = not changed_input.value

# register the command into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_AXIAL_DIODE, PackageCommandAxial)
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_AXIAL_POLARIZED_CAPACITOR, PackageCommandAxial)
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_AXIAL_FUSE, PackageCommandAxial)
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_AXIAL_RESISTOR, PackageCommandAxial)