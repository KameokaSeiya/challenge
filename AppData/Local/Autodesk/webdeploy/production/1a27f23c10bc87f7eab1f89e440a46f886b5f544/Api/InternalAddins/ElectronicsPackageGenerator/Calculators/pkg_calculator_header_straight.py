# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules
from ..Calculators import pkg_calculator_header

# this class defines the package Calculator for the Header Straight Packages.
class PackageCalculatorHeaderStraight(pkg_calculator_header.PackageCalculatorHeader):
	
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
		model_data['E'] = self.ui_data['bodyWidthMax']
		model_data['L'] = self.ui_data['bodyHeightMax']
		model_data['L1'] = self.ui_data['terminalTailLength']
		model_data['L2'] = self.ui_data['terminalPostLength']
		return model_data

	def get_footprint(self):
		
		footprint_data = []
		# build footprint pads 
		self.build_footprint_pads(footprint_data)
		
		# get the first pad
		first_pad = footprint_data[0]
		
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])

		#adjust the body width in case body outline edge is placed with minimum clearence from pads
		if self.ui_data['bodyWidthMax'] < (self.ui_data['verticalPadCount'] - 1)* self.ui_data['verticalPinPitch'] + first_pad.diameter + 2*ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']:
			body_width = (self.ui_data['verticalPadCount'] - 1)* self.ui_data['verticalPinPitch'] + first_pad.diameter + 2*ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']
		if self.ui_data['bodyLengthMax'] < (self.ui_data['horizontalPadCount'] - 1)* self.ui_data['horizontalPinPitch'] + first_pad.diameter +2*ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']:
			body_length = (self.ui_data['horizontalPadCount'] - 1)* self.ui_data['horizontalPinPitch'] + first_pad.diameter + 2*ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']
		
		body_offset_x = 0
		body_offset_y = 0
		# calculate the body offset from the original based on the footprint location and pin sequence pattern
		if self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_PIN1:
			body_offset_x = self.ui_data['horizontalPinPitch'] * (self.ui_data['horizontalPadCount'] - 1) / 2
			if self.ui_data['pinNumberSequencePattern'] == 'LRCW': # pin on is Top Left
				body_offset_y = -(self.ui_data['verticalPadCount'] - 1)* self.ui_data['verticalPinPitch']/2
			else: # pin one is Bottom Left
				body_offset_y = (self.ui_data['verticalPadCount'] - 1)* self.ui_data['verticalPinPitch']/2

		self.build_silkscreen_body_outline(footprint_data, body_width, body_length, body_offset_x, body_offset_y)

		#build pin one marker
		pin_marker_size = ipc_rules.SILKSCREEN_ATTRIBUTES['dotPinMarkerSize']
		clearance = ipc_rules.SILKSCREEN_ATTRIBUTES['PinMarkerDotClearance'] + pin_marker_size/2

		pin_marker_x = first_pad.center_point_x

		if self.ui_data['pinNumberSequencePattern'] == 'LRCW': # pin one is Top Left. build marker on top
			pad_y = first_pad.center_point_y + first_pad.diameter/2
			text_offset_y = body_offset_y + (ipc_rules.SILKSCREEN_ATTRIBUTES['PinMarkerDotClearance'] + pin_marker_size)/2
			if (body_width/2 + body_offset_y) > pad_y:
				pin_marker_y = body_width/2 + body_offset_y + clearance
			else : 
				pin_marker_y = pad_y + clearance
		else: #pin one is bottome, build marker at bottom 
			pad_y = first_pad.center_point_y - first_pad.diameter/2
			text_offset_y = body_offset_y - (ipc_rules.SILKSCREEN_ATTRIBUTES['PinMarkerDotClearance'] + pin_marker_size)/2
			if (body_offset_y - body_width/2) < pad_y:
				pin_marker_y = body_offset_y - body_width/2 - clearance
			else : 
				pin_marker_y = pad_y - clearance

		pin_marker = footprint.FootprintCircle(pin_marker_x, pin_marker_y, 0, pin_marker_size/2)
		footprint_data.append(pin_marker)

		#build text
		self.build_footprint_text(footprint_data, 0)

		return footprint_data

	def get_ipc_package_name(self):
		package_name = 'HDRV'
		return super().get_ipc_package_name(package_name)
		
	def get_ipc_package_description(self):
		family_name = 'Pin Header (Male) Straight'
		return super().get_ipc_package_description(family_name)

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_HEADER_STRAIGHT, PackageCalculatorHeaderStraight) 