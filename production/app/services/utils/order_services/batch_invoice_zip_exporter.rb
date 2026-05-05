require 'zip'

module Utils
  module OrderServices
    # Empacota em um ZIP os PDFs/arquivos anexados como Notas Fiscais
    # (OrderServiceInvoice) das OSs selecionadas. Para cada arquivo anexado,
    # o nome dentro do ZIP segue o padrão:
    #   OS{codigo}_{Fornecedor}_{Tipo}.{ext}
    #
    # Quando uma OS não tem nenhuma NF anexada, ela é listada em um
    # arquivo "_os_sem_nf_anexada.txt" dentro do ZIP, para o usuário saber.
    class BatchInvoiceZipExporter
      def initialize(order_services)
        @order_services = order_services
      end

      # Retorna [zip_bytes, total_anexadas]
      def call
        total_anexadas = 0
        faltantes = []
        used_names = Hash.new(0)

        buffer = Zip::OutputStream.write_buffer do |zos|
          @order_services.each do |os|
            approved = find_approved_proposal(os)
            invoices = approved ? approved.order_service_invoices.to_a : []
            invoices_with_file = invoices.select { |i| i.file.attached? }

            if invoices_with_file.empty?
              faltantes << "#{os.code} - #{provider_name(approved)}"
              next
            end

            invoices_with_file.each do |inv|
              tipo = tipo_label(inv.order_service_invoice_type_id)
              fornecedor = sanitize(provider_name(approved))
              base_name = "OS#{sanitize(os.code)}_#{fornecedor}_#{tipo}"
              ext = File.extname(inv.file.filename.to_s).presence || '.pdf'

              name = "#{base_name}#{ext}"
              if used_names[name] > 0
                name = "#{base_name}_#{used_names[name] + 1}#{ext}"
              end
              used_names[name] += 1

              zos.put_next_entry(name)
              inv.file.blob.download { |chunk| zos.write(chunk) }
              total_anexadas += 1
            end
          end

          if faltantes.any?
            zos.put_next_entry('_os_sem_nf_anexada.txt')
            zos.write("As seguintes OSs não possuem arquivo de NF anexado:\n\n")
            faltantes.uniq.each { |line| zos.write("- #{line}\n") }
          end
        end

        buffer.rewind
        [buffer.read, total_anexadas]
      end

      private

      def find_approved_proposal(os)
        os.order_service_proposals.find do |p|
          OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES.include?(p.order_service_proposal_status_id)
        end
      end

      def provider_name(proposal)
        provider = proposal&.provider
        (provider&.fantasy_name.presence || provider&.social_name.presence || provider&.name || 'Fornecedor').to_s
      end

      def tipo_label(type_id)
        case type_id
        when OrderServiceInvoiceType::PECAS_ID then 'Pecas'
        when OrderServiceInvoiceType::SERVICOS_ID then 'Servicos'
        else 'Outros'
        end
      end

      def sanitize(str)
        str.to_s.gsub(/[^0-9A-Za-zÀ-ÿ\- ]/, '').tr(' ', '_').squeeze('_').gsub(/_+$/, '').presence || 'Fornecedor'
      end
    end
  end
end
