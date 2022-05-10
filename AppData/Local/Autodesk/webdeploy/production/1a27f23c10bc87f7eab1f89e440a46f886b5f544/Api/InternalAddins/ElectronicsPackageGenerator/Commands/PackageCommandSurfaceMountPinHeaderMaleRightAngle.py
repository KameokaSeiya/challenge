import adsk.core
from . import PackageCommand
from . import PackageCommandSurfaceMountHeader
from ..Utilities import addin_utility, fusion_ui, constant
from ..Utilities.localization import _LCLZ

class PackageCommandSurfaceMountPinHeaderMaleRightAngle(PackageCommandSurfaceMountHeader.PackageCommandSurfaceMountHeader):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_surface_mount_pin_header_male_right_angle'
        self.cmd_name = _LCLZ('CmdNameSurfaceMountPinHeaderMaleRightAngle', 'Surface Mount Pin Header (Male) Right Angle Generator')
        self.cmd_description = _LCLZ('CmdDescSurfaceMountPinHeaderMaleRightAngle', 'Generate Surface Mount Pin Header (Male) Right Angle Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 310
        self.dialog_height = 630 

    def get_defalt_ui_data(self):
        #default parameters
        ui_data = super().get_defalt_ui_data()
        ui_data['type'] = constant.PKG_TYPE_SMD_HEADER_RIGHT_ANGLE
        ui_data['cmd_id'] = self.cmd_id

        ui_data['bodyLengthMin'] = 1.016
        ui_data['bodyLengthMax'] = 1.016
        ui_data['bodyWidthMin'] = 0.508
        ui_data['bodyWidthMax'] = 0.508
        ui_data['verticalLeadToLeadSpanMin'] = 0.736
        ui_data['verticalLeadToLeadSpanMax'] = 0.736
        ui_data['bodyHeightMax'] = 0.381
        ui_data['terminalTailLength1'] = 0.4
        ui_data['terminalTailLength2'] = 0.8
        ui_data['terminalPostLength'] = 0.584
        ui_data['customPadLength'] = 0.28
        ui_data['customPadWidth'] = 0.06
        ui_data['customPadSpan1'] = 0.60

        return ui_data

    def validate_ui_input(self, inputs: adsk.core.CommandInputs):

        status = super().validate_ui_input(inputs)
        if self.ui_data['verticalPadCount'] == 'Single Row':
            rows = 1
        else :
            rows = 2
        #calculation related check
        if self.ui_data['bodyLengthMax'] < (self.ui_data['horizontalPadCount'] - 1) * self.ui_data['horizontalPinPitch'] + self.ui_data['padHeightMax']:
            status.add_error(_LCLZ("HeaderStraightSocketError1", "The pins come out of the body, please check cols, col pitch (d) and D."))
        if self.ui_data['verticalLeadToLeadSpanMax'] < (rows - 1) * self.ui_data['verticalPinPitch'] + self.ui_data['padHeightMax']:
            status.add_error(_LCLZ("HeaderStraightSocketError2", "The pins come out of the body, please check rows, row pitch (e) and E."))
        if self.ui_data['terminalTailLength1'] <= self.ui_data['padHeightMax'] :
            status.add_error(_LCLZ("SMDRightHeader1", "L1 should be greater than b."))
        if self.ui_data['terminalTailLength2'] <= self.ui_data['padHeightMax'] :
            status.add_error(_LCLZ("SMDRightHeader2", "L3 should be greater than b."))
        if self.ui_data['terminalTailLength2'] <= self.ui_data['terminalTailLength1'] :
            status.add_error(_LCLZ("SMDRightHeader3", "L3 should be greater than L1."))


        return status

    def create_package_img(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        # Create image input.
        labeled_image = inputs.addImageCommandInput('SMDHeaderFemaleStraightImage', '', 'Resources/img/SMD-Header-Male-Right-Angle-Labeled.png')
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

    def create_dimension_ui(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):

        ao = addin_utility.AppObjects()

        #Create input for L1
        tail_length1 = inputs.addValueInput('terminalTailLength1', 'L1', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['terminalTailLength1']))
        tail_length1.tooltip = _LCLZ('terminalTailLength1', 'Terminal Tail Length 1')

        #Create input for L2
        post_length = inputs.addValueInput('terminalPostLength', 'L2', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['terminalPostLength']))
        post_length.tooltip = _LCLZ('terminalPostLength', 'Terminal Post Length')

        #Create input for L3
        tail_length2 = inputs.addValueInput('terminalTailLength2', 'L3', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['terminalTailLength2']))
        tail_length2.tooltip = _LCLZ('terminalTailLength2', 'Terminal Tail Length 2')

# register the calculator into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_SMD_HEADER_RIGHT_ANGLE, PackageCommandSurfaceMountPinHeaderMaleRightAngle) 
           