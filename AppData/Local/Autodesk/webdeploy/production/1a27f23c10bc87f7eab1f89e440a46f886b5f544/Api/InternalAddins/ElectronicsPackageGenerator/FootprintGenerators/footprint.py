# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
import adsk.core, adsk.fusion
from ..Utilities import addin_utility
from ..Utilities import fusion_sketch
from xml.etree import ElementTree as ET


# only draw the footprint on specific layers 
DRAW_LAYERS = [1, 21, 25, 27]

class BoundingBox(object):

    def __init__(self, x_min = 0, y_min = 0, x_max = 0, y_max = 0):
        self.x_min = x_min
        self.y_min = y_min
        self.x_max = x_max
        self.y_max = y_max

# the base class of all the footprint element
class FootprintElement(object):
    
    # draw the footprint object in the specified sketch
    def draw (self, sketch):
        raise AssertionError

    # export data to xml element 
    def export_xml_node(self):
        raise AssertionError

    # retune the geometry bounding box
    def bounding_box(self):
        raise AssertionError

# the footprint plated through hold pad
class FootprintPad(FootprintElement):
    # initialize the data members
    def __init__(self, point_x = 0, point_y = 0, dia = 0, drill_dia = 0):
        self.center_point_x = point_x
        self.center_point_y = point_y
        self.name = ''
        self.drill = drill_dia
        self.diameter = dia
        self.shape = 'Round'
        self.rotation = None
        self.thermals = None

    def draw(self, sketch): 
        pad_center = adsk.core.Point3D.create(self.center_point_x, self.center_point_y, 0)
        # Draw drill outlines
        if self.drill != 0:
            fusion_sketch.draw_circle_center_radius(sketch, pad_center, self.drill/2, True, True)

        # Draw pad outlines
        if self.shape == 'Square':# Square Pad
            fusion_sketch.draw_two_point_rectangle(sketch, self.center_point_x, self.center_point_y, self.diameter, self.diameter, self.rotation, True, True)
        else:# Circular Pad 
            fusion_sketch.draw_circle_center_radius(sketch, pad_center, self.diameter/2, True, True)

    def export_xml_node(self):
        node_attributes = {}
        # convert the internal unit-cm to mm which follow the electronic default unit
        node_attributes['name'] = self.name
        node_attributes['x'] = str('{:.4f}'.format(round(self.center_point_x*10,4)))
        node_attributes['y'] = str('{:.4f}'.format(round(self.center_point_y*10,4)))
        node_attributes['drill'] = str('{:.4f}'.format(round(self.drill*10,4)))
        node_attributes['diameter'] = str('{:.4f}'.format(round( self.diameter*10,4)))
        node_attributes['shape'] = self.shape.lower()
        if self.rotation != None:
            node_attributes['rotation'] = str('{:.4f}'.format(round( self.rotation,4)))
        if self.thermals != None:
            node_attributes['thermals'] = self.thermals
        return ET.Element('pad', node_attributes)
    
    def bounding_box(self):
        x_min = self.center_point_x - self.diameter/2
        y_min = self.center_point_y - self.diameter/2
        x_max = self.center_point_x + self.diameter/2
        y_max = self.center_point_y + self.diameter/2
        return BoundingBox(x_min, y_min, x_max, y_max)

