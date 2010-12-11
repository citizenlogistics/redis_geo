module Geonozzle
  module Locstring
    STREET_ENDINGS = %w{
      st rd pl av ave street road blvd circle cir
      dr drive loop ln lane park terr pkwy
    }.to_set
    ISO2_CODES = COUNTRY_CODES.keys.map(&:downcase).to_set
    COUNTRY_NAMES = COUNTRY_CODES.values.map do |name|
      name.downcase.sub(/\s*\(.*\)\s*/,'')
    end.to_set
    CITY_ENDINGS = {}
    City.all.each do |city|
      city.synonyms.each{ |syn| CITY_ENDINGS[syn] = city }
    end

    def normalized
      @normalized ||= downcase.gsub(/\W+/, ' ').gsub(/  +/, ' ').strip
    end

    def blank?
      !normalized or normalized == ''
    end

    def words
      @words ||= normalized.split
    end

    def last_word
      words.last
    end

    def last_two_words
      return last_word unless words.size > 1
      return words[-2..-1].join(' ')
    end

    def city
      CITY_ENDINGS[last_two_words] || CITY_ENDINGS[last_word]
    end

    def noncity_part
      x = normalized.split
      words = if CITY_ENDINGS[last_two_words]; x[0..-3]
      elsif      CITY_ENDINGS[last_word];      x[0..-2]
      end
      return self unless words

      str = words.join(' ')
      str.extend Locstring
      str
    end

    def obviously_worldwide?
      lat_lng? or zipcode? or ends_with_country?
    end

    def zipcode?
      last_word =~ /^\d{4,5}$/
    end

    def lat_lng?
      if self =~ /^(.*\s+)?(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)\s*$/
        [$2.to_f, $3.to_f]
      end
    end

    def ends_with_country?
      return false if looks_local?
      COUNTRY_NAMES.include? last_word or ISO2_CODES.include? last_word
    end

    def looks_local?
      STREET_ENDINGS.include? last_word
    end
  end
end
