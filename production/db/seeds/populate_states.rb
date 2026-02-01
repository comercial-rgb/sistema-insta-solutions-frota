datetime_now = DateTime.now
array = [
	{created_at: datetime_now, updated_at: datetime_now, id: 1, ibge_code: '12', name: 'Acre', acronym: 'AC', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 2, ibge_code: '27', name: 'Alagoas', acronym: 'AL', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 3, ibge_code: '16', name: 'Amapá', acronym: 'AP', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 4, ibge_code: '13', name: 'Amazônas', acronym: 'AM', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 5, ibge_code: '29', name: 'Bahia', acronym: 'BA', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 6, ibge_code: '23', name: 'Ceará', acronym: 'CE', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 7, ibge_code: '53', name: 'Distrito Federal', acronym: 'DF', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 8, ibge_code: '32', name: 'Espírito Santo', acronym: 'ES', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 9, ibge_code: '52', name: 'Goiás', acronym: 'GO', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 10, ibge_code: '21', name: 'Maranhão', acronym: 'MA', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 11, ibge_code: '50', name: 'Mato Grosso do Sul', acronym: 'MS', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 12, ibge_code: '51', name: 'Mato Grosso', acronym: 'MT', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 13, ibge_code: '31', name: 'Minas Gerais', acronym: 'MG', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 14, ibge_code: '15', name: 'Pará', acronym: 'PA', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 15, ibge_code: '25', name: 'Paraíba', acronym: 'PB', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 16, ibge_code: '41', name: 'Paraná', acronym: 'PR', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 17, ibge_code: '26', name: 'Pernambuco', acronym: 'PE', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 18, ibge_code: '22', name: 'Piauí', acronym: 'PI', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 19, ibge_code: '33', name: 'Rio de Janeiro', acronym: 'RJ', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 20, ibge_code: '24', name: 'Rio Grande do Norte', acronym: 'RN', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 21, ibge_code: '43', name: 'Rio Grande do Sul', acronym: 'RS', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 22, ibge_code: '11', name: 'Rondônia', acronym: 'RO', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 23, ibge_code: '14', name: 'Roraima', acronym: 'RR', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 24, ibge_code: '42', name: 'Santa Catarina', acronym: 'SC', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 25, ibge_code: '35', name: 'Sao Paulo', acronym: 'SP', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 26, ibge_code: '28', name: 'Sergipe', acronym: 'SE', country_id: 33},
	{created_at: datetime_now, updated_at: datetime_now, id: 27, ibge_code: '17', name: 'Tocantins', acronym: 'TO', country_id: 33}
]

State.insert_all(array)