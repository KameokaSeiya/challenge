import adsk.core
from ..Commands import PackageCommand
from ..Utilities import addin_utility,fusion_ui, constant
from ..Utilities.localization import _LCLZ

RADIAL_FAMILY_TYPES = {
    'POLARIZED_CAPACITOR': constant.COMP_FAMILY_POLARIZED_CAPACITOR,
    'NONPOLARIZED_CAPACITOR': constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR,
    'POLARIZED_INDUCTOR': constant.COMP_FAMILY_POLARIZED_INDUCTOR,
    'NONPOLARIZED_INDUCTOR': constant.COMP_FAMILY_NONPOLARIZED_INDUCTOR
}

RADIAL_BODY_COLOR = {
    'CAPACITOR':{
        'Black': constant.COLOR_VALUE_BLACK,
        'Green': constant.COLOR_VALUE_GREEN,
        'Blue': constant.COLOR_VALUE_BLUE,
        'Yellow': constant.COLOR_VALUE_YELLOW,
        'Amber': constant.COLOR_VALUE_AMBER,
        'Brown': constant.COLOR_VALUE_BROWN,
        'Cyan': constant.COLOR_VALUE_CYAN,
        'Maroon': constant.COLOR_VALUE_MAROON
    },
    'INDUCTOR':{
        'Black': constant.COLOR_VALUE_BLACK,
        'Brown': constant.COLOR_VALUE_BROWN,
        'Grey': constant.COLOR_VALUE_GREY,
        'Silver': constant.COLOR_VALUE_SILVER
    },
}

