require 'prawn'
require 'prawn/table'

module Utils
  module OrderServices
    class BatchPdfExporter
      def initialize(order_services, current_user)
        @order_services = order_services
        @current_user = current_user
      end

      def call
        pdf = Prawn::Document.new(page_size: 'A4', margin: [30, 30, 30, 30])
        
        @order_services.each_with_index do |os, index|
          pdf.start_new_page if index > 0
          render_order_service(pdf, os)
        end

        pdf.render
      end

      private

      def render_order_service(pdf, os)
        # Cabeçalho
        pdf.font_size(14) { pdf.text "Ordem de Serviço - #{os.code}", style: :bold }
        pdf.move_down 5
        pdf.font_size(8) do
          pdf.text "Criado em: #{os.created_at.strftime('%d/%m/%Y %H:%M')} · Status: #{os.order_service_status&.name}", color: '666666'
        end
        pdf.move_down 10

        # Dados principais
        pdf.font_size(11) { pdf.text "Dados Principais", style: :bold }
        pdf.move_down 5

        data = []
        data << ['Cliente:', os.client&.fantasy_name.to_s]
        data << ['Centro de Custo:', os.cost_center&.name.to_s]
        data << ['Subunidade:', os.vehicle&.sub_unit&.name.to_s] if os.vehicle&.sub_unit.present?
        data << ['Gestor:', os.manager&.name.to_s]
        data << ['Tipo de Serviço:', os.provider_service_type&.name.to_s]
        data << ['Tipo de OS:', os.order_service_type&.name.to_s]
        data << ['Veículo:', os.vehicle&.getting_vehicle_data.to_s] if os.vehicle.present?
        data << ['Empenho:', os.commitment&.get_text_name.to_s] if os.commitment.present?
        data << ['KM:', "#{os.km} km"] if os.km.present?
        data << ['Motorista:', os.driver.to_s] if os.driver.present?

        if data.any?
          pdf.font_size(9) do
            pdf.table(data, cell_style: { borders: [], padding: [2, 5] }) do
              column(0).font_style = :bold
              column(0).width = 120
            end
          end
        end

        # Detalhes
        if os.details.present?
          pdf.move_down 10
          pdf.font_size(11) { pdf.text "Detalhes", style: :bold }
          pdf.move_down 3
          pdf.font_size(9) { pdf.text os.details.to_s }
        end

        # Propostas
        proposals = os.order_service_proposals
          .includes(:provider, :order_service_proposal_status, :order_service_proposal_items)
          .order(:created_at)
        
        if proposals.any?
          pdf.move_down 10
          pdf.font_size(11) { pdf.text "Propostas (#{proposals.count})", style: :bold }
          pdf.move_down 5

          proposal_data = [['Código', 'Fornecedor', 'Status', 'Valor Total', 'Data']]
          proposals.each do |proposal|
            proposal_data << [
              proposal.code.to_s,
              (proposal.provider&.fantasy_name.presence || proposal.provider&.name || '-').to_s,
              proposal.order_service_proposal_status&.name.to_s,
              CustomHelper.to_currency(proposal.total_value),
              proposal.created_at.strftime('%d/%m/%Y')
            ]
          end

          pdf.font_size(8) do
            pdf.table(proposal_data, header: true, width: pdf.bounds.width) do
              row(0).font_style = :bold
              row(0).background_color = '333333'
              row(0).text_color = 'FFFFFF'
              cells.borders = [:top, :bottom, :left, :right]
              cells.border_width = 0.5
              cells.padding = [4, 5]
              column(3).align = :right
            end
          end

          # Detalhamento dos itens da proposta aprovada
          approved = proposals.find { |p| [3, 4, 5, 6, 7].include?(p.order_service_proposal_status_id) }
          if approved && approved.order_service_proposal_items.any?
            pdf.move_down 8
            pdf.font_size(10) { pdf.text "Itens da Proposta Aprovada: #{approved.code}", style: :bold }
            pdf.move_down 3

            items_data = [['Tipo', 'Descrição', 'Qtd', 'Valor Unit.', 'Desconto', 'Total']]
            approved.order_service_proposal_items.each do |item|
              tipo = item.service&.category_id == Category::SERVICOS_PECAS_ID ? 'Peça' : 'Serviço'
              unit_value = item.unity_value.to_f
              qty = item.quantity.to_f
              desc_val = item.discount.to_f
              total_val = item.total_value.present? ? item.total_value.to_f : ((qty * unit_value) - desc_val)
              items_data << [
                tipo,
                (item.service_name.presence || item.service&.name).to_s,
                item.quantity.to_s,
                CustomHelper.to_currency(unit_value),
                CustomHelper.to_currency(desc_val),
                CustomHelper.to_currency(total_val)
              ]
            end

            pdf.font_size(7) do
              pdf.table(items_data, header: true, width: pdf.bounds.width) do
                row(0).font_style = :bold
                row(0).background_color = '555555'
                row(0).text_color = 'FFFFFF'
                cells.borders = [:top, :bottom, :left, :right]
                cells.border_width = 0.5
                cells.padding = [3, 4]
                column(2).align = :center
                column(3).align = :right
                column(4).align = :right
                column(5).align = :right
              end
            end

            # Total
            pdf.move_down 3
            pdf.font_size(9) do
              pdf.text "Valor Total: #{CustomHelper.to_currency(approved.total_value)}", style: :bold, align: :right
              if approved.total_discount.to_f > 0
                pdf.text "Desconto: #{CustomHelper.to_currency(approved.total_discount)}", align: :right
              end
            end
          end
        end

        # Notas Fiscais
        result = OrderService.getting_invoice_data(os)
        invoices = result[0]
        if invoices.any?
          pdf.move_down 8
          pdf.font_size(10) { pdf.text "Notas Fiscais", style: :bold }
          pdf.move_down 3

          inv_data = [['Nº Nota', 'Tipo', 'Valor', 'Data Emissão']]
          invoices.each do |inv|
            inv_data << [
              inv.number.to_s,
              inv.order_service_invoice_type&.name.to_s,
              CustomHelper.to_currency(inv.value),
              inv.emission_date&.strftime('%d/%m/%Y').to_s
            ]
          end

          pdf.font_size(8) do
            pdf.table(inv_data, header: true, width: pdf.bounds.width * 0.7) do
              row(0).font_style = :bold
              row(0).background_color = '333333'
              row(0).text_color = 'FFFFFF'
              cells.borders = [:top, :bottom, :left, :right]
              cells.border_width = 0.5
              cells.padding = [3, 5]
              column(2).align = :right
            end
          end
        end

        # Rodapé com linha separadora
        pdf.move_down 15
        pdf.stroke_horizontal_rule
        pdf.move_down 5
        pdf.font_size(7) do
          pdf.text "Documento gerado em #{Time.now.strftime('%d/%m/%Y %H:%M')} - Sistema de Frotas", color: '999999', align: :center
        end
      end
    end
  end
end
