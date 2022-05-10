# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

# this class defines the package Calculator for the ECAP Package.
class PackageCalculatorQfn(pkg_calculator.PackageCalculator):
	
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
		model_data['E'] = self.ui_data['bodyLengthMax']
		model_data['b'] = self.ui_data['padHeightMax']
		model_data['D'] = self.ui_data['bodyWidthMax']
		model_data['e'] = self.ui_data['verticalPinPitch']
		model_data['L'] = (self.ui_data['padWidthMax'] + self.ui_data['padWidthMin'])/2
		model_data['EPins'] = self.ui_data['horizontalPadCount']
		model_data['DPins'] = self.ui_data['verticalPadCount']
		if self.ui_data['hasThermalPad'] == True :
			model_data['thermal'] = 1
			model_data['D1'] = self.ui_data['thermalPadLength']
			model_data['E1'] = self.ui_data['thermalPadWidth']

		return model_data
		
	def get_footprint(self):
		
		footprint_data = []
		
		toe_goal = ipc_rules.PAD_GOAL_NOLEAD['toeFilletMaxMedMin'][self.ui_data['densityLevel']]
		heel_goal = ipc_rules.PAD_GOAL_NOLEAD['heelFilletMaxMedMin'][self.ui_data['densityLevel']]
		side_goal = ipc_rules.PAD_GOAL_NOLEAD['sideFilletMaxMedMin'][self.ui_data['densityLevel']]

		#calculate the smd data.
		if self.ui_data['hasCustomFootprint'] :
				pin_pitch_h = self.ui_data['customPadSpan1'] - self.ui_data['customPadLength']
				pad_width_h = self.ui_data['customPadLength']
				pad_height_h = self.ui_data['customPadWidth']
		else : 
			pad_width_h, pad_height_h, pin_pitch_h = self.get_footprint_smd_data(self.ui_data['bodyWidthMin'], self.ui_data['bodyWidthMax'],
					self.ui_data['padWidthMin'], self.ui_data['padWidthMax'], self.ui_data['padHeightMin'], self.ui_data['padHeightMax'],
					toe_goal, heel_goal, side_goal) 			

		if self.ui_data['hasCustomFootprint'] :
				pin_pitch_v = self.ui_data['customPadSpan2'] - self.ui_data['customPadLength']
				pad_width_v = self.ui_data['customPadLength']
				pad_height_v = self.ui_data['customPadWidth']
		else :
			pad_width_v, pad_height_v, pin_pitch_v = self.get_footprint_smd_data(self.ui_data['bodyLengthMin'], self.ui_data['bodyLengthMax'],
					self.ui_data['padWidthMin'], self.ui_data['padWidthMax'], self.ui_data['padHeightMin'], self.ui_data['padHeightMax'],
					toe_goal, heel_goal, side_goal)
					
		left_smd_count = right_smd_count = self.ui_data['horizontalPadCount']
		top_smd_count = bottom_smd_count = self.ui_data['verticalPadCount']

		# build the left side smd
		for i in range(0, left_smd_count):
			row_index = i % left_smd_count
			smd_pos_y = ((left_smd_count - 1)/2 - row_index) * self.ui_data['verticalPinPitch']

			left_pad = footprint.FootprintSmd(-pin_pitch_h/2, smd_pos_y, pad_width_h, pad_height_h)
			left_pad.name = str(i + 1)
			left_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(left_pad)

		# build the bottom side smd 
		for i in range(0, bottom_smd_count):
			row_index = i % bottom_smd_count
			smd_pos_x = -((bottom_smd_count - 1)/2 - row_index) * self.ui_data['verticalPinPitch']

			bottom_pad = footprint.FootprintSmd(smd_pos_x, -pin_pitch_v/2, pad_width_v, pad_height_v)
			bottom_pad.name = str(left_smd_count + i + 1)
			bottom_pad.angle = 'R90.0'
			bottom_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(bottom_pad)	

		# build the right side smd
		for i in range(0, right_smd_count):
			row_index = right_smd_count - 1 - i % right_smd_count
			smd_pos_y = ((right_smd_count - 1)/2 - row_index) * self.ui_data['verticalPinPitch']
			
			right_pad = footprint.FootprintSmd(pin_pitch_h/2, smd_pos_y, pad_width_h, pad_height_h)
			right_pad.name = str (left_smd_count + bottom_smd_count + i + 1)
			right_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(right_pad)

		# build the top side smd 
		for i in range(0, top_smd_count):
			row_index = i % top_smd_count
			smd_pos_x = ((top_smd_count - 1)/2 - row_index) * self.ui_data['verticalPinPitch']

			top_pad = footprint.FootprintSmd(smd_pos_x, pin_pitch_v/2, pad_width_v, pad_height_v)
			top_pad.name = str(left_smd_count + bottom_smd_count + right_smd_count + i + 1)
			top_pad.angle = 'R90.0'
			top_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(top_pad)

		# build the thermal pad
		if self.ui_data['hasThermalPad'] == True :
			thermal_pad = footprint.FootprintSmd(0, 0, self.ui_data['thermalPadLength'], self.ui_data['thermalPadWidth'])
			thermal_pad.name = str(left_smd_count + bottom_smd_count + right_smd_count + top_smd_count + 1)
			thermal_pad.thermals = 'no'
			if self.ui_data['thermalPadSolderPasteOverride'] == True : 
				thermal_pad.cream = 'no'
				footprint_data.append(thermal_pad) 
				# add the solder paste data in the footprint 
				self.build_solder_paste_of_thermal_pad(footprint_data, self.ui_data['thermalPadLength'],self.ui_data['thermalPadWidth'],
						int(self.ui_data['thermalPadSolderPasteStencilRowCount']),int(self.ui_data['thermalPadSolderPasteStencilColCount']),
						self.ui_data['thermalPadSolderPasteStencilApertureLength'],self.ui_data['thermalPadSolderPasteStencilApertureWidth'], 
						self.ui_data['thermalPadSolderPasteStencilApertureGapX'],self.ui_data['thermalPadSolderPasteStencilApertureGapY'])
			else:
				#insert the thermal pad data object directly
				footprint_data.append(thermal_pad) 

		#build the silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])
		first_left_pad = footprint_data[0]
		first_bottom_pad = footprint_data[left_smd_count]

		# pin one marker
		self.build_silkscreen_pin_one_marker(footprint_data, first_left_pad.center_point_x, first_left_pad.center_point_y, first_left_pad.width, first_left_pad.height, body_width, False)

		top_edge_y = first_left_pad.center_point_y + first_left_pad.height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']
		left_edge_x = first_bottom_pad.center_point_x - first_bottom_pad.height/2 - ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']
		stroke_width = ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']

		bbox_y_max = body_length/2
		bbox_y_min = -bbox_y_max

		while True:
			# pads are outside of body
			if (top_edge_y + stroke_width/2 > body_length/2) and (left_edge_x - stroke_width/2 < -body_width/2):
				bbox_y_max = top_edge_y + stroke_width/2
				bbox_y_min = -bbox_y_max
				break

			# left first pad with clearence is outside of body
			elif top_edge_y + stroke_width/2 > body_length/2:
				bbox_y_max = top_edge_y + stroke_width/2
				bbox_y_min = -bbox_y_max

				line_top_left_h = footprint.FootprintWire(-body_width/2, bbox_y_max, left_edge_x, bbox_y_max, stroke_width)
				footprint_data.append(line_top_left_h)
				line_top_right_h = footprint.FootprintWire(body_width/2, bbox_y_max, -left_edge_x, bbox_y_max, stroke_width)
				footprint_data.append(line_top_right_h)
				line_bottom_left_h = footprint.FootprintWire(-body_width/2, -bbox_y_max, left_edge_x, -bbox_y_max, stroke_width)
				footprint_data.append(line_bottom_left_h)
				line_bottom_right_h = footprint.FootprintWire(body_width/2, -bbox_y_max, -left_edge_x, -bbox_y_max, stroke_width)
				footprint_data.append(line_bottom_right_h)

			# down first pad with clearence is outside of body	
			elif left_edge_x - stroke_width/2 < -body_width/2:
				bbox_x_max = left_edge_x - stroke_width/2
				line_top_left_v = footprint.FootprintWire(bbox_x_max, top_edge_y, bbox_x_max, body_length/2, stroke_width)
				footprint_data.append(line_top_left_v)
				line_top_right_v = footprint.FootprintWire(-bbox_x_max, body_length/2, -bbox_x_max, top_edge_y, stroke_width)
				footprint_data.append(line_top_right_v)
				line_bottom_left_v = footprint.FootprintWire(bbox_x_max, -top_edge_y, bbox_x_max, -body_length/2, stroke_width)
				footprint_data.append(line_bottom_left_v)	
				line_bottom_right_v = footprint.FootprintWire(-bbox_x_max, -body_length/2, -bbox_x_max, - top_edge_y, stroke_width)
				footprint_data.append(line_bottom_right_v)		

			else:
				line_top_left_v = footprint.FootprintWire(-body_width/2, top_edge_y, -body_width/2, body_length/2, stroke_width)
				footprint_data.append(line_top_left_v)
				line_top_left_h = footprint.FootprintWire(-body_width/2, body_length/2, left_edge_x, body_length/2, stroke_width)
				footprint_data.append(line_top_left_h)

				line_top_right_v = footprint.FootprintWire(body_width/2, body_length/2, body_width/2, top_edge_y, stroke_width)
				footprint_data.append(line_top_right_v)
				line_top_right_h = footprint.FootprintWire(body_width/2, body_length/2, -left_edge_x, body_length/2, stroke_width)
				footprint_data.append(line_top_right_h)

				line_bottom_left_v = footprint.FootprintWire(-body_width/2, -top_edge_y, -body_width/2, -body_length/2, stroke_width)
				footprint_data.append(line_bottom_left_v)
				line_bottom_left_h = footprint.FootprintWire(-body_width/2, -body_length/2, left_edge_x, -body_length/2, stroke_width)
				footprint_data.append(line_bottom_left_h)

				line_bottom_right_v = footprint.FootprintWire(body_width/2, -body_length/2, body_width/2, - top_edge_y, stroke_width)
				footprint_data.append(line_bottom_right_v)
				line_bottom_right_h = footprint.FootprintWire(body_width/2, -body_length/2, -left_edge_x, -body_length/2, stroke_width)
				footprint_data.append(line_bottom_right_h)
			break

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], stroke_width)

		#build the text
		self.build_footprint_text(footprint_data, 0)

		return footprint_data

	def get_ipc_package_name(self):
		# name + Pitch P + Body Width X Body Length X Height - Pin Qty + Thermal Pad
		
		pkg_name = 'QFN'
		pkg_name += str(int((self.ui_data['verticalPinPitch']*1000))) + 'P'
		pkg_name += str(int(((self.ui_data['bodyLengthMax'] * 1000 + self.ui_data['bodyLengthMin'] * 1000 )/2))) + 'X'
		pkg_name += str(int(((self.ui_data['bodyWidthMax'] * 1000 + self.ui_data['bodyWidthMin'] * 1000 )/2))) + 'X'
		pkg_name += str(int((self.ui_data['bodyHeightMax']*1000))) + '-'

		if self.ui_data['hasThermalPad'] == True:
			pkg_name += str(self.ui_data['horizontalPadCount']*2 + self.ui_data['verticalPadCount']*2 + 1)
			pkg_name += 'T' + str(int((self.ui_data['thermalPadWidth']*1000)))
			if self.ui_data['thermalPadLength'] != self.ui_data['thermalPadWidth']:
				pkg_name += 'X' + str(int((self.ui_data['thermalPadLength']*1000)))
		else:
			pkg_name += str(self.ui_data['horizontalPadCount']*2 + self.ui_data['verticalPadCount']*2)
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])	
		return pkg_name

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	
		pkg_name = 'QFN'

		lead_span = ao.units_manager.convert((self.ui_data['bodyWidthMax']+self.ui_data['bodyWidthMin'])/2, 'cm', unit)
		pin_pitch_h = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', unit)

		short_description = str(self.ui_data['horizontalPadCount']*2+self.ui_data['verticalPadCount']*2) + '-' + pkg_name+ ', '
		short_description += str('{:.2f}'.format(round(pin_pitch_h,2))) + ' ' + unit + ' pitch, '
		short_description += self.get_body_description(True,True) + unit + ' body'

		full_description = str(self.ui_data['horizontalPadCount']*2+self.ui_data['verticalPadCount']*2) + '-pin '+ pkg_name + ' package with '
		full_description += str('{:.2f}'.format(round(pin_pitch_h,2))) + ' ' + unit + ' pitch '
		full_description += self.get_body_description(False,True) + unit

		if self.ui_data['hasThermalPad'] == True :
			length = ao.units_manager.convert(self.ui_data['thermalPadLength'], 'cm', unit)
			width = ao.units_manager.convert(self.ui_data['thermalPadWidth'], 'cm', unit)
			short_description += ', ' + str('{:.2f}'.format(round(width,2))) + ' X ' + str('{:.2f}'.format(round(length,2))) + ' ' + unit + ' thermal pad'
			full_description += ' and thermal pad size ' +  str('{:.2f}'.format(round(width,2))) + ' X ' + str('{:.2f}'.format(round(length,2))) + ' ' + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "QFN"
		self.metadata["pitch"] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'), 4))
		self.metadata["pins"] = str((self.ui_data['horizontalPadCount'] + self.ui_data['verticalPadCount'])*2)

		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_QFN, PackageCalculatorQfn) 