feature "User - Create" do

    scenario "Success", js: true do
        user = build :user
        visit new_user_path

        select user.profile.name, :from => "user[profile_id]"

        fill_in "user[name]", with: user.name
        fill_in "user[email]", with: user.email
        fill_in "user[password]", with: user.password

        click_button "Salvar" 
        sleep 1 
        confirm

        expect(current_path).to eq new_visitors_user_path

        expect(User.all.length).to eq 2
        expect(User.last.name).to eq user.name
        expect(User.last.email).to eq user.email
    end

    scenario "invalid fields", js: true do
        visit new_visitors_user_path

        fill_in "user[name]", with: ''
        fill_in "user[email]", with: ''
        fill_in "user[phone]", with: ''
        fill_in "user[message]", with: ''

        click_button "Enviar"
        sleep 1

        expect(page).to have_content "Insira seu nome completo."
        expect(page).to have_content "Insira seu e-mail."
        expect(page).to have_content "Insira o telefone."
        expect(page).to have_content "Digite uma mensagem."
    end

end
