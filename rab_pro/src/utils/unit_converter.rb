# ==============================================================================
# RAB Pro - Unit Converter Utility
# Convert between different units (meters, currency, area, volume, etc.)
# ==============================================================================

module RABPro
  module UnitConverter
    # Standard unit conversion factors
    METER_TO_CM    = 100.0
    METER_TO_MM    = 1000.0
    METER_TO_INCH  = 39.3701
    METER_TO_FEET  = 3.28084

    # Convert meters to centimeters
    def self.meter_to_cm(meters)
      (meters * METER_TO_CM).round(2)
    end

    # Convert centimeters to meters
    def self.cm_to_meter(cm)
      (cm / METER_TO_CM).round(4)
    end

    # Convert meters to millimeters
    def self.meter_to_mm(meters)
      (meters * METER_TO_MM).round(0)
    end

    # Convert to currency format (IDR)
    def self.to_currency(amount, symbol = 'Rp')
      amount = amount.to_f.round(0).to_i
      formatted = amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
      "#{symbol} #{formatted}"
    end

    # Parse currency string to number
    def self.from_currency(currency_str)
      currency_str.to_s.gsub(/[^0-9]/, '').to_i.to_f
    end

    # Convert number to words (Terbilang - Indonesian)
    def self.to_terbilang(number)
      number = number.to_i
      return 'Nol' if number == 0
      return 'Minus ' + to_terbilang(-number) if number < 0

      words = [
        '', 'Satu', 'Dua', 'Tiga', 'Empat', 'Lima', 'Enam', 'Tujuh', 'Delapan', 'Sembilan',
        'Sepuluh', 'Sebelas', 'Dua Belas', 'Tiga Belas', 'Empat Belas', 'Lima Belas',
        'Enam Belas', 'Tujuh Belas', 'Delapan Belas', 'Sembilan Belas'
      ]

      tens = [
        '', '', 'Dua Puluh', 'Tiga Puluh', 'Empat Puluh', 'Lima Puluh',
        'Enam Puluh', 'Tujuh Puluh', 'Delapan Puluh', 'Sembilan Puluh'
      ]

      scales = [
        '', 'Ribu', 'Juta', 'Miliar', 'Triliun'
      ]

      def convert_hundreds(num, words, tens, scales, scale_index)
        return '' if num == 0

        result = ''

        # Hundreds
        hundreds_digit = (num / 100).to_i
        if hundreds_digit > 0
          result += (hundreds_digit == 1 ? 'Seratus' : words[hundreds_digit] + ' Ratus')
          result += ' '
        end

        # Tens and ones
        remainder = num % 100
        if remainder >= 20
          tens_digit = (remainder / 10).to_i
          ones_digit = remainder % 10
          result += tens[tens_digit]
          result += ' ' + words[ones_digit] if ones_digit > 0
        elsif remainder > 0
          result += words[remainder]
        end

        result = result.strip
        result += ' ' + scales[scale_index] if scale_index > 0 && !result.empty?
        result
      end

      # Break number into groups of three
      parts = []
      while number > 0
        parts.unshift(number % 1000)
        number /= 1000
      end

      result = ''
      parts.each_with_index do |part, idx|
        scale_index = parts.length - 1 - idx
        group_words = convert_hundreds(part, words, tens, scales, scale_index)
        result += group_words + ' ' unless group_words.empty?
      end

      result.strip
    end

    # Format number with decimal places
    def self.format_number(number, decimals = 2)
      format("%.#{decimals}f", number.to_f)
    end

    # Convert area units
    def self.m2_to_cm2(m2)
      (m2 * 10000).round(2)
    end

    def self.cm2_to_m2(cm2)
      (cm2 / 10000).round(4)
    end

    # Convert volume units
    def self.m3_to_cm3(m3)
      (m3 * 1000000).round(2)
    end

    def self.cm3_to_m3(cm3)
      (cm3 / 1000000).round(6)
    end

    # Convert weight
    def self.kg_to_gram(kg)
      (kg * 1000).round(0)
    end

    def self.gram_to_kg(gram)
      (gram / 1000).round(4)
    end

    # Percentage calculation
    def self.add_percentage(base, percentage)
      (base + (base * percentage / 100)).round(2)
    end

    def self.subtract_percentage(base, percentage)
      (base - (base * percentage / 100)).round(2)
    end

    def self.calculate_percentage(part, total)
      return 0.0 if total == 0
      ((part / total.to_f) * 100).round(2)
    end
  end
end
