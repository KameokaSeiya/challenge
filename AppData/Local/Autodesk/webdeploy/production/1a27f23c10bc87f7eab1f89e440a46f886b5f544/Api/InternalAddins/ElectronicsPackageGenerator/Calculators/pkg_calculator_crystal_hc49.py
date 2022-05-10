# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

# this class defines the package Calculator for the Axial Packages.
class PackageCalculatorCrystalHC49(pkg_calculator.PackageCalculator):
	
	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)
		self.pkg_type = constant.PKG_TYPE_CRYSTAL_HC49

	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass                 
	
	# process the data for 3d model generator	
	def get_ipc_3d_model_data(self):
		model_data = {}
		model_data['type'] = self.pkg_type
		model_data['A'] = self.ui_data['bodyHeightMax']
		model_data['E'] = self.ui_data['bodyLengthMax']
		model_data['D'] = self.ui_data['bodyWidthMax']
		model_data['b'] = self.ui_data['terminalWidth']
		model_data['e'] = self.ui_data['verticalPinPitch']	
		return model_data

	def get_footprint(self):
		
		footprint_data = []
		# get the pin pitch
		pin_pitch = self.ui_data['verticalPinPitch']	
		
		if self.ui_data['hasCustomFootprint'] :
			drill_size = self.ui_data['customHoleDiameter']
			pad_diameter = self.ui_data['customPadDiameter']
		else:
			drill_size = self.get_footprint_pad_drill_size(self.ui_data['densityLevel'],self.ui_data['terminalWidth'])
			pad_diameter = self.get_footprint_pad_diameter(self.ui_data['densityLevel'],self.ui_data['terminalWidth'],self.ui_data['padToHoleRatio'])

		# initiate the left pad data 
		left_pad = footprint.FootprintPad(-pin_pitch/2, 0, pad_diameter, drill_size)
		left_pad.name = '1'
		left_pad.shape = self.ui_data['padShape']	
		footprint_data.append(left_pad)

		# initiate the right pad data 
		right_pad = footprint.FootprintPad(pin_pitch/2, 0, pad_diameter, drill_size)
		right_pad.name = '2'
		right_pad.shape = self.ui_data['padShape']
		footprint_data.append(right_pad)

		#build the silkscreen . the shape is not rectagle. 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])

		circle_left = footprint.FootprintWire(-(body_width- body_length) /2, body_length/2, -(body_width - body_length) /2, - body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		circle_left.curve = 180
		footprint_data.append(circle_left)

		circle_right = footprint.FootprintWire((body_width - body_length) /2, body_length/2, (body_width - body_length) /2, - body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		circle_right.curve = -180
		footprint_data.append(circle_right)

		line_top = footprint.FootprintWire(-(body_width - body_length) /2, body_length/2, (body_width - body_length) /2, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_top)

		line_bottom = footprint.FootprintWire(-(body_width - body_length) /2, -body_length/2, (body_width - body_length) /2, - body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_bottom)

		# build assembly out line. which will take the max value of the outline
		body_width = self.ui_data['bodyWidthMax']
		body_length = self.ui_data['bodyLengthMax']

		circle_left_b = footprint.FootprintWire(-(body_width - body_length) /2, body_length/2, -(body_width - body_length) /2, - body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		circle_left_b.curve = 180
		circle_left_b.layer = 51
		footprint_data.append(circle_left_b)

		circle_right_b = footprint.FootprintWire((body_width - body_length) /2, body_length/2, (body_width - body_length) /2, - body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		circle_right_b.curve = -180
		circle_right_b.layer = 51
		footprint_data.append(circle_right_b)

		line_top_b = footprint.FootprintWire(-(body_width - body_length) /2, body_length/2, (body_width - body_length) /2, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		line_top_b.layer = 51
		footprint_data.append(line_top_b)

		line_bottom_b = footprint.FootprintWire(-(body_width - body_length) /2, -body_length/2, (body_width - body_length) /2, - body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		line_bottom_b.layer = 51
		footprint_data.append(line_bottom_b)

		#build the text
		self.build_footprint_text(footprint_data, 0)

		return footprint_data

	def get_ipc_package_name(self):
		#XTALRR + lead spacing + W lead width + L Body Length + T Body Width + Body Height
		pkg_name = 'XTALRR'  
		pkg_name += str(int((self.ui_data['verticalPinPitch']*1000))) 
		pkg_name += 'W' + str(int((self.ui_data['terminalWidth']*1000))) 
		pkg_name += 'L' + str(int(((self.ui_data['bodyWidthMax'] * 1000 +self.ui_data['bodyWidthMin'] * 1000)/2))) 
		pkg_name += 'T' + str(int(((self.ui_data['bodyLengthMax'] * 1000 +self.ui_data['bodyLengthMin'] * 1000 )/2)))
		pkg_name += 'H' + str(int((self.ui_data['bodyHeightMax']*1000))) 
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_producibility_level_for_pth(self.ui_data['densityLevel'])		
		return pkg_name
		
	def get_ipc_package_description(self):
		
		ao = addin_utility.AppObjects()
		unit = 'mm'	
		# get the pin pitch
		pin_pitch = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm')
		terminal_width = ao.units_manager.convert(self.ui_data['terminalWidth'], 'cm', 'mm')

		short_description = 'Crystal (HC49), '
		short_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		short_description += self.get_body_description(True, False) + unit + ' body'

		full_description = 'Crystal (HC49) package'
		full_description += ' with ' + str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch (lead spacing) and '
		full_description += str('{:.2f}'.format(round(terminal_width,2))) + ' ' + unit + ' lead diameter'
		full_description += self.get_body_description(False, False) + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		isPackageRotated = True
		super().get_ipc_package_metadata(isPackageRotated)
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "CRYSTAL"
		self.metadata["pitch"] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'),4))
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_CRYSTAL_HC49, PackageCalculatorCrystalHC49) 