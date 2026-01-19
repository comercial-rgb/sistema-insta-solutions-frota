datetime_now = DateTime.now

array_Profile = [
	{name: Profile::ADMIN, created_at: datetime_now, updated_at: datetime_now},
	{name: Profile::USER, created_at: datetime_now, updated_at: datetime_now}
]
Profile.insert_all(array_Profile)

array_PersonType = [
	{id: 1, name: "Física", created_at: datetime_now, updated_at: datetime_now},
	{id: 2, name: "Jurídica", created_at: datetime_now, updated_at: datetime_now},
]
PersonType.insert_all(array_PersonType)

FactoryBot.create(:system_configuration,
	notification_mail: "notificacao@sistemainstasolutions.com.br",
	contact_mail: "contato@sistemainstasolutions.com.br",
	page_title: I18n.t("session.project"),
	phone: "(99) 99999-9999",
	cellphone: "(99) 99999-9999",
	page_description: I18n.t("session.project"),
	attendance_data: "Segunda e terça de 09:00 às 18:00"
	)

array_AddressType = [
	{name: "Aeroporto", created_at: datetime_now, updated_at: datetime_now},
	{name: "Alameda", created_at: datetime_now, updated_at: datetime_now},
	{name: "Área", created_at: datetime_now, updated_at: datetime_now},
	{name: "Avenida", created_at: datetime_now, updated_at: datetime_now},
	{name: "Campo", created_at: datetime_now, updated_at: datetime_now},
	{name: "Chácara", created_at: datetime_now, updated_at: datetime_now},
	{name: "Colônia", created_at: datetime_now, updated_at: datetime_now},
	{name: "Condomínio", created_at: datetime_now, updated_at: datetime_now},
	{name: "Conjunto", created_at: datetime_now, updated_at: datetime_now},
	{name: "Distrito", created_at: datetime_now, updated_at: datetime_now},
	{name: "Esplanada", created_at: datetime_now, updated_at: datetime_now},
	{name: "Estação", created_at: datetime_now, updated_at: datetime_now},
	{name: "Estrada", created_at: datetime_now, updated_at: datetime_now},
	{name: "Favela", created_at: datetime_now, updated_at: datetime_now},
	{name: "Fazenda", created_at: datetime_now, updated_at: datetime_now},
	{name: "Feira", created_at: datetime_now, updated_at: datetime_now},
	{name: "Jardim", created_at: datetime_now, updated_at: datetime_now},
	{name: "Ladeira", created_at: datetime_now, updated_at: datetime_now},
	{name: "Lago", created_at: datetime_now, updated_at: datetime_now},
	{name: "Lagoa", created_at: datetime_now, updated_at: datetime_now},
	{name: "Largo", created_at: datetime_now, updated_at: datetime_now},
	{name: "Loteamento", created_at: datetime_now, updated_at: datetime_now},
	{name: "Morro", created_at: datetime_now, updated_at: datetime_now},
	{name: "Núcleo", created_at: datetime_now, updated_at: datetime_now},
	{name: "Parque", created_at: datetime_now, updated_at: datetime_now},
	{name: "Passarela", created_at: datetime_now, updated_at: datetime_now},
	{name: "Pátio", created_at: datetime_now, updated_at: datetime_now},
	{name: "Praça", created_at: datetime_now, updated_at: datetime_now},
	{name: "Quadra", created_at: datetime_now, updated_at: datetime_now},
	{name: "Recanto", created_at: datetime_now, updated_at: datetime_now},
	{name: "Residencial", created_at: datetime_now, updated_at: datetime_now},
	{name: "Rodovia", created_at: datetime_now, updated_at: datetime_now},
	{name: "Rua", created_at: datetime_now, updated_at: datetime_now},
	{name: "Setor", created_at: datetime_now, updated_at: datetime_now},
	{name: "Sítio", created_at: datetime_now, updated_at: datetime_now},
	{name: "Travessa", created_at: datetime_now, updated_at: datetime_now},
	{name: "Trecho", created_at: datetime_now, updated_at: datetime_now},
	{name: "Trevo", created_at: datetime_now, updated_at: datetime_now},
	{name: "Vale", created_at: datetime_now, updated_at: datetime_now},
	{name: "Vereda", created_at: datetime_now, updated_at: datetime_now},
	{name: "Via", created_at: datetime_now, updated_at: datetime_now},
	{name: "Viaduto", created_at: datetime_now, updated_at: datetime_now},
	{name: "Viela", created_at: datetime_now, updated_at: datetime_now},
	{name: "Vila", created_at: datetime_now, updated_at: datetime_now},
]
AddressType.insert_all(array_AddressType)

array_AddressArea = [
	{name: "Geral", created_at: datetime_now, updated_at: datetime_now}
]
AddressArea.insert_all(array_AddressArea)

array_Sex = [
	{name: "Masculino", created_at: datetime_now, updated_at: datetime_now},
	{name: "Feminino", created_at: datetime_now, updated_at: datetime_now},
	{name: "Não quero informar", created_at: datetime_now, updated_at: datetime_now},
]
Sex.insert_all(array_Sex)

