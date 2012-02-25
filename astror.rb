=begin
astror.rb - astronomical (Ruby) calculations

Copyright (c) 2011 Juan Manuel Rodriguez Ibañez

You can redistribute and/or modify this software under the terms of the license GNU GPL v3 or later.

=== Content
Library of functions related with astronomy which implement verifiable calculations according to known and verified astronomical sources. 

=== Sources / Bibliography: 
* Meeus, Jean 1991. "Astronomical Algorithms" Richmond: Willmann-Bell

=end


# <tt>[year, month, day] </tt> date of julian to gregorian change
#  
# Note: julian date changed to gregorian date at a different date on different
# countries but the generic (italian?) change was 1582/10/14 to 15 (ref. Meeus
# 1991, p. 59)
GREGORIAN_CHANGE = [1582, 10, 15]


# indicate the decimal digits used when returning floating point calculation
# results, to avoid problems with decimal digits precision for example when
# taking the fractional part
DECIMAL_DIGITS = 8       # test indicate 9 decimal digits precision, so 8 will be on the safe side


# true if date correspond to a julian date, false if the date correspond to the
# gregorian calendar
#
# === Example
#   is_juliandate(2000,1,31)    # <= false
def is_juliandate(year, month, day)
  (year<GREGORIAN_CHANGE[0] or (year==GREGORIAN_CHANGE[0] and (month<GREGORIAN_CHANGE[1] or (month==GREGORIAN_CHANGE[1] and day<GREGORIAN_CHANGE[2]))))
end


# true if +year+ is a leap (bixestile) one
def is_leapyear(year)
  # (ref. Meeus 1991, p. 62)
  year = year.to_i          # avoid floating point operations
  res = (year%4 == 0)
  #if it is a gregorian year and a century year 
  if year >GREGORIAN_CHANGE[0] and (year%100 == 0)
    # then only 400 are leap years
    res = (year%400 == 0)
  end
  res
end


=begin

Calculates Julian Day (not julian date) using method from Meeus 1991, p. 60-62
 
+day+ can be fractional

It will raise an error if you try to calculate negative values for julian day (i.e. before year -4712)

=== Note
If you are interested only in julian day calculation maybe you can skip using this library at all as apparently you can get the same results with either:
  Date.new(year, month, day.to_i).jd - 0.5 + day%1
or
  DateTime.new(year, month, day.to_i, (day%1)*24).ajd
=end
def calculate_jd(year, month, day, force_juliandate = false)

  raise ArgumentError, "julian day before year -4712 not supported" if year < -4712
  raise ArgumentError, "year or month can't be fractional" if year%1 != 0 or month%1 != 0
  raise ArgumentError, "month 1-12, day 1-31" unless month > 0 and month <= 12 and day > 0 and day <= 31
  
  if month==1 or month==2
    month += 12
    year -= 1
  end

  if (is_juliandate(year,month,day) or force_juliandate)
    # B=0 para el calendario juliano
    b = 0
  else
    a = (year/100).to_i
    b = 2 - a + (a/4).to_i # para el calendario GREGORIAN_CHANGEo
  end
  
  partial = (365.25*(year+4716)).to_i + (30.60001*(month+1)).to_i + b   # partial is an int!!
  (partial + day - 1524.5)    # final floating point operations
end


# calculates "julian day sub zero": julian day of the yearday 0 of a given year
# (ref. Meeus 1991, p. 62)
def calculate_jd0(year)
  calculate_jd(year-1, 12, 31)
end


# modified julian day
def calculate_mjd(year, month, day)
  calculate_mjd_fromjd(calculate_jd(year, month, day))
end
def calculate_mjd_fromjd(julian_day)
  # (ref. Meeus 1991, p. 63)
  julian_day - 2400000.5
end


# 0=sun, 1=mon, 2=tue, etc.
def calculate_weekday(year, month, day)
  calculate_weekday_fromjd(calculate_jd(year, month, day))
end
def calculate_weekday_fromjd(julian_day)
  # (modified over Meeus 1991, p. 65)
  (julian_day + 1.5).to_i%7
