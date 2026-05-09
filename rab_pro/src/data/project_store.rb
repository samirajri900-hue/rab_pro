# ==============================================================================
# RAB Pro - Project Store
# Manage project-level data persistence and state
# ==============================================================================

module RABPro
  module Data
    class ProjectStore
      
      attr_reader :settings
      
      # Project information structure
      ProjectInfo = Struct.new(:name, :owner, :location, :consultant, :contractor, 
                                :start_date, :end_date, :description) do
        def to_h
          {
            name:         self.name,
            owner:        self.owner,
            location:     self.location,
            consultant:   self.consultant,
            contractor:   self.contractor,
            start_date:   self.start_date,
            end_date:     self.end_date,
            description:  self.description
          }
        end
      end

      def initialize(settings_manager)
        @settings = settings_manager
        @project_info = nil
        @custom_prices = {}
        @overhead_pct = 15.0
        @profit_pct = 20.0
        @ppn_pct = 10.0
        _load_from_model
      end

      # Get project info
      # @return [ProjectInfo]
      def project_info
        @project_info ||= ProjectInfo.new(
          'Untitled Project',
          'Unknown Owner',
          'Unknown Location',
          'Unknown Consultant',
          'Unknown Contractor',
          Time.now.to_s,
          (Time.now + 30*24*3600).to_s,
          ''
        )
      end

      # Save project info
      # @param [Hash] info
      def save_project_info(info)
        @project_info = ProjectInfo.new(
          info[:name] || project_info.name,
          info[:owner] || project_info.owner,
          info[:location] || project_info.location,
          info[:consultant] || project_info.consultant,
          info[:contractor] || project_info.contractor,
          info[:start_date] || project_info.start_date,
          info[:end_date] || project_info.end_date,
          info[:description] || project_info.description
        )
        _save_to_model
        Logger.info("Project info saved: #{@project_info.name}")
      end

      # Get financial settings
      def overhead_pct
        @overhead_pct
      end

      def profit_pct
        @profit_pct
      end

      def ppn_pct
        @ppn_pct
      end

      # Save financial settings
      # @param [Hash] opts
      def save_financial_settings(opts = {})
        @overhead_pct = opts[:overhead].to_f if opts[:overhead]
        @profit_pct = opts[:profit].to_f if opts[:profit]
        @ppn_pct = opts[:ppn].to_f if opts[:ppn]
        _save_to_model
        Logger.info("Financial settings saved")
      end

      # Get custom price for a category
      # @param [String] item_key
      # @return [Float] price or 0.0
      def get_price(item_key)
        @custom_prices[item_key.to_s] || 0.0
      end

      # Set custom price
      # @param [String] item_key
      # @param [Float] price
      def set_price(item_key, price)
        @custom_prices[item_key.to_s] = price.to_f
        _save_to_model
        Logger.info("Price set: #{item_key} = #{price}")
      end

      # Get all custom prices
      # @return [Hash]
      def all_custom_prices
        @custom_prices.dup
      end

      # Attach to a model (load model-specific data)
      # @param [Sketchup::Model] model
      def attach(model)
        @model = model
        _load_from_model
        Logger.info("ProjectStore attached to model")
      end

      private

      def _load_from_model
        model = Sketchup.active_model
        return unless model
        
        begin
          # Try to load from model attributes
          data = model.get_attribute('RABPro', 'project_info')
          if data && data.is_a?(String)
            info_hash = JSON.parse(data)
            @project_info = ProjectInfo.new(
              info_hash['name'],
              info_hash['owner'],
              info_hash['location'],
              info_hash['consultant'],
              info_hash['contractor'],
              info_hash['start_date'],
              info_hash['end_date'],
              info_hash['description']
            )
          end
          
          # Load financial settings
          @overhead_pct = model.get_attribute('RABPro', 'overhead_pct', 15.0).to_f
          @profit_pct = model.get_attribute('RABPro', 'profit_pct', 20.0).to_f
          @ppn_pct = model.get_attribute('RABPro', 'ppn_pct', 10.0).to_f
          
          # Load custom prices
          prices_json = model.get_attribute('RABPro', 'custom_prices')
          @custom_prices = prices_json ? JSON.parse(prices_json) : {}
          
          Logger.info("ProjectStore loaded from model")
        rescue => e
          Logger.warn("ProjectStore._load_from_model: #{e.message}")
        end
      end

      def _save_to_model
        model = Sketchup.active_model
        return unless model
        
        begin
          require 'json'
          
          # Save project info
          model.set_attribute('RABPro', 'project_info', JSON.generate(project_info.to_h))
          
          # Save financial settings
          model.set_attribute('RABPro', 'overhead_pct', @overhead_pct)
          model.set_attribute('RABPro', 'profit_pct', @profit_pct)
          model.set_attribute('RABPro', 'ppn_pct', @ppn_pct)
          
          # Save custom prices
          model.set_attribute('RABPro', 'custom_prices', JSON.generate(@custom_prices))
          
          Logger.info("ProjectStore saved to model")
        rescue => e
          Logger.error("ProjectStore._save_to_model: #{e.message}")
        end
      end
    end
  end
end