array_SiteContactSubject = [
	{name: "Dúvida", created_at: datetime_now, updated_at: datetime_now},
	{name: "Sugestão", created_at: datetime_now, updated_at: datetime_now},
	{name: "Reclamação", created_at: datetime_now, updated_at: datetime_now},
	{name: "Elogio", created_at: datetime_now, updated_at: datetime_now},
]
SiteContactSubject.insert_all(array_SiteContactSubject)

array_CategoryType = [
	{name: "Planos", created_at: datetime_now, updated_at: datetime_now},
	{name: "Produtos", created_at: datetime_now, updated_at: datetime_now},
	{name: "Serviços", created_at: datetime_now, updated_at: datetime_now},
	{name: "Veículos", created_at: datetime_now, updated_at: datetime_now},
]
CategoryType.insert_all(array_CategoryType)

array_Category = [
	{category_type_id: 3, name: "Peças", created_at: datetime_now, updated_at: datetime_now},
	{category_type_id: 3, name: "Serviços", created_at: datetime_now, updated_at: datetime_now},
]
Category.insert_all(array_Category)

array_UserStatus = [
	{name: "Aguardando aprovação", created_at: datetime_now, updated_at: datetime_now},
	{name: "Aprovado", created_at: datetime_now, updated_at: datetime_now},
	{name: "Reprovado", created_at: datetime_now, updated_at: datetime_now},
]
UserStatus.insert_all(array_UserStatus)

array_BudgetType = [
	{name: "Mensal", created_at: datetime_now, updated_at: datetime_now},
	{name: "Bimestral", created_at: datetime_now, updated_at: datetime_now},
	{name: "Trimestral", created_at: datetime_now, updated_at: datetime_now},
	{name: "Semestral", created_at: datetime_now, updated_at: datetime_now},
	{name: "Anual", created_at: datetime_now, updated_at: datetime_now},
]
BudgetType.insert_all(array_BudgetType)

array_FuelType = [
	{name: "Flex", created_at: datetime_now, updated_at: datetime_now},
	{name: "Gasolina", created_at: datetime_now, updated_at: datetime_now},
	{name: "Álcool", created_at: datetime_now, updated_at: datetime_now},
	{name: "Diesel", created_at: datetime_now, updated_at: datetime_now},
]
FuelType.insert_all(array_FuelType)

# Ordem correta dos status de OS (IDs fixos para garantir consistência)
array_OrderServiceStatus = [
	{id: 1, name: "Em cadastro", created_at: datetime_now, updated_at: datetime_now},
	{id: 2, name: "Em aberto", created_at: datetime_now, updated_at: datetime_now},
	{id: 3, name: "Em reavaliação", created_at: datetime_now, updated_at: datetime_now},
	{id: 4, name: "Aguardando avaliação de proposta", created_at: datetime_now, updated_at: datetime_now},
	{id: 5, name: "Aprovada", created_at: datetime_now, updated_at: datetime_now},
	{id: 6, name: "Nota fiscal inserida", created_at: datetime_now, updated_at: datetime_now},
	{id: 7, name: "Autorizada", created_at: datetime_now, updated_at: datetime_now},
	{id: 8, name: "Aguardando pagamento", created_at: datetime_now, updated_at: datetime_now},
	{id: 9, name: "Paga", created_at: datetime_now, updated_at: datetime_now},
	{id: 10, name: "Cancelada", created_at: datetime_now, updated_at: datetime_now},
]
OrderServiceStatus.upsert_all(array_OrderServiceStatus)

array_MaintenancePlan = [
	{name: "Garantia", created_at: datetime_now, updated_at: datetime_now},
	{name: "Preventiva", created_at: datetime_now, updated_at: datetime_now},
	{name: "Corretiva", created_at: datetime_now, updated_at: datetime_now},
]
MaintenancePlan.insert_all(array_MaintenancePlan)

array_OrderServiceType = [
	{name: "Cotações", created_at: datetime_now, updated_at: datetime_now},
	{name: "Emergencial", created_at: datetime_now, updated_at: datetime_now},
]
OrderServiceType.insert_all(array_OrderServiceType)

array_OrderServiceProposalStatus = [
	{name: "Em aberto", created_at: datetime_now, updated_at: datetime_now},
	{name: "Aguardando avaliação", created_at: datetime_now, updated_at: datetime_now},
	{name: "Aprovada", created_at: datetime_now, updated_at: datetime_now},
	{name: "Notas fiscais inseridas", created_at: datetime_now, updated_at: datetime_now},
	{name: "Autorizada", created_at: datetime_now, updated_at: datetime_now},
	{name: "Aguardando pagamento", created_at: datetime_now, updated_at: datetime_now},
	{name: "Paga", created_at: datetime_now, updated_at: datetime_now},
	{name: "Proposta reprovada", created_at: datetime_now, updated_at: datetime_now},
	{name: "Cancelada", created_at: datetime_now, updated_at: datetime_now},
]
OrderServiceProposalStatus.insert_all(array_OrderServiceProposalStatus)

array_OrderServiceInvoiceType = [
	{name: "Peças", created_at: datetime_now, updated_at: datetime_now},
	{name: "Serviços", created_at: datetime_now, updated_at: datetime_now},
]
OrderServiceInvoiceType.insert_all(array_OrderServiceInvoiceType)
