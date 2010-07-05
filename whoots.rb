require 'rubygems'
require 'vendor/rack/lib/rack'
require 'vendor/sinatra/lib/sinatra'
require 'erb'

get '/hi' do
  "Hello World!"
end

get '/' do
  erb :index
end

get '/tms/:z/:x/:y/:layers/*' do
  #p params
  x = params[:x].to_i
  y = params[:y].to_i
  z = params[:z].to_i
  #for Google/OSM tile scheme we need to alter the y:
  y = ((2**z)-y-1)
  #calculate the bbox
  bbox = get_tile_bbox(x,y,z)
  #build up the other params
  format = "image/png"
  service = "WMS"
  version = "1.1.1"
  request = "GetMap"
  srs = "EPSG:900913"
  width = "256"
  height = "256"
  layers = params[:layers] || ""
  #p layers
  #p params
  map = params[:map] || ""
  base_url = params[:splat][0]
  url = base_url + "?"+ "bbox="+bbox+"&format="+format+"&service="+service+"&version="+version+"&request="+request+"&srs="+srs+"&width="+width+"&height="+height+"&layers="+layers+"&map="+map+"&styles="
  #p url
  redirect url
end

#
# tile utility methods. calculates the bounding box for a given TMS tile.
# Based on http://www.maptiler.org/google-maps-coordinates-tile-bounds-projection/
# GDAL2Tiles, Google Summer of Code 2007 & 2008
# by  Klokan Petr Pridal
#
def get_tile_bbox(x,y,z)
  min_x, min_y = get_merc_coords(x * 256, y * 256, z)
  max_x, max_y = get_merc_coords( (x + 1) * 256, (y + 1) * 256, z )
  return "#{min_x},#{min_y},#{max_x},#{max_y}"
end

def get_merc_coords(x,y,z)
  resolution = (2 * Math::PI * 6378137 / 256) / (2 ** z)
  merc_x = (x * resolution -2 * Math::PI  * 6378137 / 2.0)
  merc_y = (y * resolution - 2 * Math::PI  * 6378137 / 2.0)
  return merc_x, merc_y
end


__END__

@@ layout
<html><head><title>WhooTS - the tiny public wms to tms proxy</title>
<style>body{font-family: Arial, Helvetica, sans-serif;}</style>
</head><body>
<h1><img src="whoots_tiles.jpg" />
WhooTS - the tiny public wms to tms proxy</h1>
<%= yield %>
<hr />
<p>About: Made with Sinatra and Ruby by Tim Waters tim@geothings.net <br />
Code available at: <a href="http://github.com/timwaters/whoots">github</a></p>
</body></html>

@@ index
<h2>What is it?</h2>
<p>It's a simple WMS to Google/OSM Scheme TMS proxy. You can use WMS servers in applications which only use those pesky "Slippy Tiles"
</p>


<h2>Usage:</h2>
<h4>http://<%=request.host%>:<%=request.port%>/tms/z/x/y/{layer}/http://path.to.wms.server</h4>

e.g<br />
http://<%=request.host%>:<%=request.port%>/tms/!/!/!/2013/http://warper.geothings.net/maps/wms/2013<br />
http://<%=request.host%>:<%=request.port%>/tms/z/x/y/870/http://maps.nypl.org/warper/layers/wms/870<br />
<br />
Using this WMS server:<br />
http://hypercube.telascience.org/cgi-bin/mapserv?map=/home/ortelius/haiti/haiti.map&request=getMap&service=wms&version=1.1.1&format=image/jpeg&srs=epsg:4326&exceptions=application/vnd.ogc.se_inimage&layers=HAITI&<br /><br />
http://<%=request.host%>:<%=request.port%>/tms/!/!/!/HAITI/http://hypercube.telascience.org/cgi-bin/mapserv?map=/home/ortelius/haiti/haiti.map<br />
<br />
http://<%=request.host%>:<%=request.port%>/tms/19/154563/197076/870/http://maps.nypl.org/warper/layers/wms/870

<h2>Openstreetmap Potlatch editing example </h2>

<h3>Map Warper <a href="http://warper.geothings.net">http://warper.geothings.net</a> </h3>
WMS Link: http://warper.geothings.net/maps/wms/2013<br />
<br />
http://www.openstreetmap.org/edit?lat=18.601316&lon=-72.32806&zoom=18&tileurl=http://<%=request.host%>:<%=request.port%>/tms/!/!/!/2013/http://warper.geothings.net/maps/wms/2013

<h3>NYPL Map Rectifier <a href="http://maps.nypl.org">http://maps.nypl.org</a></h3>

http://www.openstreetmap.org/edit?lat=40.73658&lon=-73.87108&zoom=17&tileurl=http://<%=request.host%>:<%=request.port%>/tms/!/!/!/870/http://maps.nypl.org/warper/layers/wms/870



<h3>Telascience Haiti <a href="http://hypercube.telascience.org/haiti/">http://hypercube.telascience.org/haiti/</a></h3>
http://www.openstreetmap.org/edit?lat=18.601316&lon=-72.32806&zoom=18&tileurl=http://<%=request.host%>:<%=request.port%>/tms/!/!/!/HAITI/http://hypercube.telascience.org/cgi-bin/mapserv?map=/home/ortelius/haiti/haiti.map<br /><br />

<h2>Example Outputs</h2>
http://hypercube.telascience.org/cgi-bin/mapserv?bbox=-8051417.93739076,2107827.49199202,-8051265.06333419,2107980.36604859&format=image/png&service=WMS&version=1.1.1&request=GetMap&srs=EPSG:900913&width=256&height=256&layers=HAITI&map=/home/ortelius/haiti/haiti.map&styles=
<br /><br />
http://maps.nypl.org/warper/layers/wms/870?bbox=-8223095.50291926,4973298.80834671,-8222789.75480612,4973604.55645985&format=image/png&service=WMS&version=1.1.1&request=GetMap&srs=EPSG:900913&width=256&height=256&layers=870&map=&styles=
<br />

<h2>Important Notes</h2>
* Use only a WMS that supports SRS EPSG:900913 <br />
* Tiles are Google / OSM Scheme

