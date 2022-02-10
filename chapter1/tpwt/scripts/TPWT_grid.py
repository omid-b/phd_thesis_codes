#This program gets user inputs to design the grid nodes for SW studies (e.g. TPW tomography).
#Note: This script should run using python 3 interpreter (e.g python3.6 *.py3).
#Update: Oct 2018
#======Adjustable Parameters======#
n = 2 #Number of outer grid nodes for each side (rows/columns)
fac = 1 #Spacing factor in outer region (if it is set to 1, the spacing would be the same as the region of interest; I recommend '1' since it would much easier when describing resolution during the resolution test procedure)
#=================================#

import os,math
os.system('clear')
print('This program designs the grid nodes for Surface wave studies.\n(e.g. TPW tomography).\n')
outName = input('Enter the output file name?\n')
latmin, dlat, latmax = [float(x) for x in input('Enter MinLatitude, LatitudeSpacing, MaxLatitude?\n').split()]
lonmin, dlon, lonmax = [float(x) for x in input('Enter MinLongitude, LongitudeSpacing, MaxLongitude?\n').split()]


#===Defining several functions to use in the program===#

def earthRad(phi):
	#(phi in degrees) This function calculates Earth's radius at a given latitude
	a = float(6378.137) #Earth's radius at equator in km
	b = float(6356.752) #Earth's radius at poles in km
	a2 = a**2
	b2 = b**2
	sinPhi = math.sin(math.radians(phi))
	cosPhi = math.cos(math.radians(phi))
	earthRad = math.sqrt( ((a2*cosPhi)**2 + (b2*sinPhi)**2) / ((a*cosPhi)**2+(b*sinPhi)**2) )
	return earthRad

def hav(theta):
	 #Haversine function(theta in radians)
	 haversine = (1-math.cos(theta))/2
	 return haversine 

def gcDist(lat1,lon1,lat2,lon2):
	#This function calculates great circle distance between two points (All in degrees). 
	r = earthRad((lat1+lat2)/2)
	lat1,lon1,lat2,lon2 = [math.radians(x) for x in [lat1,lon1,lat2,lon2]]
	hca =  hav(lat2-lat1)+math.cos(lat1)*math.cos(lat2)*hav(lon2-lon1) #The haversine of the central angle
	gcDist = 2*r*math.asin(math.sqrt(hca))
	return gcDist

def frange(start,end,step):
	#This function is like range() for float numbers!
	lst = [start]
	while start<end :
		start = round(start+step,3)
		lst.append(start)
	return lst

#=====================================================#
#-----Latitude and Longitude nodes-----#
latNodes = frange(latmin,latmax,dlat)
lonNodes = frange(lonmin,lonmax,dlon)
#Adding n row/column to outer region

for i in range(n):
 latNodes.insert(0,latNodes[0]-fac*dlat)
 latNodes.append(latNodes[-1]+fac*dlat)
 lonNodes.insert(0,lonNodes[0]-fac*dlon)
 lonNodes.append(lonNodes[-1]+fac*dlon)

#--------------------------------------#

outFile = open(outName,'w')

outFile.write('Grid %dx%d\n%6d\n' %(len(latNodes), len(lonNodes), len(latNodes)*len(lonNodes)))

for j in range(len(lonNodes)):
	for i in range(len(latNodes)):
		outFile.write('%8.2f%8.2f\n' %(latNodes[i],lonNodes[j]))

lonDistSum=0;
for j in range(len(lonNodes)):
	lonDistSum = lonDistSum + gcDist(latNodes[int(len(latNodes)/2)],lonNodes[j]-dlon/2,latNodes[int(len(latNodes)/2)],lonNodes[j]+dlon/2)

latDistSum=0;
for i in range(len(latNodes)):
	latDistSum = latDistSum + gcDist(latNodes[i]-dlat/2,lonNodes[int(len(lonNodes)/2)],latNodes[i]+dlat/2,lonNodes[int(len(lonNodes)/2)])


#outFile.write('%.2f%8.2f\n%.2f%8.2f\n%.2f%8.2f\n%.2f%8.2f\n' %(latNodes[n-1],lonNodes[n-1],latNodes[n-1],lonNodes[-n],latNodes[-n],lonNodes[n-1],latNodes[-n],lonNodes[-n]))
outFile.write('%.2f%8.2f\n%.2f%8.2f\n%.2f%8.2f\n%.2f%8.2f\n' %(latNodes[n],lonNodes[n],latNodes[n],lonNodes[-n-1],latNodes[-n-1],lonNodes[n],latNodes[-n-1],lonNodes[-n-1]))
outFile.write('%d\n%.2f\n%.2f' %(len(lonNodes), 2*lonDistSum/len(lonNodes), 2*latDistSum/len(latNodes)))
outFile.close()
