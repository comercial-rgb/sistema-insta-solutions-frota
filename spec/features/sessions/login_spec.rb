require "rails_helper"

feature "Login" do

  scenario 'invalid', js: true do
    login('111.111.111-11', 'aaaaaaa')
    expect(page).to have_content "Usuário não encontrado"
  end

  scenario "success admin" , js: true do
    adm = create(:user)
    login(adm.email, adm.password)
    expect(current_path).to eq users_path
    expect(page).to have_content "Bem vindo!"
  end

end