end


# note that 1 of January would be yearday = 1
# a
#
def calculate_yearday(year, month, day)
  # an alternative method (ref. Meeus 1991, p. 66):
  #   k = (is_leapyear(year))? 1 : 2  
  #   ((275*month)/9).to_i - k * ((month + 9)/12).to_i + day.to_i - 30
  (calculate_jd(year,month,day) - calculate_jd(year,1,1) + 1).round(DECIMAL_DIGITS)
end


# <tt>[year, month, day]</tt> calculated from the julian day
def calculate_ymd(julian_day)
  # (method from Meeus 1991, p. 63-65)
  # this calculation method is invalid for negative julian days
  raise ArgumentError, "negative julian day not supported" if julian_day < 0
    
  z = (julian_day + 0.5).to_i
  # the following operations have problems with decimal precision
  #   (julian_day+0.5) - z)
  #   (julian_day + 0.5)%1
  f = ((julian_day + 0.5)%1).round(DECIMAL_DIGITS)
  
  if z < 2299161
    a = z
  else
    alfa = ((z - 1867216.25)/36524.25).to_i
    a = z + 1 + alfa - (alfa/4).to_i
  end
  b = a + 1524
  c = ((b - 122.1)/365.25).to_i
  d = (365.25*c).to_i
  e = ((b - d)/30.60001).to_i
  
  day = b - d - (30.60001*e).to_i + f
  month = (e < 14)? e - 1 : e - 13
  year = (month > 2)? c - 4716 : c - 4715
  [year, month, day]  
end


# <tt>[month, day]</tt> calculated from the +yearday+ for the given +year+
#
# yearday can be fractional
def calculate_md(year, yearday)
  julian_day = calculate_jd(year,1,1) + yearday - 1
  calculate_ymd(julian_day)[1..2]
end


# calculates christian easter month and day for the given +year+
def calculate_easter_md(year)
  # (method from Meeus 1991, p. 67-69)
  year = year.to_i
  if year <= GREGORIAN_CHANGE[0]
    a = year%4
    b = year%7
    c = year%19
    d = (19*c + 15)%30
    e = (2*a + 4*b - d + 34)%7
    f = (d + e + 114)/31
    g = (d + e + 114)%31
    month = f
    day = g + 1
  else
    a = year%19
    b = year/100
    c = year%100
    d = b/4
    e = b%4
    f = (b + 8)/25
    g = (b - f + 1)/3
    h = (19*a + b - d - g + 15)%30
    i = c/4
    k = c%4
    l = (32 + 2*e + 2*i - h -k)%7
    m = (a + 11*h + 22*l)/451
    n = (h + l - 7*m + 114)/31
    p = (h + l - 7*m + 114)%31
    month = n
    day = p + 1
  end
  [month, day]
end

# Date class specificaly made for astronomical calculations.
#
# The principal objective is to have a simple class that uses our previous
# library of functions for astronomical date calculations.
#
# Keeping things simple makes easy to verify and trust the results.
class DateAstro
  # Julian Day (JD)
  attr_reader :jd
  # of given date
  attr_reader :year, :month, :day

  # +day+ can be fractional
  # === Example
  #  date = DateAstro.new(2012, 12, 31.4) 
  def initialize(year, month, day)  
    @year = year 
    @month = month
    @day = day 
    @jd = calculate_jd(@year, @month, @day)
  end

  # === Example
  #   astro = AstroDate.new(2000,1,31)
  #   astro.is_juliandate?    # <= false
  def is_juliandate?
    test_juliandate(@year, @month, @day)
  end

  # returns Modified Julian Day (MJD)
  def mjd
    calculate_mjd(jd)
  end
  
  # prints a complete report on the date
  def report
    printf "year/month/day      #{@year}/#{@month}/#{day} (%s)\n",  
                ((is_juliandate())? "julian" : "gregorian")
    puts   "julian day          #{jd} JD"
    puts   "modified julian day #{mjd} MJD"
  end
end

