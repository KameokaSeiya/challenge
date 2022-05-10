import adsk.core
from . import PackageCommandHeader
from . import PackageCommand
from ..Utilities import addin_utility,fusion_ui, constant
from ..Utilities.localization import _LCLZ


class PackageCommandHeaderRightAngleSocket(PackageCommandHeader.PackageCommandHeader):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_header_right_angle_socket'
        self.cmd_name = _LCLZ('CmdNameHeaderRightAngleSocket', 'Receptacle Header(Female) Right Angle Generator')
        self.cmd_description = _LCLZ('CmdDescHeaderRightAngleSocket', 'Generate Receptacle Header(Female) Right Angle Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 330
        self.dialog_height = 760 

   
    def get_defalt_ui_data(self):
        #default parameters
        ui_data = super().get_defalt_ui_data()
        ui_data['cmd_id'] = self.cmd_id
        ui_data['type'] = constant.PKG_TYPE_HEADER_RIGHT_ANGLE_SOCKET
        ui_data['bodyHeightMin'] = 0
        ui_data['bodyHeightMax'] = 0.556
        ui_data['bodyWidthMax'] = 0.736
        ui_data['bodyWidthMin'] = 0.736
        ui_data['bodyLengthMax'] = 1.016
        ui_data['bodyLengthMin'] = 1.016
        ui_data['horizontalTerminalTailLength'] = 0.152
        ui_data['verticalTerminalTailLength'] = 0.3
        return ui_data

    def validate_ui_input(self, inputs: adsk.core.CommandInputs):

        status = super().validate_ui_input(inputs)
        
        #calculation related check
        if self.ui_data['bodyHeightMax'] < (self.ui_data['verticalPadCount'] - 1) * self.ui_data['verticalPinPitch'] + self.ui_data['terminalWidth']:
            status.add_error(_LCLZ("HeaderStraightSocketError2", "The pins come out of the body, please check rows, row pitch (e) and E."))

        return status

    def on_input_changed(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs, changed_input: adsk.core.CommandInput, input_values: dict ):
        super().on_input_changed(command, inputs, changed_input, input_values)
        if changed_input.id == 'verticalPadCount':
            self.reset_regenerate_flag('verticalPadCount', inputs.itemById('verticalPadCount').value)

    def create_package_img(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        labeled_image = inputs.addImageCommandInput('PinHeaderRightAngleSocketImage', '', "Resources/img/Header-Female-Right-Angle-Labeled.png")
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True
    
    def create_dimension_ui(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):

        ao = addin_utility.AppObjects()
        # create parameters
        terminal_width = inputs.addValueInput('terminalWidth', 'b', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['terminalWidth']))
        terminal_width.tooltip = _LCLZ('terminalWidth', 'Terminal Width')
        hor_tail_length = inputs.addValueInput('horizontalTerminalTailLength', 'L1', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['horizontalTerminalTailLength']))
        hor_tail_length.tooltip = _LCLZ('hTerminalTailLength', 'Horizontal Terminal Tail Length')
        ver_tail_length = inputs.addValueInput('verticalTerminalTailLength', 'L2', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['verticalTerminalTailLength']))
        ver_tail_length.tooltip = _LCLZ('vTerminalTailLength', 'Vertical Terminal Tail Length')
        # table
        table = inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.hasGrid = False
        table.tablePresentationStyle = 2
        table.maximumVisibleRows = 4
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))
        fusion_ui.add_row_to_table(table, 'bodyLength', 'D', adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyLengthMax']), _LCLZ('bodyLength', 'Body Length'))
        fusion_ui.add_row_to_table(table, 'bodyWidth', 'L', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyWidth', 'Body Width'))
        fusion_ui.add_row_to_table(table, 'bodyHeight', 'E', adsk.core.ValueInput.createByReal(self.ui_data['bodyHeightMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyHeightMax']), _LCLZ('bodyHeight', 'Body Height'))

    def create_custom_footprint_img(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        custom_footprint_image = inputs.addImageCommandInput('customRAHeaderImage', '', 'Resources/img/Right-Angle-Header-Custom-Footprint.png')
        custom_footprint_image.isFullWidth = True
        custom_footprint_image.isVisible = True

# register the calculator into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_HEADER_RIGHT_ANGLE_SOCKET, PackageCommandHeaderRightAngleSocket) 
           