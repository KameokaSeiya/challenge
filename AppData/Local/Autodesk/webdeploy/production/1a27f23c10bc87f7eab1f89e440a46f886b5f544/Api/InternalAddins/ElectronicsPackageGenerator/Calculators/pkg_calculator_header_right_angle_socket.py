# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules
from ..Calculators import pkg_calculator_header

# this class defines the package Calculator for the Header Right Angle Socket Packages.
class PackageCalculatorHeaderRightAngleSocket(pkg_calculator_header.PackageCalculatorHeader):
	
	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)

	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass

	# process the data for 3d model generator	
	def get_ipc_3d_model_data(self):
		model_data = super().get_ipc_3d_model_data()
		model_data['E'] = self.ui_data['bodyHeightMax']
		model_data['L'] = self.ui_data['bodyWidthMax']
		model_data['L1'] = self.ui_data['horizontalTerminalTailLength']
		model_data['L2'] = self.ui_data['verticalTerminalTailLength']
		return model_data

	def get_footprint(self):
		
		footprint_data = []
		# build footprint pads 
		self.build_footprint_pads(footprint_data)

		# get the first pad
		first_pad = footprint_data[0]
		# draw the pin on marker
		self.build_silkscreen_pin_one_marker(footprint_data,first_pad.center_point_x, first_pad.center_point_y, first_pad.diameter, first_pad.diameter, 0, True)
		

		#build body silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])
		#adjust the body width in case body outline edge is placed with minimum clearence from pads
		if self.ui_data['horizontalTerminalTailLength'] < first_pad.diameter/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']:
			body_width = body_width - (first_pad.diameter/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] - self.ui_data['horizontalTerminalTailLength'])
		# keep value of gap we leave for pad clearance
		clearance_gap = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody']) - body_width

		body_offset_x = 0
		body_offset_y = 0
		# calculate the body offset from the original based on the footprint location and pin sequence pattern
		if self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_CENTER:
			body_offset_x = 0
			body_offset_y = - ((self.ui_data['verticalPadCount'] - 1)* self.ui_data['verticalPinPitch']/2 + self.ui_data['horizontalTerminalTailLength'] + body_width/2)

		elif self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_PIN1:
			body_offset_x = self.ui_data['horizontalPinPitch'] * (self.ui_data['horizontalPadCount'] - 1) / 2
			if self.ui_data['pinNumberSequencePattern'] == 'LRCW': # pin on is Top Left
				body_offset_y = - ((self.ui_data['verticalPadCount'] - 1)* self.ui_data['verticalPinPitch'] + self.ui_data['horizontalTerminalTailLength'] + body_width/2)
			else: # pin one is Bottom Left
				body_offset_y = -(self.ui_data['horizontalTerminalTailLength'] + body_width/2)
		# apply the clearance gap to the offset.
		body_offset_y = body_offset_y - clearance_gap

		self.build_silkscreen_body_outline(footprint_data, body_width, body_length, body_offset_x, body_offset_y)
	
		#build the text
		self.build_footprint_text(footprint_data, 0)
		
		return footprint_data

	def get_ipc_package_name(self):
		package_name = 'HDRRAR'
		return super().get_ipc_package_name(package_name)

	def get_ipc_package_description(self):
		family_name ='Receptacle Header (Female) Right Angle'
		return super().get_ipc_package_description(family_name)
		
# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_HEADER_RIGHT_ANGLE_SOCKET, PackageCalculatorHeaderRightAngleSocket) 