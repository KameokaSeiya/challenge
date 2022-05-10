# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

# this class defines the package Calculator for the Axial Packages.
class PackageCalculatorMaleFemaleStandoff(pkg_calculator.PackageCalculator):
	
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
		model_data['A'] = self.ui_data['bodyHeightMax']
		model_data['E'] = self.ui_data['bodyWidthMax']
		model_data['L'] = self.ui_data['innerThreadDepth']
		model_data['L1'] = self.ui_data['postThreadDepth']
		model_data['body'] = str(self.ui_data['bodyShape']).lower()
		model_data['innerThreadType'] = self.ui_data['innerThreadType']
		model_data['innerThreadDesignation'] = self.ui_data['innerThreadDesignation']
		model_data['innerThreadClass'] = self.ui_data['innerThreadClass']
		model_data['postThreadType'] = self.ui_data['postThreadType']
		model_data['postThreadDesignation'] = self.ui_data['postThreadDesignation']
		model_data['postThreadClass'] = self.ui_data['postThreadClass']
		return model_data
		
	# generate ipc footprint data
	def get_footprint(self):
		
		footprint_data = []
		
		if self.ui_data['viaThermalRelief'] :
			thermal_connect_type = 'relief'
		else:
			thermal_connect_type = 'no'
		
		# create hole object
		hole = footprint.FootprintHole(0,0,self.ui_data['holeDiameter'])
		footprint_data.append(hole)

		if self.ui_data['withPad']:
			# build mounting hole pads
			main_pad = footprint.FootprintPad(0,0,self.ui_data['padDiameter'], self.ui_data['holeDiameter'])
			main_pad.name = '1'
			main_pad.shape = self.ui_data['padShape']
			main_pad.thermals = thermal_connect_type
			footprint_data.append(main_pad)

			# build via pads
			if self.ui_data['withVia'] and int(self.ui_data['viaCount']) > 0 :
				self.build_footprint_mounting_hole_vias(footprint_data, int(self.ui_data['viaCount']), 
														self.ui_data['viaDiameter'],self.ui_data['viaCenterOffset'], 
														thermal_connect_type, self.ui_data['densityLevel'])

			# build silkscreen for mounting hole
			self.build_silkscreen_mounting_hole(footprint_data, self.ui_data['padDiameter'], self.ui_data['padShape'], self.ui_data['bodyWidthMax'])
				
		# create silkscreen on pcb bottome side
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		circle_bottom = footprint.FootprintCircle(0, 0, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'], body_width/2)
		circle_bottom.layer = 51
		footprint_data.append(circle_bottom)
    	
		#build the text
		self.build_footprint_text(footprint_data)	
			
		return footprint_data

	def get_ipc_package_name(self):
		#STANDOFF _ Body Shape _ Gender_Body Width(E) X Height(A) _ Thread Designation_ [MTG + NP (non-plated) + Land Size(E1) + H + Hole Size(b) + V + No. of vias]
		pkg_name = 'STANDOFF'
		mounting_hole_info = ''
		if self.ui_data['withPad']:
			mounting_hole_info += '_MTG' 
			if self.ui_data['plated']:
				mounting_hole_info += 'P'
			else:
				mounting_hole_info += 'NP'
			mounting_hole_info += str(int((self.ui_data['padDiameter']*1000)))
			mounting_hole_info += 'H' + str(int((self.ui_data['holeDiameter']*1000)))
			if self.ui_data['withVia'] and int(self.ui_data['viaCount']) > 0:
				mounting_hole_info += 'V' + str(self.ui_data['viaCount'])
		
		pkg_name += '_' + str(self.ui_data['bodyShape']).upper()
		pkg_name += '_' + 'MALE-FEMALE'
		pkg_name += '_' + str(int(((self.ui_data['bodyWidthMax'] * 1000 +self.ui_data['bodyWidthMin'] * 1000 )/2)))
		pkg_name += 'X' + str(int((self.ui_data['bodyHeightMax']*1000)))
		pkg_name += '_' + self.ui_data['postThreadDesignation'] + mounting_hole_info
		return pkg_name

	def get_ipc_package_description(self):
		ao = addin_utility.AppObjects()
		unit = 'mm'

		mounting_hole_info = ''
		mounting_hole_info_full = ''
		if self.ui_data['withPad']:
			if self.ui_data['plated']:
				mounting_hole_info += ', plated'
			else:
				mounting_hole_info += ', non plated'
			pad_diameter = ao.units_manager.convert(self.ui_data['padDiameter'], 'cm', unit)
			mounting_hole_info_full = mounting_hole_info + ' with ' + str('{:.2f}'.format(round(pad_diameter,2))) + ' ' + unit  + " mounting pad"
			mounting_hole_info += ' mounting pad'

			if self.ui_data['withVia'] and int(self.ui_data['viaCount']) > 0 and self.ui_data['viaDiameter'] != 0:
				mounting_hole_info += ' and via.'
				via_diameter = ao.units_manager.convert(self.ui_data['viaDiameter'], 'cm', unit)
				mounting_hole_info_full += ' and ' + str('{:.2f}'.format(round(via_diameter,2))) + ' ' + unit + " via."
			else:
				mounting_hole_info += '.'
				mounting_hole_info_full += '.'

		# get the pin pitch
		hole_diameter = ao.units_manager.convert(self.ui_data['holeDiameter'], 'cm', unit)
		body_height = ao.units_manager.convert(self.ui_data['bodyHeightMax'], 'cm', unit)
		body_width = ao.units_manager.convert(self.ui_data['bodyWidthMax'], 'cm', unit)
		post_length = ao.units_manager.convert(self.ui_data['postThreadDepth'], 'cm', unit)
		inner_thread_depth = ao.units_manager.convert(self.ui_data['innerThreadDepth'], 'cm', unit)

		short_description = 'Male-Female ' + self.ui_data['bodyShape'] + ' Standoff/Spacer'
		short_description += ' with ' + str('{:.2f}'.format(round(hole_diameter,4))) + ' ' + unit + ' hole diameter, '
		short_description += str('{:.2f}'.format(round(body_height,2))) + ' ' + unit + ' body height, '
		short_description += str('{:.2f}'.format(round(body_width,2))) + ' ' + unit + ' body width'
		short_description += ' with post thread size ' + self.ui_data['postThreadDesignation']
		short_description += ' and inner thread size ' + self.ui_data['innerThreadDesignation']
		if mounting_hole_info == '':
			short_description += '.'
		else:
			short_description += mounting_hole_info

		full_description = 'Male-Female ' + self.ui_data['bodyShape'] + ' Standoff/Spacer package'
		full_description += ' with ' + str('{:.2f}'.format(round(hole_diameter,4))) + ' ' + unit + ' hole diameter, '
		full_description += str('{:.2f}'.format(round(body_height,2))) + ' ' + unit + ' body height, '
		full_description += str('{:.2f}'.format(round(body_width,2))) + ' ' + unit + ' body width'
		full_description += ' with post thread size ' + self.ui_data['postThreadDesignation'] + ', '
		full_description += str('{:.2f}'.format(round(post_length,2))) + ' ' + unit + ' length and '
		full_description += 'inner thread size ' + self.ui_data['innerThreadDesignation'] + ', '
		full_description += str('{:.2f}'.format(round(inner_thread_depth,2))) + ' ' + unit + ' depth'
		
		if mounting_hole_info_full == '':
			full_description += '.'
		else:
			full_description += mounting_hole_info_full

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "STANDOFF"
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		self.metadata["bodyWidth"] = str(round(ao.units_manager.convert(self.ui_data['bodyWidthMax'], 'cm', 'mm'), 4))
		self.metadata["bodyLength"] = self.metadata["bodyWidth"]
		return self.metadata
	
# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_MALE_FEMALE_STANDOFF, PackageCalculatorMaleFemaleStandoff) 