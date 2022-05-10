import adsk.core
from pathlib import Path
from . import PackageCommand
from ..Utilities import addin_utility, fusion_ui, constant
from ..Utilities.localization import _LCLZ

ROW_TYPES = {
    'SINGLE': constant.ROW_TYPE_SINGLE,
    'DOUBLE': constant.ROW_TYPE_DOUBLE
}

FOOTPRINT_LOCATION_TYPES = {
    'CENTER_PADS': constant.FOOTPRINT_LOCATION_CENTER,
    'PIN_ONE': constant.FOOTPRINT_LOCATION_PIN1
}
            
PIN_NUM_SEQUENCE_TYPES  = [
        constant.PIN_NUM_SEQUENCE_LRCCW,
        constant.PIN_NUM_SEQUENCE_LRCW,
        constant.PIN_NUM_SEQUENCE_ZZBT
]

class PackageCommandSurfaceMountHeader(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)
        self.ui_data = {}
   
    def get_defalt_ui_data(self):
        #default parameters
        ui_data = {}
        ui_data['verticalPadCount'] = constant.ROW_TYPE_DOUBLE
        ui_data['horizontalPadCount'] = 4
        ui_data['verticalPinPitch'] = 0.254
        ui_data['horizontalPinPitch'] = 0.254
        ui_data['padHeightMin'] = 0.046
        ui_data['padHeightMax'] = 0.046
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY.get('MappingTypeToBodyMax')
        ui_data['hasCustomFootprint'] = False
        #ui_data['densityLevel'] = 1 # max 2, normal 1, min, 0 
        ui_data['fabricationTolerance'] = 0.005
        ui_data['placementTolerance'] = 0.003
        ui_data['tailLengthOverride'] = False
        ui_data['footprintOriginLocation'] = FOOTPRINT_LOCATION_TYPES['PIN_ONE']
        ui_data['pinNumberSequencePattern'] = PIN_NUM_SEQUENCE_TYPES[1]        
        ui_data['padShape'] = 'Rectangle'
        ui_data['roundedPadCornerSize'] = 40
        return ui_data

    def validate_ui_input(self, inputs: adsk.core.CommandInputs):

        status = super().validate_ui_input(inputs)
        if self.ui_data['verticalPadCount'] == 'Single Row':
            rows = 1
        else :
            rows = 2
        #calculation related check
        if self.ui_data['type'] != 'surface_mount_pin_header_right_angle' :
            if self.ui_data['bodyWidthMax'] >= self.ui_data['verticalLeadToLeadSpanMax'] :
                status.add_error(_LCLZ("LJLeadError2", "E should be greater than E1."))
            if self.ui_data['bodyLengthMax'] < (self.ui_data['horizontalPadCount'] - 1) * self.ui_data['horizontalPinPitch'] + self.ui_data['padHeightMax']:
                status.add_error(_LCLZ("HeaderStraightSocketError1", "The pins come out of the body, please check cols, col pitch (d) and D."))
            if self.ui_data['bodyWidthMax'] < (rows - 1) * self.ui_data['verticalPinPitch'] + self.ui_data['padHeightMax']:
                status.add_error(_LCLZ("HeaderStraightSocketError2", "The pins come out of the body, please check rows, row pitch (e) and E."))
            if self.ui_data['terminalTailLength'] < self.ui_data['padHeightMax'] :
                status.add_error(_LCLZ("SMDHeader1", "L1 should be greater than or equal to b."))
            if self.ui_data['terminalTailLength'] >= self.ui_data['bodyHeightMax'] :
                status.add_error(_LCLZ("SMDHeader2", "L should be greater than L1."))

        return status

    def update_ui_data(self, inputs):
        # update date from UI inputs
        input_data = self.get_inputs()
        for param in self.ui_data:
            if param in input_data:
                self.ui_data[param] = input_data[param]
        
        # update the density level
        #self.ui_data['densityLevel'] = list(constant.DENSITY_LEVEL_SMD.values())[inputs.itemById('densityLevel').selectedItem.index]
        self.ui_data['silkscreenMappingTypeToBody'] = list(constant.SILKSCREEN_MAPPING_TO_BODY.values())[inputs.itemById('silkscreenMappingTypeToBody').selectedItem.index]
        self.ui_data['padShape'] = list(constant.SMD_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index]
        self.ui_data['footprintOriginLocation'] = list(FOOTPRINT_LOCATION_TYPES.values())[inputs.itemById('footPrintOrig').selectedItem.index]
        self.ui_data['pinNumberSequencePattern'] = PIN_NUM_SEQUENCE_TYPES[inputs.itemById('pinNumberSequencePattern').selectedItem.index]
        self.ui_data['verticalPadCount'] = list(ROW_TYPES.values())[inputs.itemById('verticalPadCount').selectedItem.index]
        if self.ui_data['type'] != 'surface_mount_pin_header_right_angle' :
            self.ui_data['tailLengthOverride'] = inputs.itemById('tailLengthOverride').isEnabledCheckBoxChecked

    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects()

        # Create a package tab input.
        tab1_cmd_inputs = inputs.addTabCommandInput('tab_1', _LCLZ('package', 'Package'))
        tab1_inputs = tab1_cmd_inputs.children

        # Create image input.
        self.create_package_img(command, tab1_inputs)
        
        # Create a read only textbox input.
        tab1_inputs.addTextBoxCommandInput('readonly_textBox', '', _LCLZ('smdHeaderNote', 
            '* Use the footprint tab to create land-pattern, which will be generated according to the default values otherwise.'), 3, True)

        #Create dropdown for no. of rows
        rows = tab1_inputs.addDropDownCommandInput('verticalPadCount', _LCLZ('#Rows', '# Rows'), adsk.core.DropDownStyles.TextListDropDownStyle)
        row_list = rows.listItems
        for t in ROW_TYPES:
            row_list.add(_LCLZ(t, ROW_TYPES.get(t)), True if ROW_TYPES.get(t) == self.ui_data['verticalPadCount'] else False, '')
        rows.maxVisibleItems = len(ROW_TYPES)

        #Create for no. of columns
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
        if list(ROW_TYPES.values())[inputs.itemById('verticalPadCount').selectedItem.index] == constant.ROW_TYPE_DOUBLE :
            pin_num_input.isVisible = True
        else :
            pin_num_input.isVisible = False

        # Create dropdown input with test list style.
        pad_shape = tab1_inputs.addDropDownCommandInput('padShape', _LCLZ('padShape', 'Pad Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        pad_shape_list = pad_shape.listItems
        for t in constant.SMD_PAD_SHAPE:
            pad_shape_list.add(_LCLZ(t, constant.SMD_PAD_SHAPE.get(t)), True if constant.SMD_PAD_SHAPE.get(t) == self.ui_data['padShape'] else False, '')
        pad_shape.isVisible = not self.only_3d_model_generator
        pad_shape.maxVisibleItems = len(constant.SMD_PAD_SHAPE)

        # create round corner size input
        rounded_corner = tab1_inputs.addIntegerSpinnerCommandInput('roundedPadCornerSize', _LCLZ('padRoundness', 'Pad Roundness (%)'), 1, 100 , 1, int(self.ui_data['roundedPadCornerSize']))
        rounded_corner.isVisible = True if constant.SMD_PAD_SHAPE.get('RoundedRectangle') == self.ui_data['padShape'] else False

        # create pin pitch e
        row_pitch = tab1_inputs.addValueInput('verticalPinPitch', 'e', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['verticalPinPitch']))
        row_pitch.tooltip = _LCLZ('rowPitch', 'Row Pitch')
        # create pin pitch d
        col_pitch = tab1_inputs.addValueInput('horizontalPinPitch', 'd', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['horizontalPinPitch']))
        col_pitch.tooltip = _LCLZ('colPitch', 'Col Pitch')

        # create package specific UIs
        self.create_dimension_ui(command, tab1_inputs)


        # table for inputs
        table = tab1_inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.hasGrid = False
        table.tablePresentationStyle = 2
        table.maximumVisibleRows = 7
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))

        fusion_ui.add_row_to_table(table, 'padHeight', 'b', adsk.core.ValueInput.createByReal(self.ui_data['padHeightMin']), adsk.core.ValueInput.createByReal(self.ui_data['padHeightMax']), _LCLZ('terminalWidth', 'Terminal Width'))
        fusion_ui.add_row_to_table(table, 'bodyLength', 'D', adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMax']),  _LCLZ('bodyLength', 'Body Length'))
        fusion_ui.add_row_to_table(table, 'verticalLeadToLeadSpan', 'E', adsk.core.ValueInput.createByReal(self.ui_data['verticalLeadToLeadSpanMin']), adsk.core.ValueInput.createByReal(self.ui_data['verticalLeadToLeadSpanMax']), _LCLZ('leadSpan1', 'Lead Span 1'))
        if self.ui_data['type'] != 'surface_mount_pin_header_right_angle' :
            fusion_ui.add_row_to_table(table, 'bodyWidth', 'E1', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyWidth', 'Body Width'))
        fusion_ui.add_row_to_table(table, 'bodyHeight', 'L', None, adsk.core.ValueInput.createByReal(self.ui_data['bodyHeightMax']), _LCLZ('bodyHeight', 'Body Height' ))

        # Create dropdown input with test list style.
        map_silkscreen = tab1_inputs.addDropDownCommandInput('silkscreenMappingTypeToBody', _LCLZ('mapSilkscreen', 'Map Silkscreen to Body'), adsk.core.DropDownStyles.TextListDropDownStyle)
        map_silkscreen_list = map_silkscreen.listItems
        for t in constant.SILKSCREEN_MAPPING_TO_BODY:
            map_silkscreen_list.add(_LCLZ(t, constant.SILKSCREEN_MAPPING_TO_BODY.get(t)), True if constant.SILKSCREEN_MAPPING_TO_BODY.get(t) == self.ui_data['silkscreenMappingTypeToBody'] else False, '')
        map_silkscreen.isVisible = not self.only_3d_model_generator
        map_silkscreen.maxVisibleItems = len(constant.SILKSCREEN_MAPPING_TO_BODY)


        #Create custom footprint tab
        if not self.only_3d_model_generator:
            # Create a custom footprint tab input.
            footprint_tab_cmd_inputs = inputs.addTabCommandInput('FootprintTab', _LCLZ('footprint', 'Footprint'))
            custom_footprint_inputs = footprint_tab_cmd_inputs.children
            #enable_custom_footprint = custom_footprint_inputs.addBoolValueInput('hasCustomFootprint', _LCLZ('customFootprint', 'Custom Footprint'), True, '', self.ui_data['hasCustomFootprint'])

            # Create image input.
            custom_footprint_image = custom_footprint_inputs.addImageCommandInput('customSoicImage', '', "Resources/img/SMDHeader-Custom-Footprint.png")
            custom_footprint_image.isFullWidth = True
            custom_footprint_image.isVisible = True

            custom_pad_length = custom_footprint_inputs.addValueInput('customPadLength', 'l',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadLength']))
            custom_pad_length.tooltip = _LCLZ("customPadLength", 'Custom Pad Length')
            custom_pad_width = custom_footprint_inputs.addValueInput('customPadWidth', 'c',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadWidth']))
            custom_pad_width.tooltip = _LCLZ('customPadWidth', 'Custom Pad Width')
            custom_pad_span = custom_footprint_inputs.addValueInput('customPadSpan1', 'z',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['customPadSpan1']))
            custom_pad_span.tooltip = _LCLZ('customPadSpan1', 'Custom Pad Span 1')

            #control visibility for RA header
            vertical_pad_count = list(ROW_TYPES.values())[inputs.itemById('verticalPadCount').selectedItem.index]
            if vertical_pad_count == constant.ROW_TYPE_SINGLE and self.ui_data['type'] == 'surface_mount_pin_header_right_angle' :
                custom_pad_span.isVisible = False

            #to reflect the model param d
            pin_pitch = custom_footprint_inputs.addValueInput('pinPitch', 'd',  ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['horizontalPinPitch']))
            pin_pitch.isEnabled = False
            pin_pitch.tooltip = _LCLZ('pinPitchNote', 'Read-only, edit in the package tab')

    def on_input_changed(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs, changed_input: adsk.core.CommandInput, input_values: dict ):

        if not self.only_3d_model_generator:
            #update e value only when footprint tab visible
            if changed_input.id == 'horizontalPinPitch' :
                inputs.itemById('pinPitch').value = inputs.itemById('horizontalPinPitch').value 

        if changed_input.id == 'padShape':
            pad_shape = list(constant.SMD_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index]
            if pad_shape == constant.SMD_PAD_SHAPE.get("RoundedRectangle"):
                inputs.itemById('roundedPadCornerSize').isVisible = True
            else:
                inputs.itemById('roundedPadCornerSize').isVisible = False

        if changed_input.id == 'verticalPadCount' :
            vertical_pad_count = list(ROW_TYPES.values())[inputs.itemById('verticalPadCount').selectedItem.index]
            if vertical_pad_count == constant.ROW_TYPE_DOUBLE:
                inputs.itemById('pinNumberSequencePattern').isVisible = True
                if not self.only_3d_model_generator :
                    inputs.itemById('customPadSpan1').isVisible = True
            else:
                inputs.itemById('pinNumberSequencePattern').isVisible = False
                #Check for RA header and for 'z' param since 'z' is only available in package mode
                if not self.only_3d_model_generator and self.ui_data['type'] == 'surface_mount_pin_header_right_angle':
                    inputs.itemById('customPadSpan1').isVisible = False
            #set regenrate model for non parametric updates.  
            self.reset_regenerate_flag('verticalPadCount', vertical_pad_count)

    def create_dimension_ui(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        pass

    def create_package_img(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        pass
           