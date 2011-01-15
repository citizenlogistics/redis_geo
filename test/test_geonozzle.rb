require 'helper'

class TestGeonozzle < Test::Unit::TestCase
  def assert_geo loc, cnum, lat, lng, acc
    assert g = Geonozzle.universal_geocode(loc, Geonozzle::City.num(cnum))
    assert_equal lat, g.lat
    assert_equal lng, g.lng
    assert_equal acc, g.precision
  end

  def test_universal_geocoding_no_hash
    assert_geo "12 cherry",  220, 42.323547,  -72.629872,  "address"
    assert_geo "cherry st",  220, 42.3241601, -72.6285171, "zip+4"
    assert_geo "mobile, al", 220, 30.6943566, -88.0430541, "city"
    assert_geo "mobile, al", nil, 30.6943566, -88.0430541, "city"
    assert_geo "1 haywood rd asheville",  nil, 35.5848508, -82.5691946, "address"
    assert_geo "19 lawrence road lahore", nil, 31.5522173, 74.3271002, "zip+4"
    assert_geo "santa cruz, ca", 220, 36.9741171, -122.0307963, "city"
  end
end
