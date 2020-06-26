import time
import math
import numpy as np
import gmaps
from datetime import datetime
import googlemaps
import requests
import gpxpy
import gpxpy.gpx
from vincenty import vincenty

#Previous additional weight added to vehicle
weight_added_old=0

while True:
	print('Waiting for request...')
	time.sleep(1.5)
	keyFile = open('blynk_token.txt', 'r')
	token = keyFile.readline().rstrip()
	url1 = 'http://139.59.206.133/' + token + '/get/V1'
	r=requests.get(url1)
	weight_added=int(r.text[2:-2])
	if (weight_added!=weight_added_old):
		weight_added_old=weight_added
		print('Valid request received')
		print('Step 1 of 4...')
		m = 1340 + weight_added

		#Coeff of rolling friction
		Cr_dry = 0.02
		Cr_wet = 0.022


		g = 9.8 		#Acceleration due to gravity
		rho = 1.1512    #Air density
		r = 0.343       #Wheel radius
		A = 2.5			#Frontal area
		Cd = 0.33		#Drag coefficient
		G = 4.091		#Gear ratio

		keyFile = open('keys.txt', 'r')
		consumer_key = keyFile.readline().rstrip()
		gmaps.configure(api_key=consumer_key)


		API_key= consumer_key
		gmaps2 = googlemaps.Client(key=API_key)
		now = datetime.now()

		keyFile = open('blynk_token.txt', 'r')
		token = keyFile.readline().rstrip()
		url1 = 'http://139.59.206.133/' + token + '/get/V11'
		r=requests.get(url1)

		origin      = 'IISc Bangalore'
		destination = r.text + 'karnataka'


		direction_result = gmaps2.directions(origin,
		                                     destination,
		                                     mode="driving",
		                                     departure_time=now)

		loc1_full = gmaps2.geocode(origin)
		loc2_full = gmaps2.geocode(destination)

		loc1_lat = loc1_full[0]["geometry"]["location"]["lat"]
		loc1_lng = loc1_full[0]["geometry"]["location"]["lng"]
		loc1 = (loc1_lat, loc1_lng)

		loc2_lat = loc2_full[0]["geometry"]["location"]["lat"]
		loc2_lng = loc2_full[0]["geometry"]["location"]["lng"]
		loc2 = (loc2_lat, loc2_lng)


		print('Step 2 of 4...')

		if (r.text=='["nandi hills"]') or (r.text=='["Nandi hills"]'):
		    gpx_file = open('nandihills.gpx', 'r')
    
		if (r.text=='["mysore"]') or (r.text=='["Mysore"]'):
		    gpx_file = open('mysore.gpx', 'r')
    
		if (r.text=='["kolar"]') or (r.text=='["Kolar"]'):
		    gpx_file = open('kolar.gpx', 'r')
    
		if (r.text=='["kempegowda airport"]') or (r.text=='["Kempegowda airport"]'):
		    gpx_file = open('sample_data_route.gpx', 'r')

		if (r.text=='["bangalore airport"]') or (r.text=='["Bangalore airport"]'):
			gpx_file = open('sample_data_route.gpx', 'r')


		gpx = gpxpy.parse(gpx_file)
		lat=np.array([])
		lon = np.array([])
		elev = np.array([])


		for track in gpx.tracks:
		    for segment in track.segments:
		        for point in segment.points:
		            #print('Point at ({0},{1}) -> {2}'.format(point.latitude, point.longitude, point.elevation))
		            lat = np.append(lat, point.latitude)
		            lon = np.append(lon, point.longitude)
		            elev = np.append(elev, point.elevation)



		seg_length = np.zeros([len(lon)-1])   #size of it is one less than data points
		distance = np.zeros([len(lon)])

		for i in range(len(lon) -1):
		    p1 = (lat[i], lon[i])
		    p2 = (lat[i+1], lon[i+1])
		    seg_length[i] = vincenty(p2, p1)*1000
		    distance[i+1] = distance[i]+seg_length[i]


		elev_diff_seg = np.diff(elev)   #net elevation variation for each segment
		elev_diff_seg;


		speed_seg = np.zeros(len(seg_length)) 

		dist_metres = direction_result[0]["legs"][0]["distance"]["value"] #distance in metres
		time_secs   = direction_result[0]["legs"][0]["duration"]["value"] #traveltime in seconds

		avg_speed = dist_metres/time_secs
		speed_seg = speed_seg + avg_speed
		KE_seg = 0.5*m*speed_seg**2   #KE for each segment


		PEchange_seg = m*g*elev_diff_seg    #change in PE for each segment


		seg_time = seg_length/avg_speed


		P_gravity = PEchange_seg/seg_time

		print('Step 3 of 4...')

		url1 = 'https://api.openweathermap.org/data/2.5/weather?q='
		city=loc1_full[0]["address_components"][1]["long_name"]
		city1=city
		url2 = '&appid=d7646233ef19ac4d89686943d3c33c59'
		r=requests.get(url1+city1+url2)
		data = r.json()
		temperature = data["main"]["temp"]
		pressure = data["main"]["pressure"]
		wind_speed = data["wind"]["speed"]
		humidity =  data["main"]["humidity"]
		url1 = 'http://139.59.206.133/' + token + '/update/V14?value='
		value = str(temperature)+' K, ' + str(pressure) + ' hPa, ' + str(wind_speed) + ' m/s, ' + str(humidity) + ' %25'
		r=requests.get(url1+value)


		rho = pressure*100/(temperature*287.05)
		v_rel = speed_seg + wind_speed
		F_aero = 0.5*rho*Cd*A*v_rel*v_rel
		P_aero = F_aero*seg_length/seg_time


		Cr_eff = Cr_dry + (humidity/100)*(Cr_wet-Cr_dry)

		alpha = np.zeros(len(seg_length))

		for i in range(len(seg_length)):
		    alpha[i] = math.atan(elev_diff_seg[i]/seg_length[i])
		    
		F_rolling = Cr_eff*m*g*np.cos(alpha)
		P_rolling = F_rolling*seg_length/seg_time

		P_traction = P_gravity + P_aero + P_rolling  #P_kinetic is zero for const. (avg) speed
		TractionEnergy=sum(P_traction*seg_time)/3600  #total traction energy in Wh
		TractionEnergy = round(TractionEnergy,2)


		EnergyDemand = TractionEnergy/0.78
		battery_holding = 24   #present max holding capacity
		present_holding = 20

		SOE_present = 20
		SOE_final = (20 - EnergyDemand/1000)

		print('Step 4 of 4...')

		url1 = 'http://139.59.206.133/' + token + '/update/V4?value='
		value = str(SOE_present)
		r=requests.get(url1+value)

		url1 = 'http://139.59.206.133/' + token + '/update/V5?value='
		value = str(SOE_final)
		r=requests.get(url1+value)

		url1 = 'http://139.59.206.133/' + token + '/update/V3?value='
		value = str(round(dist_metres/1000,1))
		r=requests.get(url1+value)


		print('Computation complete!')

