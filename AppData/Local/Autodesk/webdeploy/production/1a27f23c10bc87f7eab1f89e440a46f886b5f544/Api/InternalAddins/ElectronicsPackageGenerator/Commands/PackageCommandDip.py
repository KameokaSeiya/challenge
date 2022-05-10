import traceback
import adsk.core
import os, sys
from pathlib import Path
from . import PackageCommand
from .import PackageCommandDualInLine
from ..Utilities import addin_utility, fusion_ui, constant
from ..Utilities.localization import _LCLZ

class PackageCommandDip(PackageCommandDualInLine.PackageCommandDualInLine):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_dip'
        self.cmd_name = _LCLZ('CmdNameDip', 'DIP Generator')
        self.cmd_description = _LCLZ('CmdDescDip', 'Generate DIP Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 330
        self.dialog_height = 700

    def get_defalt_ui_data(self):
        #default parameters
        ui_data = super().get_defalt_ui_data()
        ui_data['cmd_id'] = self.cmd_id
        ui_data['type'] = constant.PKG_TYPE_DIP
        ui_data['leadSpan'] = 0.762
        ui_data['bodyWidthMax'] = 0.66
        ui_data['bodyWidthMin'] = 0.66
        ui_data['customPadDiameter'] = 0.134
        ui_data['customHoleDiameter'] = 0.074

        return ui_data
        
    def create_package_img(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        # Create image input.
        labeled_image = inputs.addImageCommandInput('DipImage', '', "Resources/img/DIP-Labeled.png")
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

# register the command into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_DIP, PackageCommandDip)