# the footprint plated through hold pad
class FootprintSmd(FootprintElement) :
    def __init__(self, point_x = 0, point_y = 0, width = 0, height = 0):
        self.center_point_x = point_x
        self.center_point_y = point_y
        self.width = width
        self.height = height
        self.angle = None
        self.roundness = None
        self.layer = 1
        self.name = ''
        self.thermals = None
        self.cream = None

    def draw(self, sketch): 
        if not self.roundness :
            fusion_sketch.draw_two_point_rectangle(sketch, self.center_point_x, self.center_point_y, self.width, self.height, self.angle, True, True)
        else :
            # Circular pad (Eagle uses roundness 100% for circular pad exported from cio-datamodel)
            if self.width == self.height and self.roundness == 100: 
                pad_center = adsk.core.Point3D.create(self.center_point_x, self.center_point_y, 0)
                fusion_sketch.draw_circle_center_radius(sketch, pad_center, self.width / 2, True, True)
            else:# Oblong Pad  
                fusion_sketch.draw_pad_with_round_corner(sketch, self.center_point_x, self.center_point_y, self.width, self.height, self.roundness, self.angle, True, True)

    def export_xml_node(self):
        node_attributes = {}
        # convert the internal unit-cm to mm which follow the electronic default unit
        node_attributes['name'] = self.name
        node_attributes['x'] = str('{:.4f}'.format(round(self.center_point_x*10,4)))
        node_attributes['y'] = str('{:.4f}'.format(round(self.center_point_y*10,4)))
        node_attributes['dx'] = str('{:.4f}'.format(round(self.width*10,4)))
        node_attributes['dy'] = str('{:.4f}'.format(round(self.height*10,4)))
        node_attributes['layer'] = str(self.layer)
        if self.angle != None:
            node_attributes['rot'] = self.angle
        if self.roundness != None:
            node_attributes['roundness'] = str(self.roundness)
        if self.thermals != None:
            node_attributes['thermals'] = self.thermals
        if self.cream != None:
            node_attributes['cream'] = self.cream

        return ET.Element('smd', node_attributes)

    def bounding_box(self):
        x_min = self.center_point_x - self.width/2
        y_min = self.center_point_y - self.height/2
        x_max = self.center_point_x + self.width/2
        y_max = self.center_point_y + self.height/2        
        
        if self.angle != None : 
            angle_rad = math.radians(float(self.angle[1:]))
            #x2 = cos(q)(x1-x0) – sin(q)(y1-y0) + x0;
            #y2 = sin(q)(x1-x0) + cos(q)(y1-y0) + y0;
            new_x1 = - math.cos(angle_rad) * self.width/2 - math.sin(angle_rad)*self.height/2 + self.center_point_x
            new_x2 = math.cos(angle_rad) * self.width/2  - math.sin(angle_rad)*self.height/2 + self.center_point_x
            new_x3 = math.cos(angle_rad) * self.width/2  + math.sin(angle_rad)*self.height/2 + self.center_point_x
            new_x4 = - math.cos(angle_rad) * self.width/2  + math.sin(angle_rad)*self.height/2 + self.center_point_x

            new_y1 = - math.sin(angle_rad) * self.width/2 + math.cos(angle_rad)*self.height/2  + self.center_point_y
            new_y2 = math.sin(angle_rad) * self.width/2 + math.cos(angle_rad)*self.height/2  + self.center_point_y
            new_y3 = - math.sin(angle_rad) * self.width/2 - math.cos(angle_rad)*self.height/2  + self.center_point_y
            new_y4 = math.sin(angle_rad) * self.width/2 - math.cos(angle_rad)*self.height/2  + self.center_point_y

            x_min = min(min(new_x1,new_x2), min(new_x3,new_x4))
            x_max = max(max(new_x1,new_x2), max(new_x3,new_x4))
            y_min = min(min(new_y1,new_y2), min(new_y3,new_y4))
            y_max = max(max(new_y1,new_y2), max(new_y3,new_y4))

        return BoundingBox(x_min, y_min, x_max, y_max)

