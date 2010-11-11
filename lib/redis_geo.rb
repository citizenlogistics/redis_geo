require 'geokit'
require 'tzinfo'
require 'set'
require 'methodcache'

require 'redis_geo/country_codes'
require 'redis_geo/city'
require 'redis_geo/cities'
require 'redis_geo/locstring'

module RedisGeo
  extend MethodCache::ModuleExtensions
  module_function
  PretendGeo = Struct.new(:lat, :lng, :acc, :cc2)

  def basic_geocode(loc, cc2 = nil)
    g = GeoKit::Geocoders::GoogleGeocoder.geocode(loc, :bias => cc2)
    g if g && g.success
  end

  def city_radial_geocode(city_num, loc)
    spot = City.num(city_num).to_lat_lng
    [2, 5, 10, 30].each do |distance_in_miles|
      bounds = Geokit::Bounds.from_point_and_radius(spot, distance_in_miles)
      geoloc = GeoKit::Geocoders::GoogleGeocoder.geocode(loc, :bias => bounds) rescue nil
      next unless geoloc and geoloc.success and geoloc.distance_to(spot) < distance_in_miles
      geoloc
    end
  end

  module_cache :basic_geocode,       :with => :redis
  module_cache :city_radial_geocode, :with => :redis

  def universal_geocode(loc, city=nil, delegate=nil)
    loc.strip!
    loc.extend Locstring
    loc.blank? and return
    ll = loc.lat_lng? and return PretendGeo.new(ll.first, ll.last, 'building')
    city, loc = loc.city, loc.noncity_part if loc.city
    city = nil if loc.obviously_worldwide?
    loc = loc.normalized

    result = nil
    if city
      result ||= delegate && delegate.call(loc, city)
      result ||= basic_geocode("#{loc}, #{city.name}")
      result ||= radial_geocode(city.num, loc)
    end
    result ||= delegate && delegate.call(loc, nil)
    result ||= basic_geocode(loc)
    return result
  end
end
