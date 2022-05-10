import adsk.core
from . import PackageCommand
from ..Utilities import addin_utility, constant, pkg_command_utility
from ..Utilities.localization import _LCLZ


FOOTPRINT_LOCATION_TYPES = {
    'CENTER_PADS': constant.FOOTPRINT_LOCATION_CENTER,
    'PIN_ONE': constant.FOOTPRINT_LOCATION_PIN1
}
            
PIN_NUM_SEQUENCE_TYPES  = [
        constant.PIN_NUM_SEQUENCE_LRCCW,
        constant.PIN_NUM_SEQUENCE_LRCW,
        constant.PIN_NUM_SEQUENCE_ZZBT
    ]

class PackageCommandHeader(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)
        self.ui_data = {}
   
    def get_defalt_ui_data(self):
        #default parameters
        ui_data = {}
        # all the header packages shared default values
        ui_data['horizontalPadCount'] = 4
        ui_data['verticalPadCount'] = 2
        ui_data['footprintOriginLocation'] = FOOTPRINT_LOCATION_TYPES['PIN_ONE']
        ui_data['pinNumberSequencePattern'] = PIN_NUM_SEQUENCE_TYPES[1]        
        ui_data['padShape'] = constant.PTH_PAD_SHAPE['Round']    
        ui_data['densityLevel'] = constant.DENSITY_LEVEL_TH['Nominal (B)'] # max 2, normal 1, min, 0
        ui_data['verticalPinPitch'] = 0.254
        ui_data['horizontalPinPitch'] = 0.254
        ui_data['terminalWidth'] = 0.064
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY['MappingTypeToBodyMax']
        ui_data['padToHoleRatio'] = 1.5
        ui_data['hasCustomFootprint'] = False
        ui_data['customPadDiameter'] = 0.171
        ui_data['customHoleDiameter'] = 0.111
        return ui_data

    def validate_ui_input(self, inputs: adsk.core.CommandInputs):

        status = super().validate_ui_input(inputs)
        #input field related check
        pkg_command_utility.ensure_positive_value('horizontalPinPitch', inputs, status)
        pkg_command_utility.ensure_positive_value('terminalWidth', inputs, status)
        pkg_command_utility.ensure_positive_value('horizontalTerminalTailLength', inputs, status)
        pkg_command_utility.ensure_positive_value('terminalTailLength', inputs, status)
        pkg_command_utility.ensure_positive_value('terminalPostLength', inputs, status)
        pkg_command_utility.ensure_positive_value('verticalTerminalTailLength', inputs, status)
       
        #calculation related check
        if self.ui_data['bodyLengthMax'] < (self.ui_data['horizontalPadCount'] - 1) * self.ui_data['horizontalPinPitch'] + self.ui_data['terminalWidth']:
            status.add_error(_LCLZ("HeaderStraightSocketError1", "The pins come out of the body, please check cols, col pitch (d) and D."))

        return status

    def update_ui_data(self, inputs):

        # update date from UI inputs
        input_data = self.get_inputs()
        for param in self.ui_data:
            if param in input_data:
                self.ui_data[param] = input_data[param]
        
        self.ui_data['densityLevel'] = list(constant.DENSITY_LEVEL_TH.values())[inputs.itemById('densityLevel').selectedItem.index]
        self.ui_data['silkscreenMappingTypeToBody'] = list(constant.SILKSCREEN_MAPPING_TO_BODY.values())[inputs.itemById('silkscreenMappingTypeToBody').selectedItem.index]
        self.ui_data['padShape'] = list(constant.PTH_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index]
        self.ui_data['footprintOriginLocation'] = list(FOOTPRINT_LOCATION_TYPES.values())[inputs.itemById('footPrintOrig').selectedItem.index]
        self.ui_data['pinNumberSequencePattern'] = PIN_NUM_SEQUENCE_TYPES[inputs.itemById('pinNumberSequencePattern').selectedItem.index]

    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects()

        # Create a package tab input.
        tab1_cmd_inputs = inputs.addTabCommandInput('tab_1', _LCLZ('package', 'Package'))
        tab1_inputs = tab1_cmd_inputs.children

        # Create image input.
        self.create_package_img(command, tab1_inputs)

        tab1_inputs.addIntegerSpinnerCommandInput('verticalPadCount', _LCLZ('#Rows', '# Rows'), 1 , 50 , 1, int(self.ui_data['verticalPadCount']))
        tab1_inputs.addIntegerSpinnerCommandInput('horizontalPadCount', _LCLZ('#Cols', '# Cols'), 1 , 100 , 1, int(self.ui_data['horizontalPadCount']))        

        # Create footprint dropdown input 
        if self.only_3d_model_generator : 
            lclz_string = _LCLZ('modelOrigin', 'Model Origin')
        else : 
            lclz_string = _LCLZ('footPrintOrig', 'Footprint Origin')
        footprint_origin = tab1_inputs.addDropDownCommandInput('footPrintOrig', lclz_string, adsk.core.DropDownStyles.TextListDropDownStyle)
        for t in FOOTPRINT_LOCATION_TYPES:
            footprint_origin.listItems.add(_LCLZ(t, FOOTPRINT_LOCATION_TYPES.get(t)), True if FOOTPRINT_LOCATION_TYPES.get(t) == self.ui_data['footprintOriginLocation'] else False, '')
        footprint_origin.maxVisibleItems = len(FOOTPRINT_LOCATION_TYPES)

        pin_num_input = tab1_inputs.addButtonRowCommandInput('pinNumberSequencePattern', _LCLZ('pinNumbering', 'Pin # Pattern'), False)
        for t in PIN_NUM_SEQUENCE_TYPES:
            img_path = 'Resources/img/'+ t
            pin_num_input.listItems.add(_LCLZ(t, t), True if t == self.ui_data['pinNumberSequencePattern'] else False, img_path)
        
        # Create pad shap dropdown input
        pad_shape = tab1_inputs.addDropDownCommandInput('padShape', _LCLZ('padShape', 'Pad Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        pad_shape_list = pad_shape.listItems
        pad_shape_list.add(_LCLZ('Round', constant.PTH_PAD_SHAPE.get('Round')), True if constant.PTH_PAD_SHAPE.get("Round") == self.ui_data['padShape'] else False, "")
        pad_shape_list.add(_LCLZ('Square', constant.PTH_PAD_SHAPE.get('Square')), True if constant.PTH_PAD_SHAPE.get("Square") == self.ui_data['padShape'] else False, "")
        pad_shape.isVisible = not self.only_3d_model_generator
        pad_shape.maxVisibleItems = 2

        # create pin pitch e
        row_pitch = tab1_inputs.addValueInput('verticalPinPitch', 'e', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['verticalPinPitch']))
        row_pitch.tooltip = _LCLZ('rowPitch', 'Row Pitch')
        # create pin pitch d
        col_pitch = tab1_inputs.addValueInput('horizontalPinPitch', 'd', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['horizontalPinPitch']))
        col_pitch.tooltip = _LCLZ('colPitch', 'Col Pitch')

        # create package specific UIs
        self.create_dimension_ui(command, tab1_inputs)

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
        self.create_custom_footprint_img(command, custom_footprint_inputs)
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

    def create_dimension_ui(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        pass

    def create_package_img(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        pass

    def create_custom_footprint_img(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        pass