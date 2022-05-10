# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules
from ..Utilities.localization import _LCLZ

# this class defines the package Calculator for the Axial Packages.
class PackageCalculatorDip(pkg_calculator.PackageCalculator):
	
	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)

	def get_body_color(self):
		
		if (self.ui_data['compFamily'] == 'resistor'):
			return [222, 181, 127]      
		if (self.ui_data['compFamily'] == 'Nonpolarized Capacitor'):
			return [203, 196, 53]
		if (self.ui_data['compFamily'] == 'Polarized Capacitor'):
			return [94, 208, 254]
		if (self.ui_data['compFamily'] == 'Diode'):
			return [30, 30, 30]
		if (self.ui_data['compFamily'] == 'Fuse'):
			return [200, 200, 200]
		if (self.ui_data['compFamily'] == 'Inductor'):
			return [30, 30, 30]
	

	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass
                
	# process the data for 3d model generator	
	def get_ipc_3d_model_data(self):
		model_data = {}
		model_data['type'] = self.pkg_type
		model_data['A'] = self.ui_data['bodyHeightMax']
		model_data['A1'] = self.ui_data['bodyOffset']
		model_data['E1'] = self.ui_data['bodyWidthMax']
		model_data['D'] = self.ui_data['bodyLengthMax']
		model_data['e'] = self.ui_data['verticalPinPitch']
		model_data['b'] = self.ui_data['terminalWidth']
		model_data['L'] = self.ui_data['terminalLength']
		model_data['DPins'] = self.ui_data['horizontalPadCount']
		if self.ui_data['type'] != constant.PKG_TYPE_DIP_SOCKET :    
			model_data['c'] = self.ui_data['terminalThickness'] 
			model_data['E'] = self.ui_data['leadSpan']
		else : 
			model_data['d'] = self.ui_data['horizontalPinPitch'] 
			model_data['E'] = self.ui_data['bodyWidthMax']
		return model_data
		
	def get_footprint(self):
		
		footprint_data = []

		pin_num = self.ui_data['horizontalPadCount']
		row_num = pin_num/2
		pin_pitch = self.ui_data['verticalPinPitch']

		if self.ui_data['type'] != constant.PKG_TYPE_DIP_SOCKET :
			lead_span = self.ui_data['leadSpan']
		else :
			lead_span = self.ui_data['horizontalPinPitch']

		#calculate the terminal diameter. 
		if self.ui_data['type'] != constant.PKG_TYPE_DIP_SOCKET : 
			terminal_diam = math.sqrt(self.ui_data['terminalWidth']*self.ui_data['terminalWidth'] + self.ui_data['terminalThickness']*self.ui_data['terminalThickness'])
		else :
			terminal_diam = math.sqrt(self.ui_data['terminalWidth']*self.ui_data['terminalWidth'] * 2)
		
		if self.ui_data['hasCustomFootprint']:
			drill_size = self.ui_data['customHoleDiameter']
			pad_diameter = self.ui_data['customPadDiameter']
		else:
			drill_size = self.get_footprint_pad_drill_size(self.ui_data['densityLevel'],terminal_diam)
			pad_diameter = self.get_footprint_pad_diameter(self.ui_data['densityLevel'],terminal_diam,self.ui_data['padToHoleRatio'])

		for i in range(0, pin_num):
			col = math.floor(i/row_num)
			row = i % row_num
			if col %2 == 1 :
				row = row_num - 1 - row #in odd columns change order from bottom to top
			# create Pad
			pad = footprint.FootprintPad((col-0.5)*lead_span, ((row_num - 1) / 2 - row)*pin_pitch , pad_diameter, drill_size)
			pad.name = str(i + 1)
			pad.shape = self.ui_data['padShape']
			footprint_data.append(pad)

		#build the silkscreen 
		if self.ui_data['type'] != constant.PKG_TYPE_DIP_SOCKET :    
			body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		else : 
			body_width = self.ui_data['bodyWidthMax']
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])

		# pin one marker

		self.build_silkscreen_pin_one_marker(footprint_data, -lead_span/2, pin_pitch*(row_num - 1)/2, pad_diameter, pad_diameter, body_width, True)

		top_edge = pad.center_point_y + pad_diameter/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] 
		stroke = ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']

		if top_edge + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2 > body_length/2 :
			line_top = footprint.FootprintWire(-body_width/2, top_edge + stroke/2, body_width/2, top_edge + stroke/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_top)
	
			line_bottom = footprint.FootprintWire(-body_width/2, -top_edge - stroke/2 , body_width/2, -top_edge - stroke/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_bottom)
		else:
			line_top_left = footprint.FootprintWire(-body_width/2, top_edge, -body_width/2, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_top_left)

			line_top = footprint.FootprintWire(-body_width/2, body_length/2, body_width/2, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_top)

			line_top_right = footprint.FootprintWire(body_width/2, body_length/2, body_width/2, top_edge, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_top_right)

			line_bottom_left = footprint.FootprintWire(-body_width/2, -top_edge, -body_width/2, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_bottom_left)

			line_bottom = footprint.FootprintWire(-body_width/2, -body_length/2, body_width/2, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_bottom)

			line_bottom_right = footprint.FootprintWire(body_width/2, -body_length/2, body_width/2, -top_edge, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_bottom_right)

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		#build the text
		self.build_footprint_text(footprint_data, 0)

		return footprint_data

	def get_ipc_package_name(self):
		#DIP + Lead Span + W Lead Width + P Pin Pitch + L Body Length + H Component Height + Q Pin Qty + producibility level (A, B, C)
    	#E.g., DIP762W52P254L1905H508Q14
		if self.ui_data['type'] == constant.PKG_TYPE_DIP_SOCKET : 
			pkg_name = 'DIPS'
			pkg_name += str(int((self.ui_data['bodyWidthMax']*1000))) 
		else:
			pkg_name = 'DIP'
			pkg_name += str(int((self.ui_data['leadSpan']*1000))) 		
		
		pkg_name += 'W' + str(int((self.ui_data['terminalWidth']*1000))) 
		pkg_name += 'P' + str(int((self.ui_data['verticalPinPitch']*1000)))
		pkg_name += 'L' + str(int(((self.ui_data['bodyLengthMax'] * 1000 +self.ui_data['bodyLengthMin'] * 1000 )/2))) 
		pkg_name += 'H' + str(int((self.ui_data['bodyHeightMax']*1000)))
		pkg_name += 'Q' + str(self.ui_data['horizontalPadCount'])
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_producibility_level_for_pth(self.ui_data['densityLevel'])		
		return pkg_name

	def get_ipc_package_description(self):
		ao = addin_utility.AppObjects()
		unit = 'mm'		
		# get the pin pitch
		pin_pitch = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm')
		pin_pitch_inch = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'in')
		
		if self.ui_data['type'] == constant.PKG_TYPE_DIP_SOCKET :
			lead_span = ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'mm')
			lead_span_inch = ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'in') 
		else :
			lead_span = ao.units_manager.convert(self.ui_data['leadSpan'], 'cm', 'mm')
			lead_span_inch = ao.units_manager.convert(self.ui_data['leadSpan'], 'cm', 'in')

		short_description = str(self.ui_data['horizontalPadCount'])
		if self.ui_data['type'] == constant.PKG_TYPE_DIP_SOCKET :
			short_description += '-DIP Socket,'
		else:
			short_description += '-DIP,'	
		short_description += ' ' + str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' ('+ str('{:.2f}'.format(round(pin_pitch_inch,2))) + ' in) pitch, '
		short_description += str('{:.2f}'.format(round(lead_span,2))) + ' ' + unit + ' ('+ str('{:.2f}'.format(round(lead_span_inch,2)))
		if self.ui_data['type'] == constant.PKG_TYPE_DIP_SOCKET :
			short_description += ' in) horizontal pin pitch, '
		else:
			short_description += ' in) span, '
		short_description += self.get_body_description(True, True) + unit + ' body'
		         
		full_description = str(self.ui_data['horizontalPadCount'])
		if self.ui_data['type'] == constant.PKG_TYPE_DIP_SOCKET :
			full_description += '-pin DIP Socket package'
		else:
			full_description += '-pin DIP package'
		full_description += ' with ' + str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' ('+ str('{:.2f}'.format(round(pin_pitch_inch,2))) + ' in) pitch, '
		full_description += str('{:.2f}'.format(round(lead_span,2))) + ' ' + unit + ' ('+ str('{:.2f}'.format(round(lead_span_inch,2)))
		if self.ui_data['type'] == constant.PKG_TYPE_DIP_SOCKET :
			full_description += ' in) horizontal pin pitch'
		else:
			full_description += ' in) span'
		full_description += self.get_body_description(False, True) + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "DIP"
		self.metadata["pitch"] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'),4))
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		if self.ui_data['type'] != constant.PKG_TYPE_DIP_SOCKET :    
			self.metadata['leadSpan'] = str(round(ao.units_manager.convert(self.ui_data['leadSpan'], 'cm', 'mm'), 4))
		else :
			self.metadata["pitch2"] = str(round(ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'mm'),4))

		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_DIP, PackageCalculatorDip) 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_DIP_SOCKET, PackageCalculatorDip) 