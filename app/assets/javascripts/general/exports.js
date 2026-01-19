$(document).ready(function() {

	let button = document.getElementById("button-export-table");
	if (button) {
		button.addEventListener("click", () => {
			const table = document.getElementById("table-fatured-invoices");
			const wb = XLSX.utils.table_to_book(table, { sheet: "Planilha" });
			XLSX.writeFile(wb, "dados.xlsx");
		});
	}

	$('#button-export-table').on('click', function () {
		// $('#table-fatured-invoices').btechco_excelexport({
		// 	containerid: 'table-fatured-invoices',
		// 	datatype: $datatype.Table,
		// 	filename: 'filename'
		// });
	});

	// $('#id-button-export').on('click', function () {
	// 	exportTableToCSV('nome-tabela.csv', 'id-tabela')
	// });

	// function downloadCSV(csv, filename) {
	// 	var csvFile;
	// 	var downloadLink;

	// 	// CSV file
	// 	csvFile = new Blob([csv], {type: "text/csv"});

	// 	// Download link
	// 	downloadLink = document.createElement("a");

	// 	// File name
	// 	downloadLink.download = filename;

	// 	// Create a link to the file
	// 	downloadLink.href = window.URL.createObjectURL(csvFile);

	// 	// Hide download link
	// 	downloadLink.style.display = "none";

	// 	// Add the link to DOM
	// 	document.body.appendChild(downloadLink);

	// 	// Click download link
	// 	downloadLink.click();
	// }

	// function exportTableToCSV(filename, table_id) {
	// 	var csv = [];
	// 	var rows = document.querySelectorAll("#"+table_id+" tr");

	// 	for (var i = 0; i < rows.length; i++) {
	// 		var row = [], cols = rows[i].querySelectorAll("td, th");

	// 		for (var j = 0; j < cols.length; j++)
	// 			row.push('"' + cols[j].innerText + '"');

	// 		csv.push(row.join(","));
	// 	}

	// 	// Download CSV file
	// 	downloadCSV(csv.join("\n"), filename);
	// }

});