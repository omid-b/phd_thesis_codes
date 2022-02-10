#!/usr/bin/env python3
# This scripts checks if a scattered dataset data (e.g. data.xyz) is inside a particular polygon (countour.xy)
# Coded By: omid.bagherpur@gmail.com
# Update: April 2, 2019

import os, sys
os.system('clear')
print('This script checks if a scattered dataset data lies within a polygon.\n')

if len(sys.argv) != 4:
  print('Error!')
  print(f'  USAGE: {sys.argv[0]} <points> <polygon.xy> <output file>\n')
  exit()

#---import required madules---#
try:
  import gdal, osgeo
  import numpy as np
except:
  print('Import error! Make sure the following python madules are installed:')
  print('  gdal, osgeo, numpy')

#--------main function---------#
def point_in_polygon(point, polygon):
    """
    point : [longitude, latitude]

    polygon : [(lon1, lat1), (lon2, lat2), ..., (lonn, latn),(lon1, lat1)]
    
    """
    # Create spatialReference
    spatialReference = osgeo.osr.SpatialReference()
    spatialReference.SetWellKnownGeogCS("WGS84")
    # Create ring
    ring = osgeo.ogr.Geometry(osgeo.ogr.wkbLinearRing)
    # Add points
    for lon, lat in polygon:
        ring.AddPoint(lon, lat)
    # Create polygon
    poly = osgeo.ogr.Geometry(osgeo.ogr.wkbPolygon)
    poly.AssignSpatialReference(spatialReference)
    poly.AddGeometry(ring)
    # Create point
    pt = osgeo.ogr.Geometry(osgeo.ogr.wkbPoint)
    pt.AssignSpatialReference(spatialReference)
    pt.SetPoint(0, point[0], point[1])
    return pt.Within(poly)

#--------------------------------#
#read data
with open(sys.argv[2]) as polyfile:
    polygon = [tuple(map(float, i.split())) for i in polyfile]

if polygon[0] != polygon[-1]:
    polygon.append(polygon[0])

with open(sys.argv[1]) as pointfile:
    points = [tuple(map(float, i.split())) for i in pointfile]

#make output
print(f'Making output ({sys.argv[3]}) ... \r')

output=open(sys.argv[3],'w')

i=-1
for line in open(sys.argv[1]):
	i+=1
	if point_in_polygon(points[i], polygon):
		output.write(line)
	
print(f'Done!\n\n')
