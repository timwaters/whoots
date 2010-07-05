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

get '/one/*' do
p "ONE"
p request
p params
end

get '/two/:z/:x/:y/*' do
p "two"
p request
p params
end

get '/three/:z/:x/:y' do
p "three"
p request
p params
end

get '/tmss/:z/:x/:y/:layer/*' do
p request
p params
end


get '/tms/:z/:x/:y/*' do
p request
p params
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
  layers = params[:layers] || params[:LAYERS] || ""
  p layers
  p params
  base_url = params[:splat][0]
  p base_url
  url = base_url + "?"+ "bbox="+bbox+"&format="+format+"&service="+service+"&version="+version+"&request="+request+"&srs="+srs+"&width="+width+"&height="+height+"&layers="+layers
  #redirect params[:url]
  #"Hello World! URL= " + url
  p url
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
    <html><head><title>WhooTS - the tiny public wms to tms proxy</title></head><body>
    <h1><img src="whoots_tiles.jpg" />
    WhooTS - the tiny public wms to tms proxy</h1>
    <%= yield %>
    <hr />
    <p>About: Made with Sinatra, Ruby, Mapserver Mapscript by Tim Waters tim@geothings.net <br />
    Code available at: <a href="http://github.com/timwaters/whoots">github</a></p>
    </body></html>

@@ index
    <h2>Usage:</h2>

    http://<%=request.host%>:<%=request.port%>/tms/z/x/y/?url=http://maps.nypl.org/warper/layers/wms/870 <br />
    http://<%=request.host%>:<%=request.port%>/tms/19/154563/197076/?url=http://maps.nypl.org/warper/layers/wms/870

    <h2>OSM Potlatch example </h2>
    http://www.openstreetmap.org/edit?lat=40.73658&lon=-73.87108&zoom=17&tileurl=http://whoots.mapwarper.net/tms/!/!/!/?url=http://maps.nypl.org/warper/layers/wms/870


<br />
http://www.openstreetmap.org/edit?lat=40.73658&lon=-73.87108&zoom=17&tileurl=http://0.0.0.0:4567/tms/!/!/!/http://maps.nypl.org/warper/layers/wms/870

<br />
http://www.openstreetmap.org/edit?lat=18.536839&lon=-72.303737&zoom=18&tileurl=http://0.0.0.0:4567/tms/!/!/!/http://maps.geography.uc.edu/cgi-bin/mapserv?map=/home/cgn/public_html/maps/mapfiles/haiti2.map&version=1.1.0&SERVICE=WMS&REQUEST=GetMap&FORMAT=image/png&LAYERS=DG_crisis_event_service&srs=epsg:4326&exceptions=application/vnd.ogc.se_inimage&



    <h2>Notes</h2>
    * Use only a WMS that supports SRS EPSG:900913

