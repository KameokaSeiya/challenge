import adsk.core
from ..Commands import PackageCommand
from ..Utilities import addin_utility,fusion_ui, constant, pkg_command_utility
from ..Utilities.localization import _LCLZ


class PackageCommandSnaplock(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_Snaplock'
        self.cmd_name = _LCLZ('CmdNameSnaplock', 'Snap Lock Generator')
        self.cmd_description = _LCLZ('CmdDescSnaplock', 'Generate Snap Lock Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 300
        self.dialog_height = 540 

    def get_defalt_ui_data(self):
        ui_data = {}
        ui_data['cmd_id'] = self.cmd_id
        ui_data['type'] = constant.PKG_TYPE_SNAP_LOCK
        ui_data['horizontalPadCount'] = 1     
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY.get('MappingTypeToBodyNom')
        ui_data['bodyHeightMax'] = 0.813
        ui_data['bodyLengthMax'] = 0.46
        ui_data['bodyLengthMin'] = 0.46
        ui_data['bodyWidthMax'] = 0.46
        ui_data['bodyWidthMin'] = 0.46
        ui_data['lockHeightMax'] = 0.2
        ui_data['lockHeightMin'] = 0.2
        ui_data['boardThickness'] = 0.16

        ui_data['lockWidthOverride'] = False
        ui_data['holeDiameter'] = 0.32
        ui_data['lockWidth'] = 0.38
        return ui_data

    def validate_ui_input(self, inputs: adsk.core.CommandInputs):

        status = super().validate_ui_input(inputs)
        #input field related check
        pkg_command_utility.ensure_positive_value('boardThickness', inputs, status)
        pkg_command_utility.ensure_positive_value('holeDiameter', inputs, status)

        if inputs.itemById('lockWidthOverride').isEnabledCheckBoxChecked :
            pkg_command_utility.ensure_positive_value('lockWidth', inputs, status)

        #calculation related check
        if addin_utility.get_float_data(self,'holeDiameter') == addin_utility.get_float_data(self,'bodyWidthMax') :
            status.add_error(_LCLZ("SnapLockError1", "b should not be equal to E."))
        if self.ui_data['lockWidthOverride']!= None :
            if addin_utility.get_float_data(self,'holeDiameter') == addin_utility.get_float_data(self,'lockWidth') :
                status.add_error(_LCLZ("SnapLockError2", "b should not be equal to E1."))
        
        return status

    def update_ui_data(self, inputs):
        # update date from UI inputs
        input_data = self.get_inputs()
        for param in self.ui_data:
            if param in input_data:
                self.ui_data[param] = input_data[param]

        self.ui_data['lockWidthOverride'] = inputs.itemById('lockWidthOverride').isEnabledCheckBoxChecked

    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects() 
        # Create image input.
        labeled_image = inputs.addImageCommandInput('SnaplockImage', '', "Resources/img/Snap-Lock-Labeled.png")
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

        # Create a read only textbox input.
        inputs.addTextBoxCommandInput('readonly_textBox', '', _LCLZ('snaplockNote', '* Lock diameter (E1) is automatically calculated based on the body diameter (E) and hole diameter (b). However you can provide custom value by overriding the lock diameter.'), 5, True)
    
        # table
        table = inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.hasGrid = False
        table.tablePresentationStyle = 2
        table.maximumVisibleRows = 4
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))
        fusion_ui.add_row_to_table(table, 'bodyHeight', 'A', None, adsk.core.ValueInput.createByReal(self.ui_data['bodyHeightMax']), _LCLZ('bodyHeight', 'Body Height'))
        fusion_ui.add_row_to_table(table, 'bodyWidth', 'E', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyDiameter', 'Body Diameter'))
        fusion_ui.add_row_to_table(table, 'lockHeight', 'L1', adsk.core.ValueInput.createByReal(self.ui_data['lockHeightMin']), adsk.core.ValueInput.createByReal(self.ui_data['lockHeightMax']), _LCLZ('lockHeight', 'Lock Height'))

        board_thickness = inputs.addValueInput('boardThickness', 'A1', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['boardThickness']))
        board_thickness.tooltip = _LCLZ('boardThickness', 'Board Thickness')
        hole_dia = inputs.addValueInput('holeDiameter', 'b', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['holeDiameter']))
        hole_dia.tooltip = _LCLZ('holeDiameter', 'Hole Diameter')

        # Create group input.
        groupCmdInput = inputs.addGroupCommandInput('lockWidthOverride', _LCLZ('lockWidthOverride', 'Override Lock Diameter'))
        groupCmdInput.isExpanded = True
        groupCmdInput.isEnabledCheckBoxDisplayed = True
        groupCmdInput.isEnabledCheckBoxChecked = self.ui_data['lockWidthOverride']
        groupChildInputs = groupCmdInput.children

        lock_diameter = groupChildInputs.addValueInput('lockWidth', 'E1', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['lockWidth']))
        lock_diameter.tooltip = _LCLZ('lockDiameter', 'Lock Diameter')

# register the command into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_SNAP_LOCK, PackageCommandSnaplock)