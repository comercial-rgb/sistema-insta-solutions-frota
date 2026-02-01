FactoryBot.define do
  factory :data_bank do
    ownertable { nil }
    bank { nil }
    data_bank_type { nil }
    agency { "MyString" }
    account { "MyString" }
    operation { "MyString" }
    cpf_cnpj { "MyString" }
    pix { "MyString" }
  end
end
