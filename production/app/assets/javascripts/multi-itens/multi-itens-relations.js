/*
* REGRAS:
* - a div a ser clonada deverá ter a classe multi-nome
* - a div deverá ter o hidden multi-nome-cont começando com zero
* - o botão de adicionar terá a classe multi-nome-add
* - o botão de deletar terá a classe multi-nome-del
*/

// <script>
// 	multiRelation('field', position, true);
// </script>

function multiRelation(nome, position, enableDel){
	var item      = '.multi-' + nome + '-' + position;
	var addButton = '.multi-' + nome + '-' + position+ '-add';
	var delButton = '.multi-' + nome + '-' + position+ '-del';
	var contEl    = '.multi-' + nome + '-' + position+ '-cont';

	//ao clicar no botão de adicionar
	$(document).on('click', addButton, function(){

		//incrementa-se o cont
		var cont = $(contEl).val();
		cont++;
		$(contEl).val(cont);

		//clona-se a div
		var clone = $(item).last().clone();

		//pra cada input, select e textarea
		clone.find('input, select, textarea').each(function(index, el) {
			//muda-se o id e o nome

			// console.log(this.name);
			// console.log(this.id);

			var splits_name = this.name.split('['+position+']');
			var splits_id = this.id.split('_'+position+'_');

			if(splits_name.length == 3) {
				name = this.name;
				id = this.name;
				
				var t = 0;   
				name = name.replace(/[0-9]/g, function (match) {
					t++;
					return (t === 2) ? cont : match;
				});  

				new_id = splits_id[0]+'_'+position+'_'+splits_id[1]+'_'+cont+'_'+splits_id[2];

				this.name = name;
				this.id = new_id;
			} else if(splits_name.length == 2){
				var older_name = splits_name[1];
				var replaced_name = older_name.replace(older_name.match("[0-9]"), cont);
				this.name = this.name.replace(older_name, replaced_name);

				var older_id = splits_id[1];
				var replaced_id = older_id.replace(older_id.match("[0-9]"), cont);
				this.id = this.id.replace(older_id, replaced_id)
			}

			if( $(this).attr('class') == 'phone' ){

				$(".phone").inputmask({
					mask: ["(99) 9999-9999", "(99) 99999-9999" ],
					keepStatic: true
				});

			} 
			else if( $(this).hasClass('money') ){
				$(this).unmask();
				$(this).mask("000.000.000.000,00", {reverse: true});
			}

			//limpa o valor
			this.value = '';
		});

		//coloca-se no parent
		clone.appendTo( $(item).parent() );

		//para não dar submit
		return false;
	});

	//caso o parâmetro de ativação do botão de exclusão do item seja falso, o gatilho de execução
	//deverá ser reescrito. Isso é útil para quando houverem outras operações além de remover o
	//item, como cálculos.
	if(enableDel){
		$(document).on('click', delButton, function() {
			//verificação que impede a exclusão de quando houve apenas um item
			if($(item).length > 1){
				//após o fade, remove o item
				$(this).parent().fadeOut('fast', function(){
					$(this).remove();
				});
			}
			return false;
		});
	}
}