# frozen_string_literal: true

require 'csv'

module Utils
  class DatagridPdfExporter
    DEFAULT_OPTIONS = {
      page_layout: :landscape,
      margin: 20
    }.freeze

    def initialize(grid, title: nil, pdf_options: {})
      @grid = grid
      @title = title.presence || 'Relatório'
      @pdf_options = DEFAULT_OPTIONS.merge(pdf_options)
    end

    def call
      begin
        require 'prawn'
      rescue LoadError => e
        raise "Gem prawn não encontrada. Execute 'bundle install' para instalar as dependências necessárias."
      end

      csv_rows = parsed_rows

      Prawn::Document.new(@pdf_options) do |pdf|
        pdf.text @title, size: 14, style: :bold
        pdf.move_down 10

        if csv_rows.any?
          pdf.table(
            csv_rows,
            header: true,
            row_colors: %w[FFFFFF F7F7F7],
            cell_style: { size: 8 }
          )
        else
          pdf.text 'Nenhum dado encontrado para os filtros aplicados.', size: 10
        end
      end.render
    end

    private

    def parsed_rows
      csv_content = @grid.to_csv(col_sep: ';')
      CSV.parse(csv_content, col_sep: ';')
    rescue StandardError
      []
    end
  end
end
