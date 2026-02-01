require "rails_helper"

feature "Recover Pass" do

  before do
    visit login_path
    click_link ('Esqueci minha senha')
  end

  scenario 'invalid email', js: true do
    fill_in 'email', with: 'email@email.com'
    click_button "Enviar"
    expect(page).to have_content "Email inexistente"
  end

  scenario "success send mail" , js: true do
    user = create(:user)
    fill_in 'email', with: user.email
    click_button "Enviar"
    expect(open_last_email).to be_delivered_to user.email
    expect(current_path).to eq login_path
    expect(page).to have_content "Um link para recuperação de senha foi enviado para o email cadastrado"
    expect(open_last_email).to be_delivered_to user.email
  end

  scenario "success recover" , js: true do
    user = create(:user, :recovery_token => SecureRandom.urlsafe_base64)
    visit edit_pass_token_path user.recovery_token
    fill_in 'user[password]', with: 'new_password'
    fill_in 'user[password_confirmation]', with: 'new_password'
    click_button 'Alterar senha'
    expect(page).to have_content "Sua senha foi redefinida"
    expect(current_path).to eq admin_users_path
  end

  scenario "invalid password confirmation recover" , js: true do
    user = create(:user, :recovery_token => SecureRandom.urlsafe_base64)
    visit edit_pass_token_path user.recovery_token
    fill_in 'user[password]', with: 'new_password'
    fill_in 'user[password_confirmation]', with: 'new_password_1'
    click_button 'Alterar senha'
    expect(page).to have_content "Confirmação de senha não é igual a Senha"
    expect(current_path).to eq edit_pass_token_path(:recovery_token => user.recovery_token)
  end

end
