# ==============================================================================
# RAB Pro - Chat Manager
# Manages AI conversation history and context for natural language interactions
# ==============================================================================

module RABPro
  module AI
    module Chat
      class ChatManager

        def initialize(model, settings: nil, project_store: nil)
          @model         = model
          @settings      = settings
          @project_store = project_store
          @history       = []
          @ai_engine     = AIEngine.new(settings: settings, project_store: project_store)
        end

        # -----------------------------------------------------------------------
        # Send message with optional model/RAB context
        # -----------------------------------------------------------------------
        def send(message, include_model_context: true, include_rab_context: false)
          raise 'Pesan kosong' if message.to_s.strip.empty?

          context = {}
          context[:model] = _build_model_context if include_model_context
          context[:rab]   = _build_rab_context if include_rab_context

          prompt = _build_prompt(message, context)
          result = @ai_engine._query_claude(prompt)

          # Store in history
          @history << {
            role: 'user',
            content: message,
            timestamp: Time.now.iso8601,
            context: context
          }

          @history << {
            role: 'assistant',
            content: result[:response],
            timestamp: Time.now.iso8601
          }

          result
        end

        # -----------------------------------------------------------------------
        # Direct query without history
        # -----------------------------------------------------------------------
        def query(message)
          @ai_engine._query_claude(message)
        end

        # -----------------------------------------------------------------------
        # Parse natural language commands
        # -----------------------------------------------------------------------
        def parse_model_command(text)
          text = text.to_s.downcase.strip

          commands = {
            /select.*wall/ => { action: 'select', type: 'walls' },
            /select.*column/ => { action: 'select', type: 'columns' },
            /select.*floor/ => { action: 'select', type: 'floors' },
            /show.*expensive/ => { action: 'filter', sort: 'price_desc' },
            /show.*most.*item/ => { action: 'filter', sort: 'count_desc' },
            /create.*scene/ => { action: 'create_scene' },
            /export.*rab/ => { action: 'export', format: 'excel' },
            /zoom.*all/ => { action: 'zoom', target: 'all' },
            /hide.*layer/ => { action: 'hide', type: 'layer' }
          }

          commands.each do |pattern, cmd|
            return cmd if pattern.match?(text)
          end

          { action: 'none', explanation: 'Perintah tidak dikenali' }
        end

        # -----------------------------------------------------------------------
        # Build model context for AI
        # -----------------------------------------------------------------------
        def build_model_context_summary
          reader = Core::Inspector::EntityReader.new(@model)
          summary = reader.summary

          {
            entities: "#{summary[:total_entities]} entities total",
            components: "#{summary[:component_count]} components",
            layers: "#{summary[:layer_count]} layers",
            materials: "#{summary[:material_count]} materials"
          }
        end

        # -----------------------------------------------------------------------
        # History management
        # -----------------------------------------------------------------------
        def history
          @history.map do |msg|
            { role: msg[:role], content: msg[:content], timestamp: msg[:timestamp] }
          end
        end

        def history_count
          @history.size
        end

        def clear_history
          @history = []
        end

        private

        def _build_prompt(message, context)
          ctx_text = ""
          if context[:model]
            ctx_text += "Model Context: #{context[:model][:entities]}, #{context[:model][:components]}\n"
          end
          if context[:rab]
            ctx_text += "RAB Context: Total #{context[:rab][:item_count]} items, BND$#{context[:rab][:total]}\n"
          end

          "#{ctx_text}\nUser: #{message}"
        end

        def _build_model_context
          reader = Core::Inspector::EntityReader.new(@model)
          summary = reader.summary
          {
            total_entities: summary[:total_entities],
            components: summary[:component_count],
            layers: summary[:layer_count],
            materials: summary[:material_count]
          }
        end

        def _build_rab_context
          qto = RAB::QuantityTakeoffEngine.new(@model)
          result = qto.run
          {
            item_count: result[:items].size,
            categories: result[:summary].size,
            total: 0  # Would compute total price
          }
        end

      end
    end
  end
end