# the footprint wire object
class FootprintWire(FootprintElement):
    # initialize the data members
    def __init__(self, start_x = 0, start_y = 0, end_x = 0, end_y = 0, stroke_width = 0 ):
        self.x1 = start_x
        self.y1 = start_y
        self.x2 = end_x
        self.y2 = end_y
        self.width = stroke_width
        self.cap = 'round'
        self.layer = 21
        self.curve = None

    def draw(self, sketch): 
        if self.layer not in DRAW_LAYERS: return

        p1 = adsk.core.Point3D.create(self.x1, self.y1, 0)
        p2 = adsk.core.Point3D.create(self.x2, self.y2, 0)

        if self.curve == None:
            sketch_lines = sketch.sketchCurves.sketchLines
            line = sketch_lines.addByTwoPoints(p1, p2)
            line.startSketchPoint.isFixed = True
            line.endSketchPoint.isFixed = True
            line.isFixed = True
        else:
            # p2 is start point and p1 is end point
            dy = self.y1 - self.y2
            dx = self.x1 - self.x2
            chord_length = math.sqrt(dx * dx + dy * dy)
            chord_angle = math.atan2(dy, dx)
            arc_angle = float(self.curve) * (math.pi / 180.0)
            radius = chord_length / (2.0 * math.sin(arc_angle / 2.0))
            start_angle = math.pi / 2.0 - arc_angle / 2.0 - chord_angle
            center = adsk.core.Point3D.create(self.x2 + radius * math.cos(start_angle), self.y2 - radius * math.sin(start_angle), 0)
            
            sketch_arcs = sketch.sketchCurves.sketchArcs
            arc = sketch_arcs.addByCenterStartSweep(center, p2, -arc_angle)
            arc.startSketchPoint.isFixed = True
            arc.endSketchPoint.isFixed = True
            arc.isFixed = True
    
    def export_xml_node(self):
        node_attributes = {}
        # convert the internal unit-cm to mm which follow the electronic default unit
        node_attributes['x1'] = str('{:.4f}'.format(round(self.x1*10,4)))
        node_attributes['y1'] = str('{:.4f}'.format(round(self.y1*10,4)))
        node_attributes['x2'] = str('{:.4f}'.format(round(self.x2*10,4)))
        node_attributes['y2'] = str('{:.4f}'.format(round(self.y2*10,4)))
        node_attributes['width'] = str('{:.4f}'.format(round(self.width*10,4)))
        node_attributes['layer'] = str(self.layer)
        node_attributes['cap'] = self.cap
        if self.curve != None:
            node_attributes['curve'] = str('{:.4f}'.format(round(self.curve,4)))
        return ET.Element('wire', node_attributes)

    def bounding_box(self):
        x_min = min(self.x1, self.x2)
        y_min = min(self.y1, self.y2)
        x_max = max(self.x1, self.x2)
        y_max = max(self.y1, self.y2)
        if self.curve != None:
            # p2 is start point and p1 is end point
            dy = self.y1 - self.y2
            dx = self.x1 - self.x2
            chord_length = math.sqrt(dx * dx + dy * dy)
            chord_angle = math.atan2(dy, dx)
            arc_angle = float(self.curve) * (math.pi / 180.0)
            radius = chord_length / (2.0 * math.sin(arc_angle / 2.0))
            start_angle = math.pi / 2.0 - arc_angle / 2.0 - chord_angle
            cx = self.x2 + radius * math.cos(start_angle)
            cy = self.y2 - radius * math.sin(start_angle)
            sx = (self.x2 + self.x1) / 2.0
            sy = (self.y2 + self.y1) / 2.0
            s1_x = (self.x1 + sx) / 2.0
            s1_y = (self.y1 + sy) / 2.0
            s2_x = (sx + self.x2) / 2.0
            s2_y = (sy + self.y2) / 2.0

            #get three equal distance arc points along arc.
            if arc_angle == math.pi or arc_angle == -math.pi: #Calcalate only one mid point for semi arc.
                x_arc,y_arc = addin_utility.get_arc_center(self.x1, self.y1, sx, sy, radius, arc_angle)
                x_arc1,y_arc1=x_arc,y_arc
                x_arc2,y_arc2=x_arc,y_arc
            else:
                x_arc, y_arc = addin_utility.get_arc_center(cx, cy, sx, sy, radius, arc_angle) 
                x_arc1, y_arc1 = addin_utility.get_arc_center(cx, cy, s1_x, s1_y, radius, arc_angle)
                x_arc2, y_arc2 = addin_utility.get_arc_center(cx, cy, s2_x, s2_y, radius,arc_angle)

            x_min = min(self.x1, self.x2, x_arc, x_arc1, x_arc2)
            y_min = min(self.y1, self.y2, y_arc, y_arc1, y_arc2)
            x_max = max(self.x1, self.x2, x_arc, x_arc1, x_arc2)
            y_max = max(self.y1, self.y2, y_arc, y_arc1, y_arc2)

        return BoundingBox(x_min, y_min, x_max, y_max)


# the footprint text
class FootprintText(FootprintElement):
    # initialize the data members
    def __init__(self, text_value, pos_x = 0, pos_y = 0):
        self.x = pos_x
        self.y = pos_y
        self.size = 0.127
        self.font = "proportional"
        self.ratio = 8
        self.align = "top-center"
        self.distance = 50
        self.layer = 25
        self.value = text_value

    def draw(self, sketch): 
        if self.layer not in DRAW_LAYERS: return

        height = self.size
        position = adsk.core.Point3D.create(self.x, self.y, 0)

        if self.align == "top-center":
            position.y -= height

        sketch_texts = sketch.sketchTexts
        sketch_text = sketch_texts.add(sketch_texts.createInput(self.value, height, position))
        text_bounding_box = sketch_text.boundingBox
        text_width = abs(text_bounding_box.maxPoint.x - text_bounding_box.minPoint.x)

        # Use boundary lines to translate the text
        boundary_lines = sketch_text.boundaryLines
        x_translation_done = False
        translation_x = adsk.core.Vector3D.create(-text_width / 2, 0, 0)

        cnstraints = sketch.geometricConstraints

        for i in range(boundary_lines.count):
            boundary_line = boundary_lines.item(i)

            # Apply translation on sketch points of horizontal boundary line to shift the text along x-axis
            # No need to apply translation on other horizontal boundary line
            if not x_translation_done:
                start_sketch_point = boundary_line.startSketchPoint
                end_sketch_point = boundary_line.endSketchPoint

                start_point_wg = start_sketch_point.worldGeometry
                end_point_wg = end_sketch_point.worldGeometry

                if abs(start_point_wg.y - end_point_wg.y) < 1e-2:
                    # make the boundary line horizontally constraint before applying translation to sketch point
                    # BUG: FUS-62496
                    cnstraints.addHorizontal(boundary_line)
                    
                    start_sketch_point.move(translation_x)
                    end_sketch_point.move(translation_x)
                    x_translation_done = True

            boundary_line.isFixed = True

    def export_xml_node(self):
        node_attributes = {}
        # convert the internal unit-cm to mm which follow the electronic default unit
        node_attributes['x'] = str('{:.4f}'.format(round(self.x*10,4)))
        node_attributes['y'] = str('{:.4f}'.format(round(self.y*10,4)))
        node_attributes['size'] = str('{:.4f}'.format(round(self.size*10,4)))
        node_attributes['layer'] = str(self.layer)
        node_attributes['font'] = self.font
        node_attributes['ratio'] = str(self.ratio)
        node_attributes['align'] = self.align
        node_attributes['distance'] = str(self.distance)
        node_text = ET.Element('text', node_attributes)
        node_text.text = self.value
        return node_text

    def bounding_box(self):
        # we don't need text bounding box. just return a dummy one.
        return BoundingBox()

