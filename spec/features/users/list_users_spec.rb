require "rails_helper"

RSpec.feature "Users::List", type: :feature do
	context "Access" do
		scenario "Planner should not have access" do
			planner_profile = create(:profile, :planner)
			planner = create(:user, profile: planner_profile)

			login planner.cpf, planner.password
			visit admin_users_path
			expect(current_path).to eq(home_index_path)
		end

		scenario "Administrator should have access" do
			admin = create(:user)

			login admin.cpf, admin.password
			visit admin_users_path
			expect(current_path).to eq(admin_users_path)
		end
	end

	context 'Administrator access' do
		let(:admin) { create :user }

		before do
			login admin.cpf, admin.password
		end

		scenario "Default list" do
			create_list(:user, 2)
			visit admin_users_path

			expect(page).to have_content("Nome")
			expect(page).to have_content("Email")
			expect(page).to have_content("Perfil de usuário")
			expect(page).to have_content("Telefone")
			expect(page).to have_content("CPF")
			expect(page).to have_content("Endereço")
			expect(page).to have_link('Editar usuário')
			expect(page).to have_link('Excluir')
			expect(page).to have_link('Bloquear')
		end

		scenario "Delete", js: true do
			planner_profile = create(:profile, :planner)
			planner = create(:user, profile: planner_profile)
			visit admin_users_path

			find("a[href='#{admin_user_path(planner)}']").click
			confirm
			expect(page).to have_content("Usuário removido com sucesso!")
			expect(User.all.length).to eq(1)
		end

		scenario "Block", js: true do
			planner_profile = create(:profile, :planner)
			planner = create(:user, profile: planner_profile)
			visit admin_users_path

			find("a[href='#{block_admin_user_path(planner)}']").click
			confirm
			expect(page).to have_content("Usuário bloqueado com sucesso!")
			planner.reload
			expect(planner.is_blocked).to eq(true)
		end
	end
end