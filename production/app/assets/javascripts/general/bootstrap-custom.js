$(document).ready(() => {

	/**
	* Aqui nós vamos ativar todo ou qualquer componente "toast"
	* do bootstrap que exita no HTML
	* Existe uma view específica para renderizar o componente com apoio do flash do Rails
	*
	* Veja a documentação do componente: https://getbootstrap.com/docs/4.3/components/toasts
	*/
	$('.toast').toast('show');

	// Habilitando o tooltip do bootstrap (https://getbootstrap.com/docs/5.0/components/tooltips/)
	refreshTooltipFields();

	// Trocar icone + por -
	$('.form-panel').on('hidden.bs.collapse', toggleIcon);
	$('.form-panel').on('shown.bs.collapse', toggleIcon);

	// Habilitando pills
	var triggerTabList = [].slice.call(document.querySelectorAll('[data-bs-toggle="pill"]'))
	triggerTabList.forEach(function (triggerEl) {
		var tabTrigger = new bootstrap.Tab(triggerEl)

		triggerEl.addEventListener('click', function (event) {
			event.preventDefault()
			tabTrigger.show()
		})
	})

	var tabEl = document.querySelectorAll('a[data-bs-toggle="tab"]')
	if(tabEl != null){
		for(let i = 0; i < tabEl.length; i++){
			tabEl[i].addEventListener('shown.bs.tab', function (event) {
				$('select').select2();
				// event.target // newly activated tab
				// event.relatedTarget // previous active tab
			});
		}
	}

});

function refreshTooltipFields() {
	let tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
	let tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
		return new bootstrap.Tooltip(tooltipTriggerEl)
	});
	$('[data-bs-toggle="tooltip"]').click(function () {
		$('[data-bs-toggle="tooltip"]').tooltip("hide");
	});
}