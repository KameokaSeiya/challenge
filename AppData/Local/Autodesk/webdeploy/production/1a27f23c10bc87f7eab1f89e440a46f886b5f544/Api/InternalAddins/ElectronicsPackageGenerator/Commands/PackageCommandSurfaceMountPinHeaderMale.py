import adsk.core
from . import PackageCommand
from . import PackageCommandSurfaceMountHeader
from ..Utilities import addin_utility, fusion_ui, constant
from ..Utilities.localization import _LCLZ

class PackageCommandSurfaceMountPinHeaderMale(PackageCommandSurfaceMountHeader.PackageCommandSurfaceMountHeader):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_surface_mount_pin_header_male'
        self.cmd_name = _LCLZ('CmdNameSurfaceMountPinHeaderMale', 'Surface Mount Pin Header (Male) Straight Generator')
        self.cmd_description = _LCLZ('CmdDescSurfaceMountPinHeaderMale', 'Generate Surface Mount Pin Header (Male) Straight Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 310
        self.dialog_height = 630 

    def get_defalt_ui_data(self):
        #default parameters
        ui_data = super().get_defalt_ui_data()
        ui_data['type'] = constant.PKG_TYPE_SMD_HEADER_STRAIGHT
        ui_data['cmd_id'] = self.cmd_id

        ui_data['bodyLengthMin'] = 1.016
        ui_data['bodyLengthMax'] = 1.016
        ui_data['bodyWidthMin'] = 0.508
        ui_data['bodyWidthMax'] = 0.508
        ui_data['verticalLeadToLeadSpanMin'] = 0.736
        ui_data['verticalLeadToLeadSpanMax'] = 0.736
        ui_data['bodyHeightMax'] = 0.381
        ui_data['terminalTailLength'] = 0.111
        ui_data['terminalPostLength'] = 0.584
        ui_data['customPadLength'] = 0.318
        ui_data['customPadWidth'] = 0.06
        ui_data['customPadSpan1'] = 0.8

        return ui_data

    def create_package_img(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        # Create image input.
        labeled_image = inputs.addImageCommandInput('SMDHeaderFemaleStraightImage', '', 'Resources/img/SMD-Header-Male-Straight-Labeled.png')
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

    def create_dimension_ui(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):

        ao = addin_utility.AppObjects()

        #Create input for L2
        post_length = inputs.addValueInput('terminalPostLength', 'L2', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['terminalPostLength']))
        post_length.tooltip = _LCLZ('terminalPostLength', 'Terminal Post Length')

        # Create group inputfor L1
        groupCmdInput = inputs.addGroupCommandInput('tailLengthOverride', _LCLZ('overrideTailLength', 'Override Tail Length (L1)'))
        groupCmdInput.isExpanded = True
        groupCmdInput.isEnabledCheckBoxDisplayed = True
        groupCmdInput.isEnabledCheckBoxChecked = self.ui_data['tailLengthOverride']
        groupChildInputs = groupCmdInput.children

        tail_length = groupChildInputs.addValueInput('terminalTailLength', 'L1', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['terminalTailLength']))
        tail_length.tooltip = _LCLZ('terminalTailLength', 'Terminal Tail Length')

# register the calculator into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_SMD_HEADER_STRAIGHT, PackageCommandSurfaceMountPinHeaderMale) 
           