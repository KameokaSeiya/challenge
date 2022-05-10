# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import adsk.core
import math
import os
from . import footprint
from ..Utilities import fusion_sketch, constant
from xml.etree import ElementTree as ET


class FootprintGenerator(object):

    def __init__(self):
        self.footprint_list = []
        self.package_name = ""
        self.package_description = ""

    def insert_footprint_element(self, footprint_elem):
        if issubclass(footprint_elem, footprint.FootprintElement):
            footprint.append(footprint_elem)
        
    def draw_footprint(self, design):
        root_comp = design.rootComponent
        pad_sketch = root_comp.sketches.itemByName(constant.SKETCH_NAME_FOOTPRINT)
        if pad_sketch == None:
            # Create a new sketches on the xy plane
            sketches = root_comp.sketches
            pad_sketch = sketches.add(root_comp.xYConstructionPlane)
            pad_sketch.name = constant.SKETCH_NAME_FOOTPRINT
        pad_sketch.isComputeDeferred = True
        for elem in self.footprint_list:
            if  isinstance(elem, footprint.FootprintPad) or isinstance(elem, footprint.FootprintSmd):
                elem.draw(pad_sketch)
        pad_sketch.isComputeDeferred = False

        # Use existing silkscreen sketch (always exists in package document)
        silkscreen_sketch = root_comp.sketches.itemByName(constant.SKETCH_NAME_SILKSCREEN)
        silkscreen_sketch.isComputeDeferred = True
        for elem in self.footprint_list:
            if  isinstance(elem, footprint.FootprintCircle) or isinstance(elem, footprint.FootprintWire):
                elem.draw(silkscreen_sketch)
        silkscreen_sketch.isComputeDeferred = False

        # Reuse text sketch if it exists otherwise create new
        text_sketch = root_comp.sketches.itemByName(constant.SKETCH_NAME_TEXT)
        if text_sketch == None:
            # Create a new sketches on the xy plane
            sketches = root_comp.sketches
            text_sketch = sketches.add(root_comp.xYConstructionPlane)
            text_sketch.name = constant.SKETCH_NAME_TEXT
        text_sketch.isComputeDeferred = True
        for elem in self.footprint_list:
            if  isinstance(elem, footprint.FootprintText):
                elem.draw(text_sketch)
        text_sketch.isComputeDeferred = False
        
    # delete all the footprint elements in the target component
    def remove_footprint(self, target_comp):
        # remove all the entities in pad sketch
        pad_sketch = target_comp.sketches.itemByName(constant.SKETCH_NAME_FOOTPRINT)
        if pad_sketch != None:
            pad_sketch.isComputeDeferred = True
            fusion_sketch.clear_sketch_entities(target_comp,constant.SKETCH_NAME_FOOTPRINT)
            pad_sketch.isComputeDeferred = False

        # remove all the entities in silkscreen sketch
        silkscreen_sketch = target_comp.sketches.itemByName(constant.SKETCH_NAME_SILKSCREEN)
        if silkscreen_sketch != None:
            silkscreen_sketch.isComputeDeferred = True
            fusion_sketch.clear_sketch_entities(target_comp,constant.SKETCH_NAME_SILKSCREEN)
            silkscreen_sketch.isComputeDeferred = False

        # remove all the entities in text sketch
        text_sketch = target_comp.sketches.itemByName(constant.SKETCH_NAME_TEXT)
        if text_sketch != None:
            text_sketch.isComputeDeferred = True
            fusion_sketch.clear_sketch_texts(target_comp,constant.SKETCH_NAME_TEXT)
            text_sketch.isComputeDeferred = False



    def does_footprint_exists(self, target_comp):
        # check for pads
        pad_sketch = target_comp.sketches.itemByName(constant.SKETCH_NAME_FOOTPRINT)
        if pad_sketch and pad_sketch.sketchCurves.count > 0:
            return True
        else:
            # check for silkscreens
            silkscreen_sketch = target_comp.sketches.itemByName(constant.SKETCH_NAME_SILKSCREEN)
            if silkscreen_sketch and silkscreen_sketch.sketchCurves.count > 0:
                return True
            else:
                # check for texts
                text_sketch = target_comp.sketches.itemByName(constant.SKETCH_NAME_TEXT)
                if text_sketch and text_sketch.sketchTexts.count > 0:
                    return True
                else:
                    return False

    def get_footprint_xml(self):
        root_node = ET.Element('package',{'name':self.package_name})
        tree = ET.ElementTree(root_node)
        # generate descrition node
        node_description = ET.Element('description')
        node_description.text = self.package_description
        root_node.append(node_description)

        #generate footprint data node
        for elem in self.footprint_list:           
            node_footprint = elem.export_xml_node()
            if node_footprint != None:
                root_node.append(node_footprint)
        
        #tree.write("c:\\temp\\test.xml", 'utf8')
        xml_string = ET.tostring(root_node,encoding='unicode') #unicode is used to get string instead of bytestring
        return xml_string
