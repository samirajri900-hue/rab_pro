# ==============================================================================
# RAB Pro - String Helper Utility
# Text processing utilities (slugify, camelize, humanize, etc.)
# ==============================================================================

module RABPro
  module StringHelper
    # Convert string to slug format (for URLs/identifiers)
    def self.slugify(str)
      str.to_s
        .downcase
        .gsub(/[^a-z0-9]+/, '_')
        .gsub(/_+/, '_')
        .gsub(/^_|_$/, '')
    end

    # Convert snake_case to CamelCase
    def self.camelize(str)
      str.to_s.split('_').map(&:capitalize).join('')
    end

    # Convert CamelCase to snake_case
    def self.snakeify(str)
      str.to_s
        .gsub(/::/, '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
    end

    # Convert snake_case to Human Readable
    def self.humanize(str)
      str.to_s
        .gsub(/_/, ' ')
        .split(' ')
        .map(&:capitalize)
        .join(' ')
    end

    # Truncate string with ellipsis
    def self.truncate(str, length = 50, suffix = '...')
      str = str.to_s
      return str if str.length <= length
      str[0, length - suffix.length] + suffix
    end

    # Convert number to Roman numerals
    def self.to_roman(num)
      num = num.to_i
      return '' if num <= 0

      roman_map = [
        [1000, 'M'], [900, 'CM'], [500, 'D'], [400, 'CD'],
        [100, 'C'], [90, 'XC'], [50, 'L'], [40, 'XL'],
        [10, 'X'], [9, 'IX'], [5, 'V'], [4, 'IV'], [1, 'I']
      ]

      result = ''
      roman_map.each do |value, letter|
        while num >= value
          result += letter
          num -= value
        end
      end
      result
    end

    # Convert Roman numerals to number
    def self.from_roman(roman)
      roman = roman.to_s.upcase
      return 0 if roman.empty?

      roman_values = {
        'I' => 1, 'V' => 5, 'X' => 10, 'L' => 50,
        'C' => 100, 'D' => 500, 'M' => 1000
      }

      result = 0
      i = 0
      while i < roman.length
        if i + 1 < roman.length && roman_values[roman[i]] < roman_values[roman[i + 1]]
          result += roman_values[roman[i + 1]] - roman_values[roman[i]]
          i += 2
        else
          result += roman_values[roman[i]]
          i += 1
        end
      end
      result
    end

    # Capitalize first letter only
    def self.capitalize_first(str)
      str = str.to_s
      str.empty? ? str : str[0].upcase + str[1..-1]
    end

    # Check if string is numeric
    def self.numeric?(str)
      str.to_s.match?(/^\d+(\.\d+)?$/)
    end

    # Remove duplicate spaces
    def self.remove_extra_spaces(str)
      str.to_s.gsub(/\s+/, ' ').strip
    end

    # Wrap text at word boundaries
    def self.word_wrap(str, width = 80)
      str.to_s.split(/\n/).map do |line|
        line.gsub(/(.{1,#{width}})(\s+|$)/, "\\1\n").rstrip
      end.join("\n")
    end

    # Extract numbers from string
    def self.extract_numbers(str)
      str.to_s.scan(/\d+(\.\d+)?/).map { |m| m[0] ? m.join : m[0] }
    end

    # Reverse string
    def self.reverse(str)
      str.to_s.reverse
    end

    # Check if string is empty or whitespace only
    def self.blank?(str)
      str.to_s.strip.empty?
    end
  end
end
