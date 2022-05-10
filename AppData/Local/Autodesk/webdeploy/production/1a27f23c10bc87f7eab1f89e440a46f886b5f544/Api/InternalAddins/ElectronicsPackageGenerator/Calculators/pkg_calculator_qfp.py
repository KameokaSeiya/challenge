# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

# this class defines the package Calculator for the ECAP Package.
class PackageCalculatorQfp(pkg_calculator.PackageCalculator):
	
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
		model_data['E1'] = self.ui_data['bodyWidthMax']
		model_data['D1'] = self.ui_data['bodyLengthMax']
		model_data['A1'] = self.ui_data['bodyOffsetMin']
		model_data['b'] = self.ui_data['padHeightMax']
		model_data['D'] = self.ui_data['verticalLeadToLeadSpanMax']
		model_data['E'] = self.ui_data['horizontalLeadToLeadSpanMax']
		model_data['e'] = self.ui_data['verticalPinPitch']
		model_data['L'] = (self.ui_data['padWidthMax'] + self.ui_data['padWidthMin'])/2
		model_data['DPins'] = self.ui_data['horizontalPadCount']*2
		model_data['EPins'] = self.ui_data['verticalPadCount']*2

		if self.ui_data['hasThermalPad'] == True :
			model_data['thermal'] = 1
			model_data['E2'] = self.ui_data['thermalPadLength']
			model_data['D2'] = self.ui_data['thermalPadWidth']

		return model_data
		
	def get_footprint(self):
		
		footprint_data = []
		
		if self.ui_data['verticalPinPitch'] > ipc_rules.PAD_GOAL_GULLWING['pitchTh']:
			toe_goal = ipc_rules.PAD_GOAL_GULLWING['toeFilletMaxMedMinGT'][self.ui_data['densityLevel']]
			heel_goal = ipc_rules.PAD_GOAL_GULLWING['heelFilletMaxMedMinGT'][self.ui_data['densityLevel']]
			side_goal = ipc_rules.PAD_GOAL_GULLWING['sideFilletMaxMedMinGT'][self.ui_data['densityLevel']]
		else:
			toe_goal = ipc_rules.PAD_GOAL_GULLWING['toeFilletMaxMedMinLTE'][self.ui_data['densityLevel']]
			heel_goal = ipc_rules.PAD_GOAL_GULLWING['heelFilletMaxMedMinLTE'][self.ui_data['densityLevel']]
			side_goal = ipc_rules.PAD_GOAL_GULLWING['sideFilletMaxMedMinLTE'][self.ui_data['densityLevel']]

		#calculate the smd data. 
		if self.ui_data['hasCustomFootprint'] :
				E_pin_pitch = self.ui_data['customPadSpan2'] - self.ui_data['customPadLength']
				E_pad_width = self.ui_data['customPadLength']
				E_pad_height = self.ui_data['customPadWidth']
		else :
			E_pad_width, E_pad_height, E_pin_pitch = self.get_footprint_smd_data1(self.ui_data['verticalLeadToLeadSpanMax'], self.ui_data['verticalLeadToLeadSpanMin'],
					self.ui_data['padWidthMax'], self.ui_data['padWidthMin'], self.ui_data['padHeightMax'], self.ui_data['padHeightMin'],
					self.ui_data['bodyWidthMax'], toe_goal, heel_goal, side_goal) 		

		if self.ui_data['hasCustomFootprint'] :
				D_pin_pitch = self.ui_data['customPadSpan1'] - self.ui_data['customPadLength']
				D_pad_width = self.ui_data['customPadLength']
				D_pad_height = self.ui_data['customPadWidth']
		else :
			D_pad_width, D_pad_height, D_pin_pitch = self.get_footprint_smd_data1(self.ui_data['horizontalLeadToLeadSpanMax'], self.ui_data['horizontalLeadToLeadSpanMin'],
					self.ui_data['padWidthMax'], self.ui_data['padWidthMin'], self.ui_data['padHeightMax'], self.ui_data['padHeightMin'],
					self.ui_data['bodyWidthMax'], toe_goal, heel_goal, side_goal)

		total_pad_count = self.ui_data['horizontalPadCount']*2 + self.ui_data['verticalPadCount']*2
		D_side_pad_count = self.ui_data['horizontalPadCount']
		E_side_pad_count = self.ui_data['verticalPadCount']

		#build left pads - D pads
		for i in range(0, D_side_pad_count):
			pos_y = ((D_side_pad_count - 1)/2 - i) * self.ui_data['verticalPinPitch']
			pad = footprint.FootprintSmd(-D_pin_pitch/2, pos_y, D_pad_width, D_pad_height)
			pad.name = str(i + 1)
			pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(pad)
		#build bottom pads - E pads
		for i in range(0, E_side_pad_count):
			pos_x = - ((E_side_pad_count - 1)/2 - i) * self.ui_data['verticalPinPitch']
			pad = footprint.FootprintSmd(pos_x, -E_pin_pitch/2, E_pad_width, E_pad_height)
			pad.name = str(D_side_pad_count + i + 1)
			pad.angle = 'R90.0'
			pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(pad)
		
		#build right pads - D pads
		for i in range(0, D_side_pad_count):
			pos_y = - ((D_side_pad_count - 1)/2 - i) * self.ui_data['verticalPinPitch']
			pad = footprint.FootprintSmd( D_pin_pitch/2, pos_y, D_pad_width, D_pad_height)
			pad.name = str(E_side_pad_count + D_side_pad_count + i + 1)
			pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(pad)
		#build top pads - E pads
		for i in range(0, E_side_pad_count):
			pos_x = ((E_side_pad_count - 1)/2 - i) * self.ui_data['verticalPinPitch']
			pad = footprint.FootprintSmd(pos_x, E_pin_pitch/2, E_pad_width, E_pad_height)
			pad.name = str(D_side_pad_count*2 + E_side_pad_count + i + 1)
			pad.angle = 'R90.0'
			pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(pad)
		
		# build the thermal pad
		if self.ui_data['hasThermalPad'] == True :
			thermal_pad = footprint.FootprintSmd(0, 0, self.ui_data['thermalPadLength'], self.ui_data['thermalPadWidth'])
			thermal_pad.name = str(total_pad_count+ 1)
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
		stroke_width = ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']
		top_left_pad = footprint_data[E_side_pad_count*2 + D_side_pad_count*2-1]
		left_top_pad = footprint_data[0]

		# pin one marker
		self.build_silkscreen_pin_one_marker(footprint_data, left_top_pad.center_point_x, left_top_pad.center_point_y, left_top_pad.width, left_top_pad.height, body_width, False)

		offset_y = left_top_pad.center_point_y + left_top_pad.height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']
		offset_x = abs(top_left_pad.center_point_x - top_left_pad.height/2 - ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'])

		if offset_y < body_length/2: # draw 4 vertical lines
			line_top_left = footprint.FootprintWire(-body_width/2, body_length/2, - body_width/2, offset_y, stroke_width)
			footprint_data.append(line_top_left)
			line_top_right = footprint.FootprintWire(body_width/2, body_length/2, body_width/2, offset_y, stroke_width)
			footprint_data.append(line_top_right)
			line_bottom_left = footprint.FootprintWire(-body_width/2, -body_length/2, -body_width/2, -offset_y, stroke_width)
			footprint_data.append(line_bottom_left)
			line_bottom_right = footprint.FootprintWire(body_width/2, -body_length/2, body_width/2, -offset_y, stroke_width)
			footprint_data.append(line_bottom_right)
				
		if offset_x < body_width/2 : # draw 4 horizontal lines 
			line_top_left = footprint.FootprintWire(-body_width/2, body_length/2, -offset_x, body_length/2, stroke_width)
			footprint_data.append(line_top_left)
			line_top_right = footprint.FootprintWire(body_width/2, body_length/2, offset_x, body_length/2, stroke_width)
			footprint_data.append(line_top_right)
			line_bottom_left = footprint.FootprintWire(-body_width/2, -body_length/2, -offset_x, -body_length/2, stroke_width)
			footprint_data.append(line_bottom_left)
			line_bottom_right = footprint.FootprintWire(body_width/2, -body_length/2, offset_x, -body_length/2, stroke_width)
			footprint_data.append(line_bottom_right)

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], stroke_width)

		#build the text
		self.build_footprint_text(footprint_data, 0)
		
		return footprint_data

	def get_ipc_package_name(self):
		#Name + Pitch + P + Lead Span Nominal + X + Height Max - Pin Qty density level
		pkg_name = 'QFP'
		pkg_name += str(int((self.ui_data['verticalPinPitch']*1000))) + 'P'
		pkg_name += str(int(((self.ui_data['verticalLeadToLeadSpanMax'] * 1000 + self.ui_data['verticalLeadToLeadSpanMin'] * 1000 )/2))) + 'X'
		pkg_name += str(int(((self.ui_data['horizontalLeadToLeadSpanMax'] * 1000 + self.ui_data['horizontalLeadToLeadSpanMin'] * 1000 )/2))) + 'X'
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

		h_span = ao.units_manager.convert((self.ui_data['horizontalLeadToLeadSpanMax']+self.ui_data['horizontalLeadToLeadSpanMin'])/2, 'cm', unit)
		v_span = ao.units_manager.convert((self.ui_data['verticalLeadToLeadSpanMax']+self.ui_data['verticalLeadToLeadSpanMin'])/2, 'cm', unit)
		pin_pitch = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', unit)

		short_description = str(self.ui_data['horizontalPadCount']*2 + self.ui_data['verticalPadCount']*2) + '-QFP, '
		short_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		if h_span == v_span :
			short_description += str('{:.2f}'.format(round(h_span,2))) + ' ' + unit + ' span, '
		else:
			short_description += str('{:.2f}'.format(round(v_span,2))) + ' ' + unit + ' lead span1, '
			short_description += str('{:.2f}'.format(round(h_span,2))) + ' ' + unit + ' lead span2, '
		short_description += self.get_body_description(True,False) + unit + ' body'
		
		full_description = str(self.ui_data['horizontalPadCount']*2+self.ui_data['verticalPadCount']*2) + '-pin QFP package with '
		full_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		full_description += str('{:.2f}'.format(round(v_span,2))) + ' ' + unit + ' lead span1'
		full_description += ' X ' + str('{:.2f}'.format(round(h_span,2))) + ' ' + unit + ' lead span2 '
		full_description += self.get_body_description(False,False) + unit

		if self.ui_data['hasThermalPad'] == True :
			length = ao.units_manager.convert(self.ui_data['thermalPadLength'], 'cm', unit)
			width = ao.units_manager.convert(self.ui_data['thermalPadWidth'], 'cm', unit)
			short_description += ', ' + str('{:.2f}'.format(round(width,2))) + ' X ' + str('{:.2f}'.format(round(length,2))) + ' ' + unit + ' thermal pad'
			full_description += ' and thermal pad size ' +  str('{:.2f}'.format(round(width,2))) + ' X ' + str('{:.2f}'.format(round(length,2))) + ' ' + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "QFP"
		self.metadata["pitch"] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'), 4))
		self.metadata["pins"] = str((self.ui_data['horizontalPadCount'] + self.ui_data['verticalPadCount'])*2)
		self.metadata['leadSpan'] = str(round(ao.units_manager.convert((self.ui_data['verticalLeadToLeadSpanMax']+self.ui_data['verticalLeadToLeadSpanMin'])/2, 'cm', 'mm'), 4))
		self.metadata['leadSpan2'] = str(round(ao.units_manager.convert((self.ui_data['horizontalLeadToLeadSpanMax']+self.ui_data['horizontalLeadToLeadSpanMin'])/2, 'cm', 'mm'), 4))

		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_QFP, PackageCalculatorQfp) 