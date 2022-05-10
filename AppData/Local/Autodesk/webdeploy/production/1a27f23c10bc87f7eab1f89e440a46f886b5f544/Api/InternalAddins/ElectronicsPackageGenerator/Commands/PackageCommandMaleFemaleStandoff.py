import adsk.core
from . import PackageCommand
from ..Utilities import addin_utility,fusion_ui,fusion_model, constant
from ..Utilities.localization import _LCLZ

BODY_SHAPE = {
    'ROUND': 'Round',
    'HEX': 'Hex',
    'SQUARE': 'Square'
}

class PackageCommandMaleFemaleStandoff(PackageCommand.PackageCommand):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)

        #overwrite some specific settings of this command. 
        self.cmd_id = 'cmd_id_male_female_standoff'
        self.cmd_name = _LCLZ('CmdNameMaleFemaleStandoff', 'Male-Female Standoff/Spacer Generator')
        self.cmd_description = _LCLZ('CmdDescMaleFemaleStandoff', 'Generate Male-Female Standoff/Spacer Packages')
        self.cmd_ctrl_id = self.cmd_id
        self.dialog_width = 340
        self.dialog_height = 730

    def get_defalt_ui_data(self):
        #default parameters
        ui_data = {}
        ui_data['type'] = constant.PKG_TYPE_MALE_FEMALE_STANDOFF
        ui_data['cmd_id'] = self.cmd_id
        ui_data['horizontalPadCount'] = 1
        ui_data['silkscreenMappingTypeToBody'] = constant.SILKSCREEN_MAPPING_TO_BODY.get('MappingTypeToBodyNom')
        
        ui_data['holeDiameter'] = 0.35
        ui_data['bodyHeightMax'] = 1.905
        ui_data['bodyWidthMax'] = 0.635
        ui_data['bodyWidthMin'] = 0.635
        ui_data['bodyLengthMax'] = 0.635
        ui_data['bodyLengthMin'] = 0.635
        ui_data['bodyShape'] = BODY_SHAPE['HEX']

        ui_data['innerThreadDepth'] = 0.635
        ui_data['innerThreadType'] = constant.THREAD_TYPES.get('threadType11')
        ui_data['innerThreadSize'] = '3.5'
        ui_data['innerThreadDesignation'] = 'M3.5x0.5'
        ui_data['innerThreadClass'] = '6H'
        ui_data['postThreadDepth'] = 0.635
        ui_data['postThreadType'] = constant.THREAD_TYPES.get('threadType11')
        ui_data['postThreadSize'] = '3.5'
        ui_data['postThreadDesignation'] = 'M3.5x0.5'
        ui_data['postThreadClass'] = '6g'
        # mounting hole parameters
        ui_data['withPad'] = False
        ui_data['padDiameter'] = 0.525
        ui_data['padShape'] = constant.PTH_PAD_SHAPE.get('Round')
        ui_data['plated'] = False
        ui_data['withVia'] = False
        ui_data['viaCount'] = 0
        ui_data['viaDiameter'] = 0
        ui_data['viaCenterOffset'] = 0
        ui_data['viaThermalRelief'] = False
        ui_data['densityLevel'] = 1 # max 2, normal 1, min, 0

        return ui_data

    def update_ui_data(self, inputs):
        # update date from UI inputs
        input_data = self.get_inputs()
        for param in self.ui_data:
            if param in input_data:
                self.ui_data[param] = input_data[param]
        
        self.ui_data['bodyLengthMax'] = self.ui_data['bodyWidthMax']
        self.ui_data['bodyLengthMin'] = self.ui_data['bodyWidthMin']
        self.ui_data['innerThreadType'] = list(constant.THREAD_TYPES.values())[inputs.itemById('innerThreadType').selectedItem.index]
        self.ui_data['postThreadType'] = list(constant.THREAD_TYPES.values())[inputs.itemById('postThreadType').selectedItem.index]
        self.ui_data['padShape'] = list(constant.PTH_PAD_SHAPE.values())[inputs.itemById('padShape').selectedItem.index]
        self.ui_data['bodyShape'] = list(BODY_SHAPE.values())[inputs.itemById('bodyShape').selectedItem.index]

    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        
        super().on_create(command, inputs)

        ao = addin_utility.AppObjects()

        # Create a package tab input.
        tab1_cmd_inputs = inputs.addTabCommandInput('tab_1', _LCLZ('package', 'Package'))
        tab1_inputs = tab1_cmd_inputs.children
        
        # Create image input.
        labeled_image = tab1_inputs.addImageCommandInput('MaleFemaleStandoffImage', '', 'Resources/img/Standoff-Male-Female-Labeled.png')
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

        hole_dia = tab1_inputs.addValueInput('holeDiameter', 'b', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['holeDiameter']))
        hole_dia.tooltip = _LCLZ('holeDiameter', 'Hole Diameter')

        # Create body shape dropdown input 
        body_shape = tab1_inputs.addDropDownCommandInput('bodyShape', _LCLZ('bodyShape', 'Body Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        for t in BODY_SHAPE:
            body_shape.listItems.add(_LCLZ(t, BODY_SHAPE.get(t)), True if BODY_SHAPE.get(t) == self.ui_data['bodyShape'] else False, '')
        body_shape.maxVisibleItems = len(BODY_SHAPE)

        # table
        table = tab1_inputs.addTableCommandInput('bodyDimensionTable', 'Table', 3, '1:2:2')
        table.hasGrid = False
        table.tablePresentationStyle = 2
        table.maximumVisibleRows = 3
        fusion_ui.add_title_to_table(table, '', _LCLZ('min', 'Min'), _LCLZ('max', 'Max'))
        fusion_ui.add_row_to_table(table, 'bodyWidth', 'E', adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMin']), adsk.core.ValueInput.createByReal(self.ui_data['bodyWidthMax']), _LCLZ('bodyWidth', 'Body Width'))
        fusion_ui.add_row_to_table(table, 'bodyHeight', 'A', None, adsk.core.ValueInput.createByReal(self.ui_data['bodyHeightMax']), _LCLZ('bodyHeight', 'Body Height'))

        # get all of the thread information.
        thread_data_query = ao.root_comp.features.threadFeatures.threadDataQuery
        
        inner_thread_depth = tab1_inputs.addValueInput('innerThreadDepth', 'L', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['innerThreadDepth']))
        inner_thread_depth.tooltip = _LCLZ('innerThreadDepth', 'Inner Thread Depth')
        # create thread type input
        inner_thread_type_input = tab1_inputs.addDropDownCommandInput('innerThreadType', _LCLZ('innerThreadType', 'Inner Thread Type'), adsk.core.DropDownStyles.TextListDropDownStyle)
        #if self.ui_data['innerThreadType'] not in constant.THREAD_TYPES :
        #    self.ui_data['innerThreadType'] = constant.THREAD_TYPES.get('threadType1') # get the first type as the defalt one
        for t in constant.THREAD_TYPES:
            inner_thread_type_input.listItems.add(_LCLZ(t, constant.THREAD_TYPES.get(t)), True if constant.THREAD_TYPES.get(t) == self.ui_data['innerThreadType'] else False, '') 
        inner_thread_type_input.maxVisibleItems = len(constant.THREAD_TYPES) if len(constant.THREAD_TYPES)< 10 else 10

        # create thread size input
        all_sizes = thread_data_query.allSizes(self.ui_data['innerThreadType'])
        inner_thread_size_input = tab1_inputs.addDropDownCommandInput('innerThreadSize', _LCLZ('innerThreadSize', 'Inner Thread Size'), adsk.core.DropDownStyles.TextListDropDownStyle)
        if self.ui_data['innerThreadSize'] not in all_sizes :
            self.ui_data['innerThreadSize'] = all_sizes[0] # get the first as the defalt one
        for t in all_sizes:
            inner_thread_size_input.listItems.add(t, True if t == self.ui_data['innerThreadSize'] else False, '')
        inner_thread_size_input.maxVisibleItems = len(all_sizes) if len(all_sizes)< 10 else 10

        # create thread designation input
        all_designations = thread_data_query.allDesignations(self.ui_data['innerThreadType'], self.ui_data['innerThreadSize'])
        inner_thread_designation_input = tab1_inputs.addDropDownCommandInput('innerThreadDesignation', _LCLZ('innerThreadDesignation', 'Inner Thread Designation'), adsk.core.DropDownStyles.TextListDropDownStyle)
        if self.ui_data['innerThreadDesignation'] not in all_designations :
            self.ui_data['innerThreadDesignation'] = all_designations[0] # get the first as the defalt one
        for t in all_designations:
            inner_thread_designation_input.listItems.add(t, True if t == self.ui_data['innerThreadDesignation'] else False, '')        
        inner_thread_designation_input.maxVisibleItems = len(all_designations) if len(all_designations)< 10 else 10

        # create thread class input
        all_classes = thread_data_query.allClasses(True, self.ui_data['innerThreadType'], self.ui_data['innerThreadDesignation'])
        inner_thread_class_input = tab1_inputs.addDropDownCommandInput('innerThreadClass', _LCLZ('innerThreadClass', 'Inner Thread Class'), adsk.core.DropDownStyles.TextListDropDownStyle)
        if self.ui_data['innerThreadClass'] not in all_classes :
            self.ui_data['innerThreadClass'] = all_classes[0] # get the first as the defalt one
        for t in all_classes:
            inner_thread_class_input.listItems.add(t, True if t == self.ui_data['innerThreadClass'] else False, '')  
        inner_thread_class_input.maxVisibleItems = len(all_classes) if len(all_classes)< 10 else 10

        post_thread_depth = tab1_inputs.addValueInput('postThreadDepth', 'L1', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['postThreadDepth']))
        post_thread_depth.tooltip = _LCLZ('postLength', 'Post Length')
        post_thread_type_input = tab1_inputs.addDropDownCommandInput('postThreadType', _LCLZ('postThreadType', 'Post Thread Type'), adsk.core.DropDownStyles.TextListDropDownStyle)
        #if self.ui_data['postThreadType'] not in constant.THREAD_TYPES :
        #    self.ui_data['postThreadType'] = constant.THREAD_TYPES['threadType1'] # get the first type as the defalt one
        for t in constant.THREAD_TYPES:
            post_thread_type_input.listItems.add(_LCLZ(t, constant.THREAD_TYPES.get(t)), True if constant.THREAD_TYPES.get(t) == self.ui_data['postThreadType'] else False, '') 
        post_thread_type_input.maxVisibleItems = len(constant.THREAD_TYPES) if len(constant.THREAD_TYPES)< 10 else 10

        # create thread size input
        all_sizes = thread_data_query.allSizes(self.ui_data['postThreadType'])
        post_thread_size_input = tab1_inputs.addDropDownCommandInput('postThreadSize', _LCLZ('postThreadSize', 'Post Thread Size'), adsk.core.DropDownStyles.TextListDropDownStyle)
        if self.ui_data['postThreadSize'] not in all_sizes :
            self.ui_data['postThreadSize'] = all_sizes[0] # get the first as the defalt one
        for t in all_sizes:
            post_thread_size_input.listItems.add(t, True if t == self.ui_data['postThreadSize'] else False, '')
        post_thread_size_input.maxVisibleItems = len(all_sizes) if len(all_sizes)< 10 else 10

        # create thread designation input
        all_designations = thread_data_query.allDesignations(self.ui_data['postThreadType'], self.ui_data['postThreadSize'])
        post_thread_designation_input = tab1_inputs.addDropDownCommandInput('postThreadDesignation', _LCLZ('postThreadDesignation', 'Post Thread Designation'), adsk.core.DropDownStyles.TextListDropDownStyle)
        if self.ui_data['postThreadDesignation'] not in all_designations :
            self.ui_data['postThreadDesignation'] = all_designations[0] # get the first as the defalt one
        for t in all_designations:
            post_thread_designation_input.listItems.add(t, True if t == self.ui_data['postThreadDesignation'] else False, '')
        post_thread_designation_input.maxVisibleItems = len(all_designations) if len(all_designations)< 10 else 10

        # create thread class input
        all_classes = thread_data_query.allClasses(False, self.ui_data['postThreadType'], self.ui_data['postThreadDesignation'])
        post_thread_class_input = tab1_inputs.addDropDownCommandInput('postThreadClass', _LCLZ('postThreadClass', 'Post Thread Class'), adsk.core.DropDownStyles.TextListDropDownStyle)
        if self.ui_data['postThreadClass'] not in all_classes :
            self.ui_data['postThreadClass'] = all_classes[0] # get the first as the defalt one
        for t in all_classes:
            post_thread_class_input.listItems.add(t, True if t == self.ui_data['postThreadClass'] else False, '')  
        post_thread_class_input.maxVisibleItems = len(all_classes) if len(all_classes)< 10 else 10

        # Create a mounting hole pad tab input.
        tab2_cmd_inputs = inputs.addTabCommandInput('tab_2', _LCLZ('mountingHolePad', 'Mounting Hole Pad'))
        tab2_inputs = tab2_cmd_inputs.children
        tab2_cmd_inputs.isVisible = not self.only_3d_model_generator

        # Create image input.
        enable_mounting_hole = tab2_inputs.addBoolValueInput('withPad', _LCLZ('mountingHolePad', 'Mounting Hole Pad'), True, '', self.ui_data['withPad'])
        
        labeled_image = tab2_inputs.addImageCommandInput('FemaleStandoffImage', '', 'Resources/img/Standoff-Male-Female-Labeled.png')
        labeled_image.isFullWidth = True
        labeled_image.isVisible = True

        # pad shape
        pad_shape = tab2_inputs.addDropDownCommandInput('padShape', _LCLZ('padShape', 'Pad Shape'), adsk.core.DropDownStyles.TextListDropDownStyle)
        pad_shape_list = pad_shape.listItems
        pad_shape_list.add(_LCLZ('Round', constant.PTH_PAD_SHAPE.get('Round')), True if constant.PTH_PAD_SHAPE.get("Round") == self.ui_data['padShape'] else False, "")
        pad_shape_list.add(_LCLZ('Square', constant.PTH_PAD_SHAPE.get('Square')), True if constant.PTH_PAD_SHAPE.get("Square") == self.ui_data['padShape'] else False, "")    
        pad_shape.isEnabled = enable_mounting_hole.value
        pad_shape.maxVisibleItems = 2

        pad_dia = tab2_inputs.addValueInput('padDiameter', 'E1', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['padDiameter']))
        pad_dia.isEnabled = enable_mounting_hole.value
        pad_dia.tooltip = _LCLZ('padWidth', 'Pad Width')

        is_plated = tab2_inputs.addBoolValueInput('plated', _LCLZ('plated', 'plated'), True, '', self.ui_data['plated'])
        is_plated.isEnabled = enable_mounting_hole.value

        with_via = tab2_inputs.addBoolValueInput('withVia', _LCLZ('withVias', 'With Vias'), True, '', self.ui_data['withVia'])
        with_via.isEnabled = enable_mounting_hole.value

        via_count = tab2_inputs.addIntegerSpinnerCommandInput('viaCount', _LCLZ('viaCount', 'Vias Count'), 0 , 50 , 1, int(self.ui_data['viaCount']))
        via_count.isVisible = with_via.value

        via_dia = tab2_inputs.addValueInput('viaDiameter', 'b2', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['viaDiameter']))
        via_dia.isVisible = with_via.value
        via_dia.tooltip = _LCLZ('viaDiameter', 'Via Diameter')

        via_offset = tab2_inputs.addValueInput('viaCenterOffset', 'E2', ao.units_manager.defaultLengthUnits, adsk.core.ValueInput.createByReal(self.ui_data['viaCenterOffset']))
        via_offset.isVisible = with_via.value
        via_offset.tooltip = _LCLZ('viaOffset', 'Via Offset From Hole Center')


        via_thermal_relief = tab2_inputs.addBoolValueInput('viaThermalRelief', _LCLZ('viaThermalRelief', 'Via Thermal Relief'), True, '', self.ui_data['viaThermalRelief'])
        via_thermal_relief.isEnabled = enable_mounting_hole.value
        via_thermal_relief.isVisible = with_via.value


    def on_validate_inputs(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs,args: adsk.core.ValidateInputsEventArgs):
        ao = addin_utility.AppObjects()
        thread_data_query = ao.root_comp.features.threadFeatures.threadDataQuery
        hole_diameter = inputs.itemById('holeDiameter').value 

        #validate the innner thread type
        inner_thread_type_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('innerThreadType'))
        selected_thread_type = list(constant.THREAD_TYPES.values())[inputs.itemById('innerThreadType').selectedItem.index]
        #try to get the recommend thread data.        
        try:
            result = thread_data_query.recommendThreadData(hole_diameter, True, selected_thread_type)
            args.areInputsValid = True
        except:
            args.areInputsValid = False
            return

        #validate the post thread type
        post_thread_type_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('postThreadType'))
        selected_thread_type = list(constant.THREAD_TYPES.values())[inputs.itemById('postThreadType').selectedItem.index]
        #try to get the recommend thread data.        
        try:
            result = thread_data_query.recommendThreadData(hole_diameter, False, selected_thread_type)
            args.areInputsValid = True
        except:
            args.areInputsValid = False

    def on_input_changed(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs, changed_input: adsk.core.CommandInput, input_values: dict ):
        
        super().on_input_changed(command, inputs, changed_input, input_values)
        
        # get all of the thread information.
        ao = addin_utility.AppObjects()
        thread_data_query = ao.root_comp.features.threadFeatures.threadDataQuery

        if changed_input.id == 'withPad':
            inputs.itemById('padShape').isEnabled = changed_input.value
            inputs.itemById('padDiameter').isEnabled = changed_input.value
            inputs.itemById('plated').isEnabled = changed_input.value
            inputs.itemById('withVia').isEnabled = changed_input.value
            inputs.itemById('viaCount').isEnabled = changed_input.value
            inputs.itemById('viaDiameter').isEnabled = changed_input.value
            inputs.itemById('viaCenterOffset').isEnabled = changed_input.value
            inputs.itemById('viaThermalRelief').isEnabled = changed_input.value
        if changed_input.id == 'withVia':
            inputs.itemById('viaCount').isVisible = changed_input.value
            inputs.itemById('viaDiameter').isVisible = changed_input.value
            inputs.itemById('viaCenterOffset').isVisible = changed_input.value
            inputs.itemById('viaThermalRelief').isVisible = changed_input.value

        
        # update the inner thread related UIs
        if changed_input.id == 'innerThreadType':
            # update the thread type            
            thread_type_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('innerThreadType'))
            selected_thread_type = list(constant.THREAD_TYPES.values())[inputs.itemById('innerThreadType').selectedItem.index]
            
            #try to get the recommend thread data.
            hole_diameter = inputs.itemById('holeDiameter').value
            all_sizes = thread_data_query.allSizes(selected_thread_type)
            thread_unit = thread_data_query.threadTypeUnit(selected_thread_type)
            try:
                result = thread_data_query.recommendThreadData(hole_diameter, True, selected_thread_type)
                if result[0] == True:
                    self.ui_data['innerThreadDesignation'] = result[1]
                    self.ui_data['innerThreadClass'] = result[2]
                #set regenrate model for non parametric updates. 
                self.reset_regenerate_flag('innerThreadType', selected_thread_type)
                self.ui_data['innerThreadType'] =  selected_thread_type              
            except:
                ao.ui.messageBox('Cannot find suitable thread for the type - ' + selected_thread_type + '.')
                return

            # update thread size input
            # all_sizes = thread_data_query.allSizes(self.ui_data['innerThreadType'])
            thread_size_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('innerThreadSize'))
            thread_size_input.listItems.clear()
            self.ui_data['innerThreadSize'] = fusion_model.find_proper_thread_size(hole_diameter,thread_unit,all_sizes)# get the proper sizes as the defalt one
            if self.ui_data['innerThreadSize'] not in all_sizes :
                self.ui_data['innerThreadSize'] = all_sizes[0] # get the first as the defalt one
            for t in all_sizes:
                thread_size_input.listItems.add(t, True if t == self.ui_data['innerThreadSize'] else False, '') 

            # update thread designation input
            all_designations = thread_data_query.allDesignations(self.ui_data['innerThreadType'], self.ui_data['innerThreadSize'])
            thread_designation_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('innerThreadDesignation'))
            thread_designation_input.listItems.clear()
            if self.ui_data['innerThreadDesignation'] not in all_designations :
                self.ui_data['innerThreadDesignation'] = all_designations[0] # get the first as the defalt one
            for t in all_designations:
                thread_designation_input.listItems.add(t, True if t == self.ui_data['innerThreadDesignation'] else False, '')         
        
            # update thread class input
            all_classes = thread_data_query.allClasses(True, self.ui_data['innerThreadType'], self.ui_data['innerThreadDesignation'])
            thread_class_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('innerThreadClass'))
            thread_class_input.listItems.clear()
            if self.ui_data['innerThreadClass'] not in all_classes :
                self.ui_data['innerThreadClass'] = all_classes[0] # get the first as the defalt one
            for t in all_classes:
                thread_class_input.listItems.add(t, True if t == self.ui_data['innerThreadClass'] else False, '')  

        if changed_input.id == 'innerThreadSize':
            # update thread size input
            thread_size_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('innerThreadSize'))
            #set regenrate model for non parametric updates. 
            self.reset_regenerate_flag('innerThreadSize', thread_size_input.selectedItem.name)
            self.ui_data['innerThreadSize'] = thread_size_input.selectedItem.name

            # update thread designation input
            all_designations = thread_data_query.allDesignations(self.ui_data['innerThreadType'], self.ui_data['innerThreadSize'])
            thread_designation_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('innerThreadDesignation'))
            thread_designation_input.listItems.clear()
            if self.ui_data['innerThreadDesignation'] not in all_designations :
                self.ui_data['innerThreadDesignation'] = all_designations[0] # get the first as the defalt one
            for t in all_designations:
                thread_designation_input.listItems.add(t, True if t == self.ui_data['innerThreadDesignation'] else False, '')         
        
            # update thread class input
            all_classes = thread_data_query.allClasses(True, self.ui_data['innerThreadType'], self.ui_data['innerThreadDesignation'])
            thread_class_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('innerThreadClass'))
            thread_class_input.listItems.clear()
            if self.ui_data['innerThreadClass'] not in all_classes :
                self.ui_data['innerThreadClass'] = all_classes[0] # get the first as the defalt one
            for t in all_classes:
                thread_class_input.listItems.add(t, True if t == self.ui_data['innerThreadClass'] else False, '') 

        if changed_input.id == 'innerThreadDesignation':
            # update thread designation input
            thread_designation_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('innerThreadDesignation'))
            #set regenrate model for non parametric updates.
            self.reset_regenerate_flag('innerThreadDesignation', thread_designation_input.selectedItem.name)
            self.ui_data['innerThreadDesignation'] = thread_designation_input.selectedItem.name
        
            # update thread class input
            all_classes = thread_data_query.allClasses(True, self.ui_data['innerThreadType'], self.ui_data['innerThreadDesignation'])
            thread_class_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('innerThreadClass'))
            thread_class_input.listItems.clear()
            if self.ui_data['innerThreadClass'] not in all_classes :
                self.ui_data['innerThreadClass'] = all_classes[0] # get the first as the defalt one
            for t in all_classes:
                thread_class_input.listItems.add(t, True if t == self.ui_data['innerThreadClass'] else False, '')    

        # update the post thread related UIs
        if changed_input.id == 'postThreadType':
            # update the thread type            
            thread_type_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('postThreadType'))
            selected_thread_type = list(constant.THREAD_TYPES.values())[inputs.itemById('postThreadType').selectedItem.index]

            #try to get the recommend thread data.
            hole_diameter = inputs.itemById('holeDiameter').value
            all_sizes = thread_data_query.allSizes(selected_thread_type)
            thread_unit = thread_data_query.threadTypeUnit(selected_thread_type)                 
            try:
                result = thread_data_query.recommendThreadData(hole_diameter, False, selected_thread_type)
                if result[0] == True:
                    self.ui_data['postThreadDesignation'] = result[1]
                    self.ui_data['postThreadClass'] = result[2]
                #set regenrate model for non parametric updates. 
                self.reset_regenerate_flag('postThreadType', selected_thread_type)
                self.ui_data['postThreadType'] = selected_thread_type
            except:
                ao.ui.messageBox('Cannot find suitable thread for the type - ' + selected_thread_type + '.')
                return
                    
            # update thread size input
            # all_sizes = thread_data_query.allSizes(self.ui_data['postThreadType'])
            thread_size_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('postThreadSize'))
            thread_size_input.listItems.clear()
            self.ui_data['postThreadSize'] = fusion_model.find_proper_thread_size(hole_diameter,thread_unit,all_sizes)# get the proper sizes as the defalt one
            if self.ui_data['postThreadSize'] not in all_sizes :
                self.ui_data['postThreadSize'] = all_sizes[0] # get the first as the defalt one
            for t in all_sizes:
                thread_size_input.listItems.add(t, True if t == self.ui_data['postThreadSize'] else False, '') 

            # update thread designation input
            all_designations = thread_data_query.allDesignations(self.ui_data['postThreadType'], self.ui_data['postThreadSize'])
            thread_designation_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('postThreadDesignation'))
            thread_designation_input.listItems.clear()
            if self.ui_data['postThreadDesignation'] not in all_designations :
                self.ui_data['postThreadDesignation'] = all_designations[0] # get the first as the defalt one
            for t in all_designations:
                thread_designation_input.listItems.add(t, True if t == self.ui_data['postThreadDesignation'] else False, '')         
        
            # update thread class input
            all_classes = thread_data_query.allClasses(False, self.ui_data['postThreadType'], self.ui_data['postThreadDesignation'])
            thread_class_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('postThreadClass'))
            thread_class_input.listItems.clear()
            if self.ui_data['postThreadClass'] not in all_classes :
                self.ui_data['postThreadClass'] = all_classes[0] # get the first as the defalt one
            for t in all_classes:
                thread_class_input.listItems.add(t, True if t == self.ui_data['postThreadClass'] else False, '')  

        if changed_input.id == 'postThreadSize':
            # update thread size input
            thread_size_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('postThreadSize'))
            #set regenrate model for non parametric updates. 
            self.reset_regenerate_flag('postThreadSize', thread_size_input.selectedItem.name)   
            self.ui_data['postThreadSize'] = thread_size_input.selectedItem.name

            # update thread designation input
            all_designations = thread_data_query.allDesignations(self.ui_data['postThreadType'], self.ui_data['postThreadSize'])
            thread_designation_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('postThreadDesignation'))
            thread_designation_input.listItems.clear()
            if self.ui_data['postThreadDesignation'] not in all_designations :
                self.ui_data['postThreadDesignation'] = all_designations[0] # get the first as the defalt one
            for t in all_designations:
                thread_designation_input.listItems.add(t, True if t == self.ui_data['postThreadDesignation'] else False, '')         
        
            # update thread class input
            all_classes = thread_data_query.allClasses(False, self.ui_data['postThreadType'], self.ui_data['postThreadDesignation'])
            thread_class_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('postThreadClass'))
            thread_class_input.listItems.clear()
            if self.ui_data['postThreadClass'] not in all_classes :
                self.ui_data['postThreadClass'] = all_classes[0] # get the first as the defalt one
            for t in all_classes:
                thread_class_input.listItems.add(t, True if t == self.ui_data['postThreadClass'] else False, '')            

        if changed_input.id == 'postThreadDesignation':
            # update thread designation input
            thread_designation_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('postThreadDesignation'))
            #set regenrate model for non parametric updates.
            self.reset_regenerate_flag('postThreadDesignation', thread_designation_input.selectedItem.name)    
            self.ui_data['postThreadDesignation'] = thread_designation_input.selectedItem.name
        
            # update thread class input
            all_classes = thread_data_query.allClasses(False, self.ui_data['postThreadType'], self.ui_data['postThreadDesignation'])
            thread_class_input = adsk.core.DropDownCommandInput.cast(inputs.itemById('postThreadClass'))
            thread_class_input.listItems.clear()
            if self.ui_data['postThreadClass'] not in all_classes :
                self.ui_data['postThreadClass'] = all_classes[0] # get the first as the defalt one
            for t in all_classes:
                thread_class_input.listItems.add(t, True if t == self.ui_data['postThreadClass'] else False, '')    

        if changed_input.id == 'bodyShape':
            #set regenrate model for non parametric updates.
            body_shape = list(BODY_SHAPE.values())[inputs.itemById('bodyShape').selectedItem.index] 
            self.reset_regenerate_flag('bodyShape', body_shape)    
   
# register the calculator into the factory. 
PackageCommand.cmd_factory.register_command(constant.PKG_TYPE_MALE_FEMALE_STANDOFF, PackageCommandMaleFemaleStandoff) 
           