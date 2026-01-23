require "rails_helper"

RSpec.feature "Users::Edit", type: :feature do

	context 'Planner' do
		let(:planner) { create :user, :planner }

		before do
			login planner.cpf, planner.password
		end

		scenario "should not have access to another user profile" do
			other_planner = create(:user, :planner)

			visit edit_admin_user_path other_planner
			expect(current_path).to eq(home_index_path)
		end

		scenario "should have access to his own profile" do
			visit edit_admin_user_path planner
			expect(current_path).to eq(edit_admin_user_path planner)
		end

		scenario "should not see Profile field" do
			
			visit edit_admin_user_path planner
			expect(page).not_to have_field("user_profile_id", :type => 'select')
			expect(current_path).to eq(edit_admin_user_path planner)
		end

		scenario "invalid", js: true do
			visit edit_admin_user_path planner
			fill_in "user[cpf]", with: "111.111.111-11"
			click_button "Salvar"

			expect(page).to have_content("CPF Inválido")

			fill_in "user[cpf]", with: planner.cpf

			fill_in "user[name]", with: ""
			fill_in "user[email]", with: ""
			fill_in "user[password]", with: ""
			fill_in "user[phone]", with: ""
			fill_in "user[address_attributes][zipcode]", with: ""
			fill_in "user[address_attributes][number]", with: ""
			fill_in "user[address_attributes][complement]", with: ""

			click_button "Salvar"

			expect(page).to have_content("Nome não pode ficar em branco")
			expect(page).not_to have_content("Perfil de usuário não pode ficar em branco")
			expect(page).to have_content("Email não pode ficar em branco")
			expect(page).not_to have_content("Senha não pode ficar em branco")
			expect(page).to have_content("Telefone não pode ficar em branco")
			expect(page).to have_content("Endereço não pode ficar em branco")
			expect(page).to have_content("Bairro não pode ficar em branco")
			expect(page).to have_content("Número não pode ficar em branco")
			expect(page).to have_content("Estado não pode ficar em branco")
			expect(page).to have_content("Cidade não pode ficar em branco")
		end

		scenario "success", js: true do
			create :profile
			create :profile, :planner
			state = create(:state, acronym: "MG")
			city = create(:city, name: "Belo Horizonte", state: state)
			new_user = build :user

			visit edit_admin_user_path planner

			fill_in "user[name]", with: new_user.name
			fill_in "user[email]", with: new_user.email
			fill_in "user[password]", with: new_user.password
			fill_in "user[phone]", with: '(31) 99999-9999'
			fill_in "user[cpf]", with: new_user.cpf
			
			page.execute_script %{ $("#user_address_attributes_zipcode").val("30.575-740"); }
			page.execute_script %{ $("#user_address_attributes_zipcode").blur(); }
			sleep 3
			fill_in "user[address_attributes][number]", with: "100"
			fill_in "user[address_attributes][complement]", with: "bloco 3 apto 602"
			click_button "Salvar"
			sleep 1

			expect(page).to have_content("Usuário atualizado com sucesso!")
			expect(current_path).to eq(home_index_path)
			expect(User.last.name).to eq(new_user.name)
			expect(User.last.email).to eq(new_user.email)
			expect(User.last.phone).to eq('(31) 99999-9999')
			expect(User.last.cpf).to eq(new_user.cpf)
			expect(User.last.address.zipcode).to eq("30.575-740")
			expect(User.last.address.address).to eq("Rua Eli Seabra Filho")
			expect(User.last.address.district).to eq("Buritis")
			expect(User.last.address.number).to eq("100")
			expect(User.last.address.complement).to eq("bloco 3 apto 602")
			expect(User.last.address.state_id).to eq(state.id)
			expect(User.last.address.city_id).to eq(city.id)
		end
	end

	context 'Administrador' do
		let(:admin) { create :user }
		let(:other_user) { create :user }

		before do
			login admin.cpf, admin.password
		end

		scenario "should have access to other user profile" do
			visit edit_admin_user_path other_user
			expect(current_path).to eq(edit_admin_user_path other_user)
		end

		scenario "invalid", js: true do
			visit edit_admin_user_path other_user

			fill_in "user[cpf]", with: "111.111.111-11"
			click_button "Salvar"
			expect(page).to have_content("CPF Inválido")

			fill_in "user[cpf]", with: other_user.cpf

			fill_in "user[name]", with: ""
			fill_in "user[email]", with: ""
			fill_in "user[password]", with: ""
			fill_in "user[phone]", with: ""
			fill_in "user[address_attributes][zipcode]", with: ""
			fill_in "user[address_attributes][number]", with: ""
			fill_in "user[address_attributes][complement]", with: ""

			click_button "Salvar"

			expect(page).to have_content("Nome não pode ficar em branco")
			expect(page).to have_content("Email não pode ficar em branco")
			expect(page).not_to have_content("Senha não pode ficar em branco")
			expect(page).to have_content("Telefone não pode ficar em branco")
			expect(page).to have_content("Endereço não pode ficar em branco")
			expect(page).to have_content("Bairro não pode ficar em branco")
			expect(page).to have_content("Número não pode ficar em branco")
			expect(page).to have_content("Estado não pode ficar em branco")
			expect(page).to have_content("Cidade não pode ficar em branco")
		end

		scenario "success", js: true do
			
			create :profile, :planner
			state = create(:state, acronym: "MG")
			city = create(:city, name: "Belo Horizonte", state: state)
			new_user = build(:user, profile_id: 1)

			visit edit_admin_user_path other_user

			fill_in "user[name]", with: new_user.name
			fill_in "user[email]", with: new_user.email
			fill_in "user[password]", with: new_user.password
			fill_in "user[phone]", with: '(31) 99999-9999'
			fill_in "user[cpf]", with: new_user.cpf
			
			page.execute_script %{ $("#user_address_attributes_zipcode").val("30.575-740"); }
			page.execute_script %{ $("#user_address_attributes_zipcode").blur(); }
			sleep 3
			fill_in "user[address_attributes][number]", with: "100"
			fill_in "user[address_attributes][complement]", with: "bloco 3 apto 602"
			click_button "Salvar"
			sleep 1
			other_user.reload

			expect(page).to have_content("Usuário atualizado com sucesso!")
			expect(current_path).to eq(admin_users_path)
			expect(other_user.name).to eq(new_user.name)
			expect(other_user.profile_id).to eq(other_user.profile.id)
			expect(other_user.email).to eq(new_user.email)
			expect(other_user.phone).to eq('(31) 99999-9999')
			expect(other_user.cpf).to eq(new_user.cpf)
			expect(other_user.address.zipcode).to eq("30.575-740")
			expect(other_user.address.address).to eq("Rua Eli Seabra Filho")
			expect(other_user.address.district).to eq("Buritis")
			expect(other_user.address.number).to eq("100")
			expect(other_user.address.complement).to eq("bloco 3 apto 602")
			expect(other_user.address.state_id).to eq(state.id)
			expect(other_user.address.city_id).to eq(city.id)
		end
	end
end