gem 'minitest'
require 'minitest/autorun'
#require 'test/unit'


require './astro'

# test unit for the astro.rb libray
class AstroTest < MiniTest::Unit::TestCase 

  #def setup
  #end
  #def teardown
  #end
  
  # test AstroDate class
  def test_astroclass
  end
  
  # test calculation tool
  def test_calculate 
    # -4715/1/1 # <= invalid year (negative julian date)
    assert_raises(ArgumentError) { DateAstro.new(-4715,1,1) }
    assert_raises(ArgumentError) { DateAstro.new(1.2, 1,    1) }
    assert_raises(ArgumentError) { DateAstro.new(1,   1.3,  1) }
    assert_raises(ArgumentError) { DateAstro.new(1,   0,    1) }
    assert_raises(ArgumentError) { DateAstro.new(1,   1,    0) }
    assert_raises(ArgumentError) { DateAstro.new(1,   -1,   1) }
    assert_raises(ArgumentError) { DateAstro.new(1,   1,    -1) }

    data_jd = [
      # year, month, day, expected julian day
      # (source: Meeus 1991 p.62)
      [2000,  1,  1.5,  2451545.0],
      [1987,  1,  27,   2446822.5],
      [1987,  6,  19.5, 2446966.0],
      [1988,  1,  27.0, 2447187.5],
      [1900,  1,  1,    2415020.5],
      [1600,  1,  1.0,  2305447.5],
      [1600,  12, 31,   2305812.5],
      [837,   4,  10.3, 2026871.8],
      [-1000, 7,  12.5, 1356001.0],
      [-1000, 2,  29.0, 1355866.5],
      [-1001, 8,  17.9, 1355671.4],
      [-4712, 1,  1.5,  0.0]
=begin
test_jd(1582,10,15)
test_jd(1582,10,4)
test_jd(333,1,27.5)
=end
    ]
              
    for d in data_jd do
      jd = calculate_jd(d[0], d[1], d[2])
      assert_equal(d[3], jd, "jd for #{d[0]}/#{d[1]}/#{d[2]}")
    end

    assert_equal(0.0, calculate_mjd(1858, 11, 17))
    
    data_easter = [
      # year, [month, day]
      # (source: Meeus 1991 p.68-69)
      [179,  [4,12]],
      [711,  [4,12]],
      [1243, [4,12]],
      [1818, [3,22]],
      [1991, [3,31]],
      [1992, [4,19]],
      [1993, [4,11]],
      [1954, [4,18]],
      [2000, [4,23]],
      [2038, [4,25]]
    ]
    
    for d in data_easter do
      assert_equal(d[1], calculate_easter_md(d[0]), "easter for year #{d[0]}")
    end
    
    assert_equal(318, calculate_yearday(1978,11,14))
    assert_equal(113.2, calculate_yearday(1988,4,22.2))

    assert_equal([11, 14], calculate_md(1978,318.0))
    assert_equal([4, 22.2], calculate_md(1988,113.2))

  end
end