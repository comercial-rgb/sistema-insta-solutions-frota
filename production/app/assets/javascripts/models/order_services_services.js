document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll(".submit-new-service").forEach(button => {
      button.addEventListener("click", function () {
        const categoryId = this.dataset.categoryId;
        const name = document.getElementById(`service_name_${categoryId}`).value;
  
        fetch("/services.json", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
          },
          body: JSON.stringify({
            service: {
              name: name,
              category_id: categoryId
            }
          })
        })
        .then(response => response.json())
        .then(service => {
          if (service.id) {
            
            // Novo layout compacto: adicionar opção ao select e selecioná-la
            const selectNewItem = document.getElementById(`select-new-item-${categoryId}`);
            if (selectNewItem) {
              // Adicionar nova opção ao select
              const newOption = new Option(service.name, service.id, true, true);
              newOption.dataset.name = service.name;
              selectNewItem.appendChild(newOption);
              
              // Se usar Select2, atualizar
              if (typeof $ !== 'undefined' && $.fn.select2) {
                $(`#select-new-item-${categoryId}`).val(service.id).trigger('change');
              } else {
                selectNewItem.value = service.id;
              }
            } else {
              // Layout antigo: compatibilidade
              if (service.category_id == 1) {
                const btn = document.getElementsByClassName("multi-partserviceordeservice1-add")[0];
                if (btn) btn.click();
              } else if (service.category_id == 2) {
                const btn = document.getElementsByClassName("multi-partserviceordeservice2-add")[0];
                if (btn) btn.click();
              }

              // Encontrar todos os selects visíveis dessa categoria
              const allSelects = document.querySelectorAll(`select.service-select-${categoryId}`);
              const visibleSelects = Array.from(allSelects).filter(el => el.offsetParent !== null);
    
              // Usar o último visível
              const select = visibleSelects[visibleSelects.length - 1];
    
              if (select) {
                const newOption = new Option(service.name, service.id, true, true);
                select.appendChild(newOption);
                $(select).val(service.id).trigger("change");
              }
            }
  
            // Fechar modal e limpar campo
            const modal = document.getElementById(`newServiceModal${categoryId}`);
            bootstrap.Modal.getInstance(modal).hide();
  
            document.getElementById(`service_name_${categoryId}`).value = "";
          } else {
            alert("Erro ao cadastrar");
          }
        });
      });
    });
  });
  