# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility,constant
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules
from ..Utilities.localization import _LCLZ

# this class defines the package Calculator for the Axial Packages.
class PackageCalculatorAxial(pkg_calculator.PackageCalculator):
	
	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)

	# get the bend radius value based on the IPC reference table. 
	def get_bend_radius(self):		
		lead_bend_factor = 1
		if self.ui_data['terminalWidthMax'] <= ipc_rules.AXIAL_LEAD_GOAL['thresholds'][0] :
			lead_bend_factor = ipc_rules.AXIAL_LEAD_GOAL['range1'][3]
		else:
			if (self.ui_data['terminalWidthMax'] > ipc_rules.AXIAL_LEAD_GOAL['thresholds'][0] and self.ui_data['terminalWidthMax'] <= ipc_rules.AXIAL_LEAD_GOAL['thresholds'][1]) :
				lead_bend_factor = ipc_rules.AXIAL_LEAD_GOAL['range2'][3]
			else:
				if (self.ui_data['terminalWidthMax'] > ipc_rules.AXIAL_LEAD_GOAL['thresholds'][1]):
					lead_bend_factor = ipc_rules.AXIAL_LEAD_GOAL['range3'][3]

		return lead_bend_factor*self.ui_data['terminalWidthMax']
	
	# get the lead extension value based on the IPC reference table. 	
	def get_lead_extension(self):
		if self.ui_data['terminalWidthMax'] <= ipc_rules.AXIAL_LEAD_GOAL['thresholds'][0] :
			return ipc_rules.AXIAL_LEAD_GOAL['range1'][self.ui_data['densityLevel']]

		else:
			if (self.ui_data['terminalWidthMax'] > ipc_rules.AXIAL_LEAD_GOAL['thresholds'][0] and self.ui_data['terminalWidthMax'] <= ipc_rules.AXIAL_LEAD_GOAL['thresholds'][1]) :
				return ipc_rules.AXIAL_LEAD_GOAL['range2'][self.ui_data['densityLevel']]
			else:
				if (self.ui_data['terminalWidthMax'] > ipc_rules.AXIAL_LEAD_GOAL['thresholds'][1]):
					return ipc_rules.AXIAL_LEAD_GOAL['range3'][self.ui_data['densityLevel']]
					
					
	def get_body_color(self):
		
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_RESISTOR):
			return [222, 181, 127]      
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR):
			return [203, 196, 53]
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_POLARIZED_CAPACITOR):
			return [94, 208, 254]
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE):
			return [30, 30, 30]
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_FUSE):
			return [200, 200, 200]
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_INDUCTOR):
			return [30, 30, 30]
	
	def get_pin_pitch(self):
		if self.ui_data['pitchOverride']:
			pin_pitch = self.ui_data['verticalPinPitch']
		else : 
			lead_extension = self.get_lead_extension()
			bend_radius = self.get_bend_radius()
			pin_pitch = self.ui_data['bodyWidthMax'] + (lead_extension + bend_radius)*2
		return pin_pitch

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
		model_data['b'] = self.ui_data['terminalWidthMax']
		model_data['R'] = self.get_bend_radius()
		
		if self.ui_data['pitchOverride']:
			model_data['e'] = self.ui_data['verticalPinPitch']
		else : 
			model_data['L1'] = self.get_lead_extension()

		if 	(self.ui_data['componentFamily'] == constant.COMP_FAMILY_POLARIZED_CAPACITOR or 
			self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE) :
			model_data['isPolarized'] = 1
		else : 
			model_data['isPolarized'] = 0

        # get the proper body color
		body_color = self.get_body_color()
		model_data['color_r'] = body_color[0]
		model_data['color_g'] = body_color[1]
		model_data['color_b'] = body_color[2] 
        
		return model_data

		
	def get_footprint(self):
		
		footprint_data = []
		# get the pin pitch
		pin_pitch = self.get_pin_pitch()
		if self.ui_data['hasCustomFootprint'] :
			drill_size = self.ui_data['customHoleDiameter']
			pad_diameter = self.ui_data['customPadDiameter']
		else:
			drill_size = self.get_footprint_pad_drill_size(self.ui_data['densityLevel'],self.ui_data['terminalWidthMax'])
			pad_diameter = self.get_footprint_pad_diameter(self.ui_data['densityLevel'],self.ui_data['terminalWidthMax'],self.ui_data['padToHoleRatio'])

		# initiate the left pad data 
		left_pad = footprint.FootprintPad(-pin_pitch/2, 0, pad_diameter, drill_size)
		if self.ui_data['componentFamily']  == constant.COMP_FAMILY_DIODE :
			left_pad.name = 'C'
		else:
			left_pad.name = '1'
		left_pad.shape = self.ui_data['padShape']
		footprint_data.append(left_pad)

		# initiate the right pad data 
		right_pad = footprint.FootprintPad(pin_pitch/2, 0, pad_diameter, drill_size)
		if self.ui_data['componentFamily']  == constant.COMP_FAMILY_DIODE :
			right_pad.name = 'A'
		else:
			right_pad.name = '2'
		right_pad.shape = self.ui_data['padShape']
		footprint_data.append(right_pad)

		#build the silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])

		line1 = footprint.FootprintWire(-body_width/2, -body_length/2, -body_width/2, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line1)
		line2 = footprint.FootprintWire(-body_width/2, body_length/2, body_width/2, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line2)
		line3 = footprint.FootprintWire(body_width/2, body_length/2, body_width/2, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line3)
		line4 = footprint.FootprintWire(body_width/2, -body_length/2, -body_width/2, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line4)

		if self.ui_data['componentFamily'] == constant.COMP_FAMILY_POLARIZED_CAPACITOR or self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE :
			band_line =  footprint.FootprintWire(-body_width*3/8, body_length/2, -body_width*3/8, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(band_line)
		
		left_line = footprint.FootprintWire(-body_width/2, 0, -pin_pitch/2 + pad_diameter/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'], 0, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(left_line)
		right_line = footprint.FootprintWire(body_width/2, 0, pin_pitch/2 - pad_diameter/2 - ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'], 0, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(right_line)

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		#build the text
		self.build_footprint_text(footprint_data)


		return footprint_data

	def get_ipc_package_name(self):
		#family + Lead Spacing + W Lead Width + L Body Length + D Body Diameter + producibility level (A, B, C)
        #E.g., RESAD800W52L600D150B
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_RESISTOR):
			family_name = 'RESAD'     
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR):
			family_name = 'CAPAD' 
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_POLARIZED_CAPACITOR):
			family_name = 'CAPPAD' 
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE):
			family_name = 'DIOAD' 
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_FUSE):
			family_name = 'FUSAD' 
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_INDUCTOR):
			family_name = 'INDAD' 
		
		# get the pin pitch
		pin_pitch = self.get_pin_pitch()
        
		pkg_name = family_name 
		pkg_name += str(int((pin_pitch*1000))) 
		pkg_name += 'W' + str(int((self.ui_data['terminalWidthMax']*1000))) 
		pkg_name += 'L' + str(int(((self.ui_data['bodyWidthMax'] * 1000 +self.ui_data['bodyWidthMin'] * 1000 )/2))) 
		pkg_name += 'D' + str(int(((self.ui_data['bodyLengthMax'] * 1000 +self.ui_data['bodyLengthMin'] * 1000 )/2)))
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_producibility_level_for_pth(self.ui_data['densityLevel'])		
		return pkg_name
		
	def get_ipc_package_description(self):

		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_RESISTOR):
			family_name = 'Resistor'     
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR):
			family_name = 'Non-Polarized Capacitor' 
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_POLARIZED_CAPACITOR):
			family_name = 'Polarized Capacitor' 
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE):
			family_name = 'Diode' 
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_FUSE):
			family_name = 'Fuse' 
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_INDUCTOR):
			family_name = 'Inductor' 
		
		ao = addin_utility.AppObjects()
		unit = 'mm'
		# get the pin pitch
		pin_pitch = ao.units_manager.convert(self.get_pin_pitch(), 'cm', 'mm')
		terminal_width = ao.units_manager.convert(self.ui_data['terminalWidthMax'], 'cm', 'mm')
		body_width = ao.units_manager.convert((self.ui_data['bodyWidthMax']+self.ui_data['bodyWidthMin'])/2, 'cm', 'mm')
		body_length = ao.units_manager.convert((self.ui_data['bodyLengthMax']+self.ui_data['bodyLengthMin'])/2, 'cm', 'mm')

		short_description = 'Axial ' + family_name + ', '
		short_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		short_description += str('{:.2f}'.format(round(body_width,2))) + ' ' + unit + ' body length, '
		short_description += str('{:.2f}'.format(round(body_length,2))) + ' ' + unit + ' body diameter'

		full_description = 'Axial ' + family_name + ' package'
		full_description += ' with ' + str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch (lead spacing), '
		full_description += str('{:.2f}'.format(round(terminal_width,2))) + ' ' + unit + ' lead diameter, '
		full_description += str('{:.2f}'.format(round(body_width,2))) + ' ' + unit + ' body length'
		full_description += ' and ' + str('{:.2f}'.format(round(body_length,2))) + ' ' + unit + ' body diameter'

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		isPackageRotated = True
		super().get_ipc_package_metadata(isPackageRotated)
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "AXIAL"
		self.metadata["pitch"] = str(round(ao.units_manager.convert(self.get_pin_pitch(), 'cm', 'mm'),4))
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_AXIAL_POLARIZED_CAPACITOR, PackageCalculatorAxial) 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_AXIAL_DIODE, PackageCalculatorAxial)
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_AXIAL_FUSE, PackageCalculatorAxial) 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_AXIAL_RESISTOR, PackageCalculatorAxial) 
