module LoginMacros
  
  def login(user_email, user_pass)
    visit login_path
    fill_in 'email', with: user_email
    fill_in 'password', with: user_pass
    click_button "Entrar"
    sleep 1
  end

  def logout
    find("a[href='#{logout_path}']").click
    confirm
  end
  
end
