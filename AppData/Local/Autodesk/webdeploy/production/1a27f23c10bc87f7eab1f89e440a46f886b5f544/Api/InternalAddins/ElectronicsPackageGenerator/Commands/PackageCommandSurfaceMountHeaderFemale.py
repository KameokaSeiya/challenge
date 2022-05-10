import traceback
import adsk.core
import os, sys
from pathlib import Path
from . import PackageCommand
from .import PackageCommandSurfaceMountHeader
from ..Utilities import addin_utility, fusion_ui, constant
from ..Utilities.localization import _LCLZ

class PackageCommandSurfaceMountHeaderFemale(PackageCommandSurfaceMountHeader.PackageCommandSurfaceMountHeader):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_surafce_mount_header_female'
        self.cmd_name = _LCLZ('CmdNameSurfaceMountHeaderFemale', 'Surface Mount Receptacle Header (Female) Straight Generator')
        self.cmd_description = _LCLZ('CmdDescSurfaceMountHeaderFemale', 'Generate Surface Mount Receptacle Header (Female) Straight Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 310
        self.dialog_height = 630 

    def get_defalt_ui_data(self):
        #default parameters
        ui_data = super().get_defalt_ui_data()
        ui_data['type'] = constant.PKG_TYPE_SMD_HEADER_SOCKET
        ui_data['cmd_id'] = self.cmd_id
        ui_data['bodyLengthMin'] = 1.20
        ui_data['bodyLengthMax'] = 1.20
        ui_data['bodyWidthMin'] = 0.419
        ui_data['bodyWidthMax'] = 0.429
        ui_data['verticalLeadToLeadSpanMin'] = 0.533
        ui_data['verticalLeadToLeadSpanMax'] = 0.533
        ui_data['bodyHeightMax'] = 0.555
        ui_data['terminalTailLength'] = 0.111
        ui_data['customPadLength'] = 0.22
        ui_data['customPadWidth'] = 0.06
        ui_data['customPadSpan1'] = 0.6
        return ui_data

    def create_package_img(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        # Create image input.
        labeled_image = inputs.addImageCommandInput('SMDHeaderFemaleStraightImage', '', 'Resources/img/SMD-Header-Female-Straight-Labeled.png')
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

    def create_dimension_ui(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):

        ao = addin_utility.AppObjects()
        # Create group inputfor L1
        groupCmdInput = inputs.addGroupCommandInput('tailLengthOverride', _LCLZ('overrideTailLength', 'Override Tail Length (L1)'))
        groupCmdInput.isExpanded = True
        groupCmdInput.isEnabledCheckBoxDisplayed = True
        groupCmdInput.isEnabledCheckBoxChecked = self.ui_data['tailLengthOverride']
        groupChildInputs = groupCmdInput.children

        tail_length = groupChildInputs.addValueInput('terminalTailLength', 'L1', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['terminalTailLength']))
        tail_length.tooltip = _LCLZ('terminalTailLength', 'Terminal Tail Length')

# register the calculator into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_SMD_HEADER_SOCKET, PackageCommandSurfaceMountHeaderFemale) 
           