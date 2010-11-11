module RedisGeo
  class City < Struct.new(:num, :name, :lat, :lng)
    include GeoKit::Mappable
    extend MethodCache::ModuleExtensions
    attr_accessor :ll, :distance
    @@all = []
    @@by_num = []

    def initialize(*args)
      super
      @ll = GeoKit::LatLng.normalize(lat, lng)
      @@all << self
      @@by_num[num] = self
    end

    def self.num(num)
      @@by_num[num.to_i]
    end

    def self.all
      @@all
    end

    def js
      args = [num, name, lat, lng].to_json[1..-2]
      "city(#{args});\n"
    end

    def self.[](lat, lng)
      return unless thing = GeoKit::LatLng.normalize(lat, lng)
      @@all.min{ |a, b| a.ll.distance_to(thing) <=> b.ll.distance_to(thing) }
    end

    def self.closest_city_cached(lat, lng)
      City[lat, lng]
    end

    class_cache :closest_city_cached, :for => 30*24*60*60

    def self.closest(lat, lng)
      nlat = (lat.to_f*2000.0).round/2000.0
      nlng = (lng.to_f*2000.0).round/2000.0
      closest_city_cached(nlat, nlng)
    end

    def to_lat_lng
      Geokit::LatLng.new(lat, lng)
    end

    def distance_to_ll(*ll)
      GeoKit::LatLng.normalize(*ll).distance_to(to_lat_lng, :units => :kms) * 1000
    end

    def synonyms
      suffixes = [province_code, country_code, country_name].compact
      ([city_name] + suffixes.map{ |suf| "#{city_name} #{suf}" }).map(&:downcase)
    end

    # TODO: local city names, etc
    def country_name
      @country_name ||= name.split(', ').last
    end

    # TODO: local city names, etc
    def city_name
      @city_name ||= name.split(', ').first
    end

    def province_code
      @province_code ||= name.split(', ')[1..-2].first
    end

    def country_code
      @country_code ||= COUNTRY_CODES.index(country_name)
    end

    def timezone
      raise "no country code for #{country_name}" unless country_code
      TZInfo::Country.get(country_code).zone_info.min_by do |tz_country|
        (lng - tz_country.longitude).abs
      end.timezone
    end
  end
end
