# ==============================================================================
# RAB Pro - Settings Manager Utility
# Manage persistent application settings using SketchUp registry
# ==============================================================================

module RABPro
  class SettingsManager
    DEFAULT_SETTINGS = {
      currency: 'IDR',
      currency_symbol: 'Rp',
      language: 'id',
      timezone: 'Asia/Jakarta',
      export_path: File.expand_path('~/Desktop'),
      pdf_paper_size: 'A3',
      pdf_orientation: 'landscape',
      units: 'metric', # 'metric' or 'imperial'
      decimals: 2,
      overhead_pct: 15.0,
      profit_pct: 20.0,
      ppn_pct: 10.0,
      panel_x: 100,
      panel_y: 100,
      panel_width: 800,
      panel_height: 600,
      auto_save: true,
      auto_save_interval: 300, # seconds
      theme: 'light',
      show_tips: true,
      last_export_format: 'excel'
    }.freeze

    def initialize
      @settings_key = 'RABPro'
      @defaults = DEFAULT_SETTINGS.dup
      _load_defaults_if_needed
    end

    # Get a setting value
    def get(key, default = nil)
      key_str = key.to_s
      value = Sketchup.read_default(@settings_key, key_str)
      value.nil? ? (default || @defaults[key.to_sym]) : _parse_value(value)
    end

    # Set a setting value
    def set(key, value)
      key_str = key.to_s
      Sketchup.write_default(@settings_key, key_str, value.to_s)
      Logger.info("Setting #{key} = #{value}")
    end

    # Get all settings as hash
    def to_hash
      hash = {}
      @defaults.each_key do |k|
        hash[k] = get(k)
      end
      hash
    end

    # Load settings from hash
    def from_hash(hash)
      hash.each do |key, value|
        set(key, value) unless value.nil?
      end
    end

    # Reset to defaults
    def reset_to_defaults
      @defaults.each do |key, value|
        set(key, value)
      end
      Logger.info('Settings reset to defaults')
    end

    # Get panel geometry
    def panel_geometry
      {
        x:      get(:panel_x, 100).to_i,
        y:      get(:panel_y, 100).to_i,
        width:  get(:panel_width, 800).to_i,
        height: get(:panel_height, 600).to_i
      }
    end

    # Set panel geometry
    def set_panel_geometry(x, y, width, height)
      set(:panel_x, x)
      set(:panel_y, y)
      set(:panel_width, width)
      set(:panel_height, height)
    end

    # Get financial settings
    def financial_settings
      {
        overhead_pct: get(:overhead_pct, 15.0).to_f,
        profit_pct:   get(:profit_pct, 20.0).to_f,
        ppn_pct:      get(:ppn_pct, 10.0).to_f
      }
    end

    # Check if key exists
    def key_exists?(key)
      Sketchup.read_default(@settings_key, key.to_s) != nil
    end

    # Delete a setting
    def delete(key)
      # SketchUp doesn't have a built-in delete, so we set to empty
      Sketchup.write_default(@settings_key, key.to_s, '')
      Logger.info("Setting #{key} deleted")
    end

    # Clear all settings
    def clear_all
      @defaults.each_key do |k|
        delete(k)
      end
      Logger.info('All settings cleared')
    end

    private

    def _load_defaults_if_needed
      @defaults.each do |key, value|
        set(key, value) unless key_exists?(key)
      end
    end

    def _parse_value(str)
      # Try to parse as number
      return str.to_i if str.match?(/^\d+$/)
      return str.to_f if str.match?(/^\d+\.\d+$/)
      # Try to parse as boolean
      return true if str.downcase == 'true'
      return false if str.downcase == 'false'
      # Return as string
      str
    end
  end
end
