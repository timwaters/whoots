#require 'rubygems'
#require 'erb'

class WhootsApp
 
  def self.call(env)
    req = Rack::Request.new(env)

    case req.path
    when /^\/hi\b/
      Rack::Response.new("Hello World!")
    when /^\/tms\/\d+\/\d+\/\d+\/\w+\/*/
      #'/tms/:z/:x/:y/:layers/*'
      params = req.path.split("/")
  
      z,x,y,layer = params[2],params[3],params[4],params[5]

      splat = params[6..params.length].join("/")
      query_params = req.query_string.split("&")

      query_params =  Rack::Utils.parse_query(req.query_string)
      x = x.to_i
      y = y.to_i
      z = z.to_i
      #for Google/OSM tile scheme we need to alter the y:
      y = ((2**z)-y-1)
      #calculate the bbox
      bbox = get_tile_bbox(x,y,z)
      #build up the other params
      format = "image/png"
      service = "WMS"
      version = "1.1.1"
      request = "GetMap"
      srs = "EPSG:3857"
      width = "256"
      height = "256"
      layers = layer || ""

      map = query_params["map"] || ""
      base_url = splat
      url = base_url + "?"+ "bbox="+bbox+"&format="+format+"&service="+service+"&version="+version+"&request="+request+"&srs="+srs+"&width="+width+"&height="+height+"&layers="+layers+"&map="+map+"&styles="

      response = Rack::Response.new
      response.redirect(url, 302)
      response.finish
    else
      Rack::Response.new("<html>Not found. <a href='/'>Whoots</a></html>", 404)
    end
  end
  

  
  def self.get_tile_bbox(x,y,z)
    min_x, min_y = get_merc_coords(x * 256, y * 256, z)
    max_x, max_y = get_merc_coords( (x + 1) * 256, (y + 1) * 256, z )
    return "#{min_x},#{min_y},#{max_x},#{max_y}"
  end

  def self.get_merc_coords(x,y,z)
    resolution = (2 * Math::PI * 6378137 / 256) / (2 ** z)
    merc_x = (x * resolution -2 * Math::PI  * 6378137 / 2.0)
    merc_y = (y * resolution - 2 * Math::PI  * 6378137 / 2.0)
    return merc_x, merc_y
  end
  

end
