module Api  
	module V1
		class Base < Grape::API
			
			mount Api::V1::Addresses
			mount Api::V1::Auth
			mount Api::V1::Banks
			mount Api::V1::CardBanners
			mount Api::V1::Cards
			mount Api::V1::Cep
			mount Api::V1::Cities
			mount Api::V1::CivilStates
			mount Api::V1::Countries
			mount Api::V1::PersonTypes
			mount Api::V1::Profiles
			mount Api::V1::States
			mount Api::V1::SystemConfigurations
			mount Api::V1::Users
			mount Api::V1::PhoneTypes
			mount Api::V1::Phones
			mount Api::V1::EmailTypes
			mount Api::V1::Emails
			mount Api::V1::DataBankTypes
			mount Api::V1::DataBanks
			mount Api::V1::AddressTypes
			mount Api::V1::Sexes
			mount Api::V1::PaymentTypes
			mount Api::V1::Plans
			mount Api::V1::Nascentes
			mount Api::V1::SiteContactSubjects
			mount Api::V1::SiteContacts

		end
	end
end  