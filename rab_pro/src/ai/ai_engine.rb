# ==============================================================================
# RAB Pro - AI Engine
# Claude API integration for RAB analysis, suggestions, and anomaly detection
# ==============================================================================

module RABPro
  module AI
    class AIEngine

      def initialize(settings: nil, project_store: nil)
        @settings      = settings
        @project_store = project_store
        @api_key       = Sketchup.read_default('RABPro', 'api_key', '')
      end

      # -----------------------------------------------------------------------
      # Analyze RAB document for insights
      # -----------------------------------------------------------------------
      def analyze_rab(rab_document)
        return { error: 'Tidak ada API key' } if @api_key.empty?

        prompt = _build_analysis_prompt(rab_document)
        result = _query_claude(prompt)
        result
      end

      # -----------------------------------------------------------------------
      # Suggest alternatives for a category
      # -----------------------------------------------------------------------
      def suggest_alternatives(category_id, count: 3)
        return { error: 'Tidak ada API key' } if @api_key.empty?

        cat = Data::CategoryLibrary.find(category_id)
        return { error: 'Kategori tidak ditemukan' } unless cat

        prompt = <<~PROMPT
          Saya memerlukan #{count} alternatif untuk pekerjaan berikut:
          Kategori: #{cat.name}
          Unit: #{cat.unit}
          Deskripsi: #{cat.description}

          Berikan alternatif dengan:
          1. Nama produk/metode
          2. Kelebihan & kekurangan
          3. Perkiraan harga relatif (lebih mahal/murah %)
          4. Kualitas/durabilitas
          5. Rekomendasi

          Format JSON dengan array dari hasil.
        PROMPT

        result = _query_claude(prompt)
        result
      end

      # -----------------------------------------------------------------------
      # Detect cost anomalies
      # -----------------------------------------------------------------------
      def detect_anomalies(rab_lines)
        return { anomalies: [] } if rab_lines.empty?

        # Calculate statistics
        prices = rab_lines.map { |l| l[:unit_price] }.compact
        quantities = rab_lines.map { |l| l[:quantity] }.compact

        price_mean = prices.sum / prices.size.to_f
        price_std  = Math.sqrt(prices.map { |p| (p - price_mean) ** 2 }.sum / prices.size)

        qty_mean = quantities.sum / quantities.size.to_f
        qty_std  = Math.sqrt(quantities.map { |q| (q - qty_mean) ** 2 }.sum / quantities.size)

        anomalies = []

        rab_lines.each do |line|
          # Price anomaly (3 sigma)
          if line[:unit_price] > (price_mean + 3 * price_std)
            anomalies << {
              type: 'price_high',
              category: line[:category_name],
              value: line[:unit_price],
              reason: 'Harga jauh lebih tinggi dari rata-rata'
            }
          end

          # Quantity anomaly
          if line[:quantity] > (qty_mean + 2 * qty_std)
            anomalies << {
              type: 'quantity_high',
              category: line[:category_name],
              value: line[:quantity],
              reason: 'Kuantitas jauh lebih tinggi dari rata-rata'
            }
          end
        end

        { anomalies: anomalies, count: anomalies.size }
      end

      # -----------------------------------------------------------------------
      # Set API key
      # -----------------------------------------------------------------------
      def set_api_key(key)
        @api_key = key.to_s.strip
        Sketchup.write_default('RABPro', 'api_key', @api_key)
        { ok: true, message: 'API key tersimpan' }
      end

      # -----------------------------------------------------------------------
      # Test API connection
      # -----------------------------------------------------------------------
      def test_connection
        return { ok: false, message: 'Tidak ada API key' } if @api_key.empty?

        result = _query_claude('Halo, ini test koneksi. Jawab "OK" saja.')
        { ok: result[:success], message: result[:response] }
      end

      private

      def _build_analysis_prompt(rab_doc)
        sections_text = rab_doc.sections.map do |s|
          items = s.items.map { |i| "  - #{i.category_name}: #{i.quantity} #{i.unit} × BND$#{i.unit_price} = BND$#{i.total_price}" }.join("\n")
          "#{s.group_label}:\n#{items}"
        end.join("\n\n")

        <<~PROMPT
          Analisa dokumen RAB berikut dan berikan insights:

          Proyek: #{rab_doc.project_info&.dig(:name) || 'Tidak ada nama'}
          Total: BND$#{rab_doc.grand_total}
          Overhead: #{rab_doc.overhead_pct}%
          Profit: #{rab_doc.profit_pct}%
          PPN: #{rab_doc.ppn_pct}%

          #{sections_text}

          Berikan:
          1. Ringkasan cost breakdown
          2. Kategori dengan biaya tertinggi
          3. Rekomendasi optimasi biaya
          4. Potensi penghematan
          5. Risk assessment
        PROMPT
      end

      def _query_claude(prompt)
        begin
          Logger.info("AIEngine: querying Claude API")

          # Placeholder untuk Claude API call
          # Di production, gunakan HTTP client untuk call Claude API
          # Untuk sekarang return mock response
          {
            success: true,
            response: "Mock response dari Claude API. Implementasi penuh memerlukan HTTP client gem.",
            usage: { input_tokens: 0, output_tokens: 0 }
          }
        rescue => e
          Logger.error("AIEngine.query: #{e.message}")
          { success: false, error: e.message }
        end
      end

    end
  end
end
