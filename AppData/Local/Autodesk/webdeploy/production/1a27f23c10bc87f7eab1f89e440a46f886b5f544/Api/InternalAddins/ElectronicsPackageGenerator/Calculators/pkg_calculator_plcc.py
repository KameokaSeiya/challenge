# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, fusion_sketch, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules
from ..Utilities.localization import _LCLZ

# this class defines the package Calculator for the ECAP Package.
class PackageCalculatorPlcc(pkg_calculator.PackageCalculator):
	
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
		model_data['E'] = self.ui_data['verticalLeadToLeadSpanMax']
		model_data['E1'] = self.ui_data['bodyLengthMax']
		model_data['D1'] = self.ui_data['bodyWidthMax']
		model_data['D2'] = self.ui_data['terminalCenterToCenterDistance']
		model_data['E2'] = self.ui_data['terminalCenterToCenterDistance2']
		model_data['e'] = self.ui_data['verticalPinPitch']
		model_data['EPins'] = self.ui_data['horizontalPadCount']*2
		model_data['DPins'] = self.ui_data['verticalPadCount']*2
		return model_data
		
	def get_footprint(self):
		
		footprint_data = []

		toe_goal = ipc_rules.PAD_GOAL_PLCC['toeFilletMaxMedMin'][self.ui_data['densityLevel']]
		heel_goal = ipc_rules.PAD_GOAL_PLCC['heelFilletMaxMedMin'][self.ui_data['densityLevel']]
		side_goal = ipc_rules.PAD_GOAL_PLCC['sideFilletMaxMedMin'][self.ui_data['densityLevel']]

		E_pad_width_max = self.ui_data['horizontalLeadToLeadSpanMax'] - self.ui_data['terminalCenterToCenterDistance']
		E_pad_width_min = self.ui_data['horizontalLeadToLeadSpanMin'] - self.ui_data['terminalCenterToCenterDistance']

		D_pad_width_max = self.ui_data['verticalLeadToLeadSpanMax'] - self.ui_data['terminalCenterToCenterDistance2']
		D_pad_width_min = self.ui_data['verticalLeadToLeadSpanMin'] - self.ui_data['terminalCenterToCenterDistance2']

		#calculate the smd data. 
		if self.ui_data['hasCustomFootprint'] :
				E_pin_pitch = self.ui_data['customPadSpan2'] - self.ui_data['customPadLength']
				E_pad_width = self.ui_data['customPadLength']
				E_pad_height = self.ui_data['customPadWidth']
		else :
			E_pad_width, E_pad_height, E_pin_pitch = self.get_footprint_smd_data(self.ui_data['horizontalLeadToLeadSpanMin'],self.ui_data['horizontalLeadToLeadSpanMax'], 
					E_pad_width_min, E_pad_width_max, self.ui_data['padHeightMin'], self.ui_data['padHeightMax'], toe_goal, heel_goal, side_goal) 

		if self.ui_data['hasCustomFootprint'] :
				D_pin_pitch = self.ui_data['customPadSpan1'] - self.ui_data['customPadLength']
				D_pad_width = self.ui_data['customPadLength']
				D_pad_height = self.ui_data['customPadWidth']
		else :
			D_pad_width, D_pad_height, D_pin_pitch = self.get_footprint_smd_data(self.ui_data['verticalLeadToLeadSpanMin'],self.ui_data['verticalLeadToLeadSpanMax'], 
					D_pad_width_min, D_pad_width_max, self.ui_data['padHeightMin'], self.ui_data['padHeightMax'], toe_goal, heel_goal, side_goal)

		

		total_pad_count = self.ui_data['horizontalPadCount']*2 + self.ui_data['verticalPadCount']*2
		E_side_pad_count = self.ui_data['horizontalPadCount']
		D_side_pad_count = self.ui_data['verticalPadCount']
		pin_one_idx = math.floor(E_side_pad_count/2)
		#build left pads - E pads
		for i in range(0, E_side_pad_count):
			pos_y = ((E_side_pad_count - 1)/2 - i) * self.ui_data['verticalPinPitch']
			pad = footprint.FootprintSmd(-E_pin_pitch/2, pos_y, E_pad_width, E_pad_height)
			if i < pin_one_idx:
				pad.name = str(total_pad_count - pin_one_idx + i + 1)
			else:
				pad.name = str(i + 1 - pin_one_idx)
			
			pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(pad)
		#build bottom pads - D pads
		for i in range(0, D_side_pad_count):
			pos_x = - ((D_side_pad_count - 1)/2 - i) * self.ui_data['verticalPinPitch']
			pad = footprint.FootprintSmd(pos_x, -D_pin_pitch/2, D_pad_width, D_pad_height)
			pad.name = str(E_side_pad_count - pin_one_idx + i + 1)
			pad.angle = 'R90.0'
			pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(pad)
		
		#build right pads - Epads
		for i in range(0, E_side_pad_count):
			pos_y = - ((E_side_pad_count - 1)/2 - i) * self.ui_data['verticalPinPitch']
			pad = footprint.FootprintSmd( E_pin_pitch/2, pos_y, E_pad_width, E_pad_height)
			pad.name = str(E_side_pad_count + D_side_pad_count - pin_one_idx + i + 1)
			pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(pad)
		#build top pads - D pads
		for i in range(0, D_side_pad_count):
			pos_x = ((D_side_pad_count - 1)/2 - i) * self.ui_data['verticalPinPitch']
			pad = footprint.FootprintSmd(pos_x, D_pin_pitch/2, D_pad_width, D_pad_height)
			pad.name = str(E_side_pad_count*2 + D_side_pad_count - pin_one_idx + i + 1)
			pad.angle = 'R90.0'
			pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(pad)



		#build the silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])
		pin_one_pad = footprint_data[pin_one_idx]
		stroke_width = ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']
		top_left_pad = footprint_data[E_side_pad_count*2 + D_side_pad_count*2-1]
		left_top_pad = footprint_data[0]

		# pin one marker
		self.build_silkscreen_pin_one_marker(footprint_data, pin_one_pad.center_point_x, pin_one_pad.center_point_y, pin_one_pad.width, pin_one_pad.height, body_width, True)

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
		#PLCC + Pitch P + Lead Span L1 X Lead Span L2 Nominal X Height Max - Pin Qty
		#L1 and L2 are along X and Y directions respectively
		pkg_name = 'PLCC'
		pkg_name += str(int((self.ui_data['verticalPinPitch']*1000))) + 'P'
		pkg_name += str(int(((self.ui_data['horizontalLeadToLeadSpanMax'] * 1000 + self.ui_data['horizontalLeadToLeadSpanMin'] * 1000 )/2))) + 'X'		
		pkg_name += str(int(((self.ui_data['verticalLeadToLeadSpanMax'] * 1000 + self.ui_data['verticalLeadToLeadSpanMin'] * 1000 )/2))) + 'X'
		pkg_name += str(int((self.ui_data['bodyHeightMax']*1000))) + '-'
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

		short_description = str(self.ui_data['horizontalPadCount']*2 + self.ui_data['verticalPadCount']*2) + '-PLCC, '
		short_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		if h_span == v_span :
			short_description += str('{:.2f}'.format(round(h_span,2))) + ' ' + unit + ' span, '
		else:
			short_description += str('{:.2f}'.format(round(h_span,2))) + ' ' + unit + ' lead span1, '
			short_description += str('{:.2f}'.format(round(v_span,2))) + ' ' + unit + ' lead span2, '
		short_description += self.get_body_description(True,False) + unit + ' body'
		
		full_description = str(self.ui_data['horizontalPadCount']*2 + self.ui_data['verticalPadCount']*2) + '-pin PLCC package with '
		full_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		full_description += str('{:.2f}'.format(round(h_span,2))) + ' ' + unit + ' lead span1'
		full_description += ' X ' + str('{:.2f}'.format(round(v_span,2))) + ' ' + unit + ' lead span2 '
		full_description += self.get_body_description(False,False) + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		isPackageRotated = True
		super().get_ipc_package_metadata(isPackageRotated)
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "PLCC"
		self.metadata['leadSpan2'] = str(round(ao.units_manager.convert((self.ui_data['verticalLeadToLeadSpanMax']+self.ui_data['verticalLeadToLeadSpanMin'])/2, 'cm', 'mm'), 4))
		self.metadata['leadSpan'] = str(round(ao.units_manager.convert((self.ui_data['horizontalLeadToLeadSpanMax']+self.ui_data['horizontalLeadToLeadSpanMin'])/2, 'cm', 'mm'), 4))
		self.metadata["pins"] = str((self.ui_data['horizontalPadCount'] + self.ui_data['verticalPadCount'])*2)
		
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_PLCC, PackageCalculatorPlcc) 