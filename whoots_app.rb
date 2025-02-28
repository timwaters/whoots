#require 'rubygems'
#require 'erb'

class WhootsApp
 
  def self.call(env)
    req = Rack::Request.new(env)

    case req.path
    when /^\/hi\b/
      Rack::Response.new(["Hello World!"]).finish
    when /^\/tms\/\d+\/\d+\/\d+\/\w+\/*/
      #'/tms/:z/:x/:y/:layers/*'
      params = req.path.split("/")

      # Validate numeric parameters
      return [400, {'Content-Type' => 'text/plain'}, ['Invalid parameters']] unless (
        params[2..4].all? { |p| p.match?(/\A\d+\z/) } 
      )
      
      layer = params[5].to_s.gsub(/[^a-zA-Z0-9\-_\.:\s%]/, '')
      
      z,x,y = params[2],params[3],params[4]

      scheme = params[6].strip.match?(/\Ahttps?:\z/) ? params[6].strip.chomp(':') : 'http'
  
      # Sanitize splat path to prevent directory traversal
      splat = "#{scheme}://" +  params[6..params.length]
        .select { |p| p.match?(/\A[\w\-\.\/]+\z/) }
        .join("/")
      # splat = params[6..params.length].join("/")
      # Validate splat is not empty after sanitization
      return [400, {'Content-Type' => 'text/plain'}, ['Invalid path']] if splat.empty?
      
      query_params = Rack::Utils.parse_query(req.query_string)
      
      # Sanitize map parameter
      map = query_params["map"].to_s.gsub(/[^a-zA-Z0-9\-_\.\/]/, '')
      
      x = x.to_i
      y = y.to_i
      z = z.to_i
      #for Google/OSM tile scheme we need to alter the y:
      y = ((2**z)-y-1)
      #calculate the bbox
      bbox = get_tile_bbox(x,y,z)
      #build up the other params
      format = query_params["format"] == "image/jpeg" ? "image/jpeg" : "image/png"
      service = "WMS"
      version = "1.1.1"
      request = "GetMap"
      srs = "EPSG:3857"
      width = "256"
      height = "256"
      layers = layer || ""
      
      # Only include map parameter if it exists and is not empty
      map_param = ""
      unless query_params["map"].to_s.empty?
        map = query_params["map"].to_s.gsub(/[^a-zA-Z0-9\-_\.\/]/, '')
        map_param = "&map=" + map
      end
      
      base_url = splat
      url = base_url + "?"+ "bbox="+bbox+"&format="+format+"&service="+service+"&version="+version+"&request="+request+"&srs="+srs+"&width="+width+"&height="+height+"&layers="+layers+map_param+"&styles="

      return [302, {'Location' => url}, []]
    else
      Rack::Response.new(["<html>Not found. <a href='/'>Whoots</a></html>"], 404).finish
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
