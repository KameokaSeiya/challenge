# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

# this class defines the package Calculator for the ECAP Package.
class PackageCalculatorSod(pkg_calculator.PackageCalculator):
	
	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)

	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass

	# process the data for 3d model generator	
	def get_ipc_3d_model_data(self):
		model_data = {}
		model_data['type'] = self.pkg_type
		model_data['A'] = self.ui_data['bodyHeightMax']
		model_data['A1'] = self.ui_data['bodyOffsetMin']
		model_data['b'] = self.ui_data['padHeightMax']
		model_data['D'] = self.ui_data['horizontalLeadToLeadSpanMax']
		model_data['E'] = self.ui_data['bodyLengthMax']
		model_data['D1'] = self.ui_data['bodyWidthMax']
		model_data['L'] = self.ui_data['padWidthMax']
		return model_data
		
	def get_footprint(self):
		
		footprint_data = []

		toe_goal = ipc_rules.PAD_GOAL_GULLWING['toeFilletMaxMedMinGT'][self.ui_data['densityLevel']]
		heel_goal = ipc_rules.PAD_GOAL_GULLWING['heelFilletMaxMedMinGT'][self.ui_data['densityLevel']]
		side_goal = ipc_rules.PAD_GOAL_GULLWING['sideFilletMaxMedMinGT'][self.ui_data['densityLevel']]

		#calculate the smd data. 
		if self.ui_data['hasCustomFootprint'] :
			pad_width = self.ui_data['customPadLength']
			pad_height = self.ui_data['customPadWidth']
			pin_pitch = self.ui_data['customPadToPadGap'] + self.ui_data['customPadLength']
		else:
			pad_width, pad_height, pin_pitch = self.get_footprint_smd_data1(self.ui_data['horizontalLeadToLeadSpanMax'], self.ui_data['horizontalLeadToLeadSpanMin'],
					self.ui_data['padWidthMax'], self.ui_data['padWidthMin'], self.ui_data['padHeightMax'], self.ui_data['padHeightMin'],
					self.ui_data['bodyWidthMax'], toe_goal, heel_goal, side_goal) 			

		# build the left side smd 
		left_pad = footprint.FootprintSmd(-pin_pitch/2, 0, pad_width, pad_height)
		left_pad.name = 'C'
		left_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(left_pad)

		# build the right side smd
		right_pad = footprint.FootprintSmd(pin_pitch/2, 0, pad_width, pad_height)
		right_pad.name = 'A'
		right_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(right_pad)

		#build the silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])
		stroke_width = ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']
		left_edge_x = left_pad.center_point_x - left_pad.width/2 - ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] - stroke_width/2
		top_edge_y = left_pad.center_point_y + left_pad.height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] + stroke_width/2

		#top side silkscreen
		if top_edge_y < body_length/2:
			top_edge_y = body_length/2

		#top side silkscreen
		line_left = footprint.FootprintWire(left_edge_x, top_edge_y, left_edge_x, -top_edge_y, stroke_width)
		footprint_data.append(line_left)
		line_top = footprint.FootprintWire(left_edge_x, top_edge_y, body_width/2, top_edge_y, stroke_width)
		footprint_data.append(line_top)
		line_bottom = footprint.FootprintWire(left_edge_x, -top_edge_y, body_width/2, -top_edge_y, stroke_width)
		footprint_data.append(line_bottom)

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'],stroke_width)

		#build the text
		self.build_footprint_text(footprint_data, 0)

		return footprint_data

	def get_ipc_package_name(self):
		#name + Lead Span Nominal + Body Width Nominal X Body Height Max

		span_nom = int(((self.ui_data['horizontalLeadToLeadSpanMax'] * 1000 + self.ui_data['horizontalLeadToLeadSpanMin'] * 1000 )/20))
		if span_nom < 10:
			span_str = '0' + str(span_nom)
		else:
			span_str = str(span_nom)

		body_length_nom = int(((self.ui_data['bodyLengthMax'] * 1000 + self.ui_data['bodyLengthMin'] * 1000 )/20))
		if body_length_nom < 10:
			body_length_str = '0' + str(body_length_nom)
		else:
			body_length_str = str(body_length_nom)

		pkg_name = 'SOD' + span_str + body_length_str + 'X'
		pkg_name += str(int((self.ui_data['bodyHeightMax']*1000))) 
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])

		return pkg_name

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		lead_span = ao.units_manager.convert((self.ui_data['horizontalLeadToLeadSpanMax']+self.ui_data['horizontalLeadToLeadSpanMin'])/2, 'cm', unit)

		short_description = 'SOD, '
		short_description += str('{:.2f}'.format(round(lead_span,2))) + ' ' + unit + ' span, '
		short_description += self.get_body_description(True,False) + unit + ' body'
			
		full_description = 'SOD package with '
		full_description += str('{:.2f}'.format(round(lead_span,2))) + ' ' + unit + ' span'
		full_description += self.get_body_description(False,False) + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		isPackageRotated = True
		super().get_ipc_package_metadata(isPackageRotated)
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "SOD"
		self.metadata['leadSpan'] = str(round(ao.units_manager.convert((self.ui_data['horizontalLeadToLeadSpanMax']+self.ui_data['horizontalLeadToLeadSpanMin'])/2, 'cm', 'mm'), 4))
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_SOD, PackageCalculatorSod) 