class PackageCommandRadial(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_Radial'
        self.cmd_name = _LCLZ('CmdNameRadial', 'Radial Generator')
        self.cmd_description = _LCLZ('CmdDescRadial', 'Generate Radial Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 300
        self.dialog_height = 570 

    def get_defalt_ui_data(self):
        ui_data = {}
        ui_data['cmd_id'] = self.cmd_id
        ui_data['type'] = constant.PKG_TYPE_RADIAL_ECAP
        ui_data['componentFamily'] = RADIAL_FAMILY_TYPES['POLARIZED_CAPACITOR']  
        ui_data['bodyColor'] = RADIAL_BODY_COLOR['CAPACITOR']['Blue']
        ui_data['horizontalPadCount'] = 2      
        ui_data['verticalPinPitch'] = 0.5080
        ui_data['padToHoleRatio'] = 1.5
        ui_data['bodyHeightMax'] = 1.1
        ui_data['bodyHeightMin'] = 0
        ui_data['bodyWidthMax'] = 1.0
        ui_data['bodyWidthMin'] = 1.0
        ui_data['terminalWidthMax'] = 0.065
        ui_data['terminalWidthMin'] = 0.065
        ui_data['bodyLengthMax'] = 0.065
        ui_data['bodyLengthMin'] = 0.065
        ui_data['densityLevel'] = 1 # max 2, normal 1, min, 0
        ui_data['padShape'] = 'Round'
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY.get('MappingTypeToBodyMax')
        ui_data['hasCustomFootprint'] = False
        ui_data['customPadDiameter'] = 0.145
        ui_data['customHoleDiameter'] = 0.085
        return ui_data

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
        self.ui_data['componentFamily'] = list(RADIAL_FAMILY_TYPES.values())[inputs.itemById('componentFamily').selectedItem.index]
        self.ui_data['bodyLengthMax'] = self.ui_data['bodyWidthMax']
        self.ui_data['bodyLengthMin'] = self.ui_data['bodyWidthMin']
        if self.ui_data['type'] == constant.PKG_TYPE_RADIAL_INDUCTOR:
            self.ui_data['bodyColor'] = list(RADIAL_BODY_COLOR['INDUCTOR'].values())[inputs.itemById('bodyColor').selectedItem.index]
        else:
            self.ui_data['bodyColor'] = list(RADIAL_BODY_COLOR['CAPACITOR'].values())[inputs.itemById('bodyColor').selectedItem.index]

    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects() 

        # Create a package tab input.
        tab1_cmd_inputs = inputs.addTabCommandInput('tab_1', _LCLZ('package', 'Package'))
        tab1_inputs = tab1_cmd_inputs.children
 
        # Create image input.
        labeled_image = tab1_inputs.addImageCommandInput('radialImage', '', "Resources/img/Radial-Round-Labeled.png")
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

        # Create dropdown input with test list style.
        component_family = tab1_inputs.addDropDownCommandInput('componentFamily', _LCLZ('componentFamily', 'Component Family'), adsk.core.DropDownStyles.TextListDropDownStyle)
        component_family_list = component_family.listItems
        for t in RADIAL_FAMILY_TYPES:
            component_family_list.add(_LCLZ(t, RADIAL_FAMILY_TYPES.get(t)), True if RADIAL_FAMILY_TYPES.get(t) == self.ui_data['componentFamily'] else False, '')
        component_family.maxVisibleItems = len(RADIAL_FAMILY_TYPES)

        # Create dropdown input with  list style.
        body_color = tab1_inputs.addDropDownCommandInput('bodyColor', _LCLZ('bodyColor', 'Body Color'), adsk.core.DropDownStyles.TextListDropDownStyle)
        selected_component_family = list(RADIAL_FAMILY_TYPES.values())[inputs.itemById('componentFamily').selectedItem.index]
        if selected_component_family == constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR or selected_component_family == constant.COMP_FAMILY_POLARIZED_CAPACITOR:
            for t in RADIAL_BODY_COLOR['CAPACITOR']:
                body_color.listItems.add(_LCLZ(t, t), True if RADIAL_BODY_COLOR['CAPACITOR'][t] == self.ui_data['bodyColor'] else False, '')
                body_color.maxVisibleItems = len(RADIAL_BODY_COLOR['CAPACITOR'])
        else:
            for t in RADIAL_BODY_COLOR['INDUCTOR']:
                body_color.listItems.add(_LCLZ(t, t), True if RADIAL_BODY_COLOR['INDUCTOR'][t] == self.ui_data['bodyColor'] else False, '')
                body_color.maxVisibleItems = len(RADIAL_BODY_COLOR['INDUCTOR'])
        

        # Create dropdown input with test list style.
        pad_shape = tab1_inputs.addDropDownCommandInput('padShape', _LCLZ('padShape', 'Pad Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        pad_shape_list = pad_shape.listItems
        pad_shape_list.add(_LCLZ('Round', constant.PTH_PAD_SHAPE.get('Round')), True if constant.PTH_PAD_SHAPE.get("Round") == self.ui_data['padShape'] else False, "")
        pad_shape_list.add(_LCLZ('Square', constant.PTH_PAD_SHAPE.get('Square')), True if constant.PTH_PAD_SHAPE.get("Square") == self.ui_data['padShape'] else False, "")
        pad_shape.isVisible = not self.only_3d_model_generator
        pad_shape.maxVisibleItems = 2

        pin_pitch = tab1_inputs.addValueInput('verticalPinPitch', 'e', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['verticalPinPitch']))
        pin_pitch.tooltip = _LCLZ('pinPitch', 'Pin Pitch')

        # table
        table = tab1_inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.hasGrid = False
        table.tablePresentationStyle = 2
        table.maximumVisibleRows = 5
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))
        fusion_ui.add_row_to_table(table, 'terminalWidth', 'b', None, adsk.core.ValueInput.createByReal(self.ui_data['terminalWidthMax']), _LCLZ('leadDiameter', 'Lead Diameter'))
        fusion_ui.add_row_to_table(table, 'bodyWidth', 'D', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyDiameter', 'Body Diameter'))
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
        
        if changed_input.id == 'hasCustomFootprint':
            inputs.itemById('customPadDiameter').isEnabled = changed_input.value
            inputs.itemById('customHoleDiameter').isEnabled = changed_input.value
            inputs.itemById('tab_3').isVisible = not changed_input.value

        if changed_input.id == 'componentFamily':
            selected_component_family = list(RADIAL_FAMILY_TYPES.values())[inputs.itemById('componentFamily').selectedItem.index]
            body_color = inputs.itemById('bodyColor')
            body_color_list = body_color.listItems
            body_color_list.clear()
            default_color = 'Black'
            pkg_type = self.ui_data['type']
            if selected_component_family == constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR or selected_component_family == constant.COMP_FAMILY_POLARIZED_CAPACITOR:
                self.ui_data['type'] = constant.PKG_TYPE_RADIAL_ECAP
                if selected_component_family == constant.COMP_FAMILY_POLARIZED_CAPACITOR:
                    default_color = 'Blue'
                for t in RADIAL_BODY_COLOR['CAPACITOR']:
                    body_color_list.add(_LCLZ(t, t), True if t == default_color else False, '')
                body_color.maxVisibleItems = len(RADIAL_BODY_COLOR['CAPACITOR'])

            elif selected_component_family == constant.COMP_FAMILY_NONPOLARIZED_INDUCTOR or selected_component_family == constant.COMP_FAMILY_POLARIZED_INDUCTOR:
                self.ui_data['type'] = constant.PKG_TYPE_RADIAL_INDUCTOR
                if selected_component_family == constant.COMP_FAMILY_POLARIZED_INDUCTOR:
                     default_color = 'Grey'   
                for t in RADIAL_BODY_COLOR['INDUCTOR']:
                    body_color_list.add(_LCLZ(t, t), True if t == default_color else False, '')
                body_color.maxVisibleItems = len(RADIAL_BODY_COLOR['INDUCTOR'])    

            #set regenrate model for non parametric updates. 
            self.reset_regenerate_flag('componentFamily', selected_component_family)   

# register the command into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_RADIAL_ECAP, PackageCommandRadial) 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_RADIAL_INDUCTOR, PackageCommandRadial)