# the footprint circle object.
class FootprintCircle(FootprintElement):
    # initialize the data members
    def __init__(self, point_x = 0, point_y = 0, circle_width = 0, circle_radius = 0):
        self.center_point_x = point_x
        self.center_point_y = point_y
        self.width = circle_width
        self.radius = circle_radius
        self.layer = 21

    def draw(self, sketch): 
        if self.layer not in DRAW_LAYERS: return
        center = adsk.core.Point3D.create(self.center_point_x, self.center_point_y, 0)
        # draw the circle
        fusion_sketch.draw_circle_center_radius(sketch, center, self.radius, False, True)

    def export_xml_node(self):
        node_attributes = {}
        # convert the internal unit-cm to mm which follow the electronic default unit
        node_attributes['x'] = str('{:.4f}'.format(round(self.center_point_x*10,4)))
        node_attributes['y'] = str('{:.4f}'.format(round(self.center_point_y*10,4)))
        node_attributes['layer'] = str(self.layer)
        node_attributes['width'] = str('{:.4f}'.format(round(self.width*10,4)))
        node_attributes['radius'] = str('{:.4f}'.format(round(self.radius*10,4)))
        return ET.Element('circle', node_attributes)

    def bounding_box(self):
        x_min = self.center_point_x - self.radius
        y_min = self.center_point_y - self.radius
        x_max = self.center_point_x + self.radius
        y_max = self.center_point_y + self.radius
        return BoundingBox(x_min, y_min, x_max, y_max)

# the footprint Hole object. it only represents the hole on the pcb board
class FootprintHole(FootprintElement):
    # initialize the data members
    def __init__(self, point_x = 0, point_y = 0, drill_diameter = 0):
        self.center_point_x = point_x
        self.center_point_y = point_y
        self.drill = drill_diameter

    def draw(self, sketch): # don't need draw the hole geometry in Silkscreen
        pass

    def export_xml_node(self):
        node_attributes = {}
        # convert the internal unit-cm to mm which follow the electronic default unit
        node_attributes['x'] = str('{:.4f}'.format(round(self.center_point_x*10,4)))
        node_attributes['y'] = str('{:.4f}'.format(round(self.center_point_y*10,4)))
        node_attributes['drill'] = str('{:.4f}'.format(round(self.drill*10,4)))
        return ET.Element('hole', node_attributes)

    def bounding_box(self):
        x_min = self.center_point_x - self.drill/2
        y_min = self.center_point_y - self.drill/2
        x_max = self.center_point_x + self.drill/2
        y_max = self.center_point_y + self.drill/2
        return BoundingBox(x_min, y_min, x_max, y_max)

# the footprint rectagle object. it only represents the solder paste 
class FootprintRectangle(FootprintElement):
    # initialize the data members
    def __init__(self, start_x = 0, start_y = 0, end_x = 0, end_y = 0):
        self.x1 = start_x
        self.y1 = start_y
        self.x2 = end_x
        self.y2 = end_y
        self.layer = 31

    def draw(self, sketch): # don't need draw the hole geometry in Silkscreen
        pass

    def export_xml_node(self):
        node_attributes = {}
        # convert the internal unit-cm to mm which follow the electronic default unit
        node_attributes['x1'] = str('{:.4f}'.format(round(self.x1*10,4)))
        node_attributes['y1'] = str('{:.4f}'.format(round(self.y1*10,4)))
        node_attributes['x2'] = str('{:.4f}'.format(round(self.x2*10,4)))
        node_attributes['y2'] = str('{:.4f}'.format(round(self.y2*10,4)))
        node_attributes['layer'] = str(self.layer)
        return ET.Element('rectangle', node_attributes)

    def bounding_box(self):
        x_min = min(self.x1, self.x2)
        y_min = min(self.y1, self.y2)
        x_max = max(self.x1, self.x2)
        y_max = max(self.y1, self.y2)
        return BoundingBox(x_min, y_min, x_max, y_max)

