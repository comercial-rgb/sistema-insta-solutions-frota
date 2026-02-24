# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_02_24_150000) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.bigint "active_storage_blobs"
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addendum_commitments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "commitment_id", null: false
    t.string "number"
    t.text "description"
    t.decimal "total_value", precision: 15, scale: 2
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "contract_id"
    t.index ["commitment_id"], name: "index_addendum_commitments_on_commitment_id"
    t.index ["contract_id"], name: "index_addendum_commitments_on_contract_id"
  end

  create_table "addendum_contracts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "contract_id"
    t.string "name"
    t.string "number"
    t.decimal "total_value", precision: 15, scale: 2
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id"], name: "index_addendum_contracts_on_contract_id"
  end

  create_table "address_areas", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "address_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "addresses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "ownertable_type"
    t.bigint "ownertable_id"
    t.string "name"
    t.string "zipcode"
    t.string "address"
    t.string "district"
    t.string "number"
    t.string "complement"
    t.text "reference"
    t.string "latitude"
    t.string "longitude"
    t.bigint "address_area_id"
    t.bigint "address_type_id"
    t.bigint "state_id"
    t.bigint "city_id"
    t.bigint "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_area_id"], name: "index_addresses_on_address_area_id"
    t.index ["address_type_id"], name: "index_addresses_on_address_type_id"
    t.index ["city_id"], name: "index_addresses_on_city_id"
    t.index ["country_id"], name: "index_addresses_on_country_id"
    t.index ["ownertable_type", "ownertable_id"], name: "index_addresses_on_ownertable"
    t.index ["state_id"], name: "index_addresses_on_state_id"
  end

  create_table "attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "ownertable_type"
    t.bigint "ownertable_id"
    t.integer "attachment_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.index ["category"], name: "index_attachments_on_category"
    t.index ["ownertable_type", "ownertable_id"], name: "index_attachments_on_ownertable"
  end

  create_table "audits", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_id", "associated_type"], name: "associated_index"
    t.index ["auditable_id", "auditable_type"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "banks", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "number"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "budget_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cancel_commitments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "commitment_id"
    t.decimal "value", precision: 15, scale: 2
    t.string "number"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commitment_id"], name: "index_cancel_commitments_on_commitment_id"
  end

  create_table "catalogo_pdf_imports", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "filename", null: false
    t.string "fornecedor", limit: 50, null: false
    t.string "checksum", limit: 64
    t.integer "total_registros", default: 0
    t.integer "total_paginas", default: 0
    t.string "status", limit: 20, default: "pendente"
    t.text "log"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["filename"], name: "index_catalogo_pdf_imports_on_filename", unique: true
    t.index ["fornecedor"], name: "index_catalogo_pdf_imports_on_fornecedor"
  end

  create_table "catalogo_pecas", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "fornecedor", limit: 50, null: false
    t.string "marca", limit: 100, default: ""
    t.string "veiculo", limit: 150, default: ""
    t.string "modelo", limit: 150, default: ""
    t.string "motor", limit: 100, default: ""
    t.integer "ano_inicio"
    t.integer "ano_fim"
    t.string "grupo_produto", limit: 200, default: ""
    t.string "produto", limit: 150, default: ""
    t.string "observacao", limit: 300, default: ""
    t.integer "pagina_origem"
    t.string "arquivo_origem"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fornecedor", "marca", "veiculo", "modelo", "produto"], name: "idx_catalogo_unique_entry", length: { marca: 50, veiculo: 50, modelo: 50, produto: 80 }
    t.index ["fornecedor"], name: "idx_catalogo_fornecedor"
    t.index ["fornecedor"], name: "index_catalogo_pecas_on_fornecedor"
    t.index ["grupo_produto"], name: "index_catalogo_pecas_on_grupo_produto", length: 100
    t.index ["marca"], name: "idx_catalogo_marca"
    t.index ["marca"], name: "index_catalogo_pecas_on_marca"
    t.index ["produto"], name: "idx_catalogo_produto"
    t.index ["produto"], name: "index_catalogo_pecas_on_produto"
    t.index ["veiculo", "modelo"], name: "idx_catalogo_veiculo"
    t.index ["veiculo", "modelo"], name: "idx_catalogo_veiculo_modelo"
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "category_type_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_type_id"], name: "index_categories_on_category_type_id"
  end

  create_table "category_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cities", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "latitude"
    t.string "longitude"
    t.string "ibge_code"
    t.decimal "quantity_population", precision: 10
    t.bigint "state_id"
    t.bigint "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_cities_on_country_id"
    t.index ["state_id"], name: "index_cities_on_state_id"
  end

  create_table "ckeditor_assets", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "data_file_name", null: false
    t.string "data_content_type"
    t.integer "data_file_size"
    t.string "data_fingerprint"
    t.string "type", limit: 30
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type"], name: "index_ckeditor_assets_on_type"
  end

  create_table "commitment_cost_centers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "commitment_id", null: false
    t.bigint "cost_center_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["commitment_id", "cost_center_id"], name: "index_commitment_cost_centers_unique", unique: true
    t.index ["commitment_id"], name: "index_commitment_cost_centers_on_commitment_id"
    t.index ["cost_center_id"], name: "index_commitment_cost_centers_on_cost_center_id"
  end

  create_table "commitments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "cost_center_id"
    t.bigint "contract_id"
    t.string "commitment_number"
    t.decimal "commitment_value", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "canceled_value", precision: 15, scale: 2
    t.bigint "sub_unit_id"
    t.boolean "active", default: true, null: false
    t.bigint "category_id"
    t.index ["category_id"], name: "index_commitments_on_category_id"
    t.index ["client_id"], name: "index_commitments_on_client_id"
    t.index ["contract_id"], name: "index_commitments_on_contract_id"
    t.index ["cost_center_id"], name: "index_commitments_on_cost_center_id"
    t.index ["sub_unit_id"], name: "index_commitments_on_sub_unit_id"
  end

  create_table "contracts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name"
    t.string "initial_date"
    t.string "number"
    t.decimal "total_value", precision: 15, scale: 2
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "final_date"
    t.index ["client_id"], name: "index_contracts_on_client_id"
  end

  create_table "contracts_cost_centers", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "contract_id", null: false
    t.bigint "cost_center_id", null: false
  end

  create_table "cost_centers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name"
    t.string "contract_number"
    t.string "commitment_number"
    t.decimal "initial_consumed_balance", precision: 15, scale: 2
    t.text "description"
    t.decimal "budget_value", precision: 15, scale: 2
    t.bigint "budget_type_id"
    t.date "contract_initial_date"
    t.boolean "has_sub_units"
    t.string "invoice_name"
    t.string "invoice_cnpj"
    t.text "invoice_address"
    t.bigint "invoice_state_id"
    t.string "invoice_fantasy_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_type_id"], name: "index_cost_centers_on_budget_type_id"
    t.index ["client_id"], name: "index_cost_centers_on_client_id"
    t.index ["invoice_state_id"], name: "index_cost_centers_on_invoice_state_id"
  end

  create_table "cost_centers_users", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "cost_center_id", null: false
    t.bigint "user_id", null: false
  end

  create_table "countries", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "data_bank_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "data_banks", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "ownertable_type"
    t.bigint "ownertable_id"
    t.bigint "bank_id"
    t.bigint "data_bank_type_id"
    t.string "agency"
    t.string "account"
    t.string "operation"
    t.string "cpf_cnpj"
    t.string "pix"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_id"], name: "index_data_banks_on_bank_id"
    t.index ["data_bank_type_id"], name: "index_data_banks_on_data_bank_type_id"
    t.index ["ownertable_type", "ownertable_id"], name: "index_data_banks_on_ownertable"
  end

  create_table "fuel_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "maintenance_plans", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notifications", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "profile_id"
    t.boolean "send_all", default: true
    t.string "title"
    t.text "message", size: :long
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_notifications_on_profile_id"
  end

  create_table "notifications_users", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "notification_id", null: false
    t.bigint "user_id", null: false
  end

  create_table "order_service_directed_providers", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "order_service_id", null: false
    t.bigint "provider_id", null: false
    t.index ["order_service_id", "provider_id"], name: "idx_os_directed_providers_unique", unique: true
    t.index ["provider_id"], name: "idx_os_directed_providers_provider"
  end

  create_table "order_service_invoice_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_service_invoices", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "order_service_proposal_id"
    t.bigint "order_service_invoice_type_id"
    t.string "number"
    t.decimal "value", precision: 15, scale: 2
    t.date "emission_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_service_invoice_type_id"], name: "index_order_service_invoices_on_order_service_invoice_type_id"
    t.index ["order_service_proposal_id"], name: "index_order_service_invoices_on_order_service_proposal_id"
  end

  create_table "order_service_proposal_items", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "order_service_proposal_id"
    t.bigint "service_id"
    t.integer "quantity"
    t.decimal "discount", precision: 15, scale: 2
    t.decimal "total_value", precision: 15, scale: 2
    t.decimal "unity_value", precision: 15, scale: 2
    t.decimal "total_value_without_discount", precision: 15, scale: 2
    t.string "service_name"
    t.text "service_description"
    t.string "brand"
    t.integer "warranty_period"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "observation"
    t.string "guarantee"
    t.date "warranty_start_date"
    t.boolean "is_complement", default: false
    t.string "referencia_catalogo", limit: 500
    t.index ["order_service_proposal_id"], name: "idx_on_order_service_proposal_id_fc807812fe"
    t.index ["service_id"], name: "index_order_service_proposal_items_on_service_id"
  end

  create_table "order_service_proposal_statuses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_service_proposals", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "order_service_id"
    t.bigint "provider_id"
    t.bigint "order_service_proposal_status_id"
    t.text "details", size: :long
    t.decimal "total_value", precision: 15, scale: 2
    t.decimal "total_discount", precision: 15, scale: 2
    t.decimal "total_value_without_discount", precision: 15, scale: 2
    t.string "code"
    t.boolean "reproved", default: false
    t.text "reason_reproved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "reason_approved"
    t.bigint "approved_by_additional_id"
    t.bigint "authorized_by_additional_id"
    t.datetime "approved_by_additional_at"
    t.datetime "authorized_by_additional_at"
    t.boolean "pending_manager_approval", default: false
    t.boolean "pending_manager_authorization", default: false
    t.boolean "is_complement", default: false
    t.text "justification"
    t.text "reason_refused_approval"
    t.integer "parent_proposal_id"
    t.index ["approved_by_additional_id"], name: "index_order_service_proposals_on_approved_by_additional_id"
    t.index ["authorized_by_additional_id"], name: "index_order_service_proposals_on_authorized_by_additional_id"
    t.index ["order_service_id"], name: "index_order_service_proposals_on_order_service_id"
    t.index ["order_service_proposal_status_id"], name: "idx_on_order_service_proposal_status_id_a50919f65f"
    t.index ["pending_manager_approval"], name: "index_order_service_proposals_on_pending_manager_approval"
    t.index ["pending_manager_authorization"], name: "index_order_service_proposals_on_pending_manager_authorization"
    t.index ["provider_id"], name: "index_order_service_proposals_on_provider_id"
  end

  create_table "order_service_statuses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_service_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_services", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "order_service_status_id"
    t.bigint "client_id"
    t.bigint "manager_id"
    t.bigint "vehicle_id"
    t.bigint "provider_service_type_id"
    t.bigint "maintenance_plan_id"
    t.bigint "order_service_type_id"
    t.bigint "provider_id"
    t.string "code"
    t.integer "km"
    t.string "driver"
    t.text "details", size: :long
    t.text "cancel_justification", size: :long
    t.text "invoice_information", size: :long
    t.decimal "invoice_part_ir", precision: 15, scale: 2, default: "1.2"
    t.decimal "invoice_part_pis", precision: 15, scale: 2, default: "0.65"
    t.decimal "invoice_part_cofins", precision: 15, scale: 2, default: "3.0"
    t.decimal "invoice_part_csll", precision: 15, scale: 2, default: "1.0"
    t.decimal "invoice_service_ir", precision: 15, scale: 2, default: "4.8"
    t.decimal "invoice_service_pis", precision: 15, scale: 2, default: "0.65"
    t.decimal "invoice_service_cofins", precision: 15, scale: 2, default: "3.0"
    t.decimal "invoice_service_csll", precision: 15, scale: 2, default: "1.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "commitment_id"
    t.boolean "data_inserted_by_provider", default: false
    t.boolean "release_quotation", default: false
    t.boolean "parts_services_added", default: false
    t.bigint "commitment_parts_id"
    t.bigint "commitment_services_id"
    t.bigint "service_group_id"
    t.string "origin"
    t.boolean "directed_to_specific_providers", default: false
    t.index ["client_id"], name: "index_order_services_on_client_id"
    t.index ["commitment_id"], name: "index_order_services_on_commitment_id"
    t.index ["commitment_parts_id"], name: "fk_rails_8411f8cafd"
    t.index ["commitment_services_id"], name: "fk_rails_c723b846de"
    t.index ["maintenance_plan_id"], name: "index_order_services_on_maintenance_plan_id"
    t.index ["manager_id"], name: "index_order_services_on_manager_id"
    t.index ["order_service_status_id"], name: "index_order_services_on_order_service_status_id"
    t.index ["order_service_type_id"], name: "index_order_services_on_order_service_type_id"
    t.index ["provider_id"], name: "index_order_services_on_provider_id"
    t.index ["provider_service_type_id"], name: "index_order_services_on_provider_service_type_id"
    t.index ["vehicle_id"], name: "index_order_services_on_vehicle_id"
  end

  create_table "orientation_manuals", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "orientation_manuals_profiles", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "orientation_manual_id", null: false
    t.bigint "profile_id", null: false
  end

  create_table "part_service_order_services", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "order_service_id"
    t.bigint "service_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "observation"
    t.integer "quantity", default: 1
    t.index ["order_service_id"], name: "index_part_service_order_services_on_order_service_id"
    t.index ["service_id"], name: "index_part_service_order_services_on_service_id"
  end

  create_table "person_contacts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "ownertable_type"
    t.bigint "ownertable_id"
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "office"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ownertable_type", "ownertable_id"], name: "index_person_contacts_on_ownertable"
  end

  create_table "person_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "profiles", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "provider_service_temps", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "order_service_proposal_id"
    t.string "name"
    t.string "code"
    t.decimal "price", precision: 15, scale: 2
    t.bigint "category_id"
    t.text "description"
    t.integer "quantity"
    t.decimal "discount", precision: 15, scale: 2
    t.decimal "total_value", precision: 15, scale: 2
    t.string "brand"
    t.integer "warranty_period"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "service_id"
    t.string "referencia_catalogo", limit: 500
    t.index ["category_id"], name: "index_provider_service_temps_on_category_id"
    t.index ["order_service_proposal_id"], name: "index_provider_service_temps_on_order_service_proposal_id"
    t.index ["service_id"], name: "index_provider_service_temps_on_service_id"
  end

  create_table "provider_service_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "provider_service_types_users", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "provider_service_type_id", null: false
    t.bigint "user_id", null: false
  end

  create_table "read_marks", charset: "latin1", force: :cascade do |t|
    t.string "readable_type", null: false
    t.bigint "readable_id"
    t.string "reader_type", null: false
    t.bigint "reader_id"
    t.datetime "timestamp", precision: nil, null: false
    t.index ["readable_type", "readable_id"], name: "index_read_marks_on_readable_type_and_readable_id"
    t.index ["reader_id", "reader_type", "readable_type", "readable_id"], name: "read_marks_reader_readable_index", unique: true
    t.index ["reader_type", "reader_id"], name: "index_read_marks_on_reader_type_and_reader_id"
  end

  create_table "reference_prices", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "vehicle_model_id", null: false
    t.bigint "service_id", null: false
    t.decimal "reference_price", precision: 15, scale: 2, null: false
    t.decimal "max_percentage", precision: 5, scale: 2, default: "110.0"
    t.text "observation"
    t.string "source"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_reference_prices_on_active"
    t.index ["service_id"], name: "index_reference_prices_on_service_id"
    t.index ["vehicle_model_id", "service_id"], name: "index_reference_prices_on_model_and_service", unique: true
    t.index ["vehicle_model_id"], name: "index_reference_prices_on_vehicle_model_id"
  end

  create_table "rejected_order_services_providers", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "order_service_id"
    t.bigint "provider_id"
    t.index ["order_service_id"], name: "index_rejected_order_services_providers_on_order_service_id"
    t.index ["provider_id"], name: "index_rejected_order_services_providers_on_provider_id"
  end

  create_table "service_group_clients", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "service_group_id", null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_service_group_clients_on_client_id"
    t.index ["service_group_id", "client_id"], name: "index_sg_clients_unique", unique: true
    t.index ["service_group_id"], name: "index_service_group_clients_on_service_group_id"
  end

  create_table "service_group_items", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "service_group_id", null: false
    t.bigint "service_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "0.0"
    t.decimal "max_value", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_group_id", "service_id"], name: "index_service_group_items_unique", unique: true
    t.index ["service_group_id"], name: "index_service_group_items_on_service_group_id"
    t.index ["service_id"], name: "index_service_group_items_on_service_id"
  end

  create_table "service_groups", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_service_groups_on_active"
  end

  create_table "services", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "provider_id"
    t.string "name"
    t.string "code"
    t.decimal "price", precision: 15, scale: 2
    t.bigint "category_id"
    t.text "description"
    t.string "brand"
    t.integer "warranty_period"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_services_on_category_id"
    t.index ["provider_id"], name: "index_services_on_provider_id"
  end

  create_table "sexes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "site_contact_subjects", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "site_contacts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "site_contact_subject_id"
    t.string "name"
    t.string "email"
    t.string "phone"
    t.text "message", size: :long
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_contact_subject_id"], name: "index_site_contacts_on_site_contact_subject_id"
    t.index ["user_id"], name: "index_site_contacts_on_user_id"
  end

  create_table "states", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "acronym"
    t.string "ibge_code"
    t.bigint "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_states_on_country_id"
  end

  create_table "states_users", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "state_id", null: false
  end

  create_table "sub_categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_sub_categories_on_category_id"
  end

  create_table "sub_units", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "cost_center_id"
    t.string "name"
    t.string "contract_number"
    t.string "commitment_number"
    t.decimal "initial_consumed_balance", precision: 15, scale: 2
    t.decimal "budget_value", precision: 15, scale: 2
    t.bigint "budget_type_id"
    t.date "contract_initial_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_type_id"], name: "index_sub_units_on_budget_type_id"
    t.index ["cost_center_id"], name: "index_sub_units_on_cost_center_id"
  end

  create_table "sub_units_users", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "sub_unit_id", null: false
    t.bigint "user_id", null: false
  end

  create_table "system_configurations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "notification_mail"
    t.string "contact_mail"
    t.text "use_policy", size: :long
    t.text "exchange_policy", size: :long
    t.text "warranty_policy", size: :long
    t.text "privacy_policy", size: :long
    t.string "phone"
    t.string "cellphone"
    t.string "cnpj"
    t.text "data_security_policy", size: :long
    t.text "quality", size: :long
    t.text "about", size: :long
    t.text "mission", size: :long
    t.text "view", size: :long
    t.text "values", size: :long
    t.string "site_link"
    t.string "facebook_link"
    t.string "instagram_link"
    t.string "twitter_link"
    t.string "youtube_link"
    t.string "id_google_analytics"
    t.string "page_title"
    t.string "page_description"
    t.integer "pix_limit_payment_minutes"
    t.text "geral_conditions", size: :long
    t.text "contract_data", size: :long
    t.text "attendance_data", size: :long
    t.string "about_video_link"
    t.text "notification_new_users"
    t.text "notification_validation_users"
    t.text "about_product", size: :long
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_statuses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "access_user"
    t.string "password_digest"
    t.string "recovery_token"
    t.string "validate_mail_token"
    t.boolean "is_blocked", default: false
    t.boolean "external_register", default: false
    t.bigint "profile_id"
    t.string "phone"
    t.string "cpf"
    t.string "rg"
    t.date "birthday"
    t.bigint "person_type_id"
    t.bigint "sex_id"
    t.bigint "user_status_id"
    t.string "social_name"
    t.string "fantasy_name"
    t.string "cnpj"
    t.boolean "accept_therm", default: false
    t.boolean "validated_mail", default: false
    t.string "cellphone"
    t.string "profession"
    t.string "municipal_inscription"
    t.string "state_inscription"
    t.decimal "discount_percent", precision: 15, scale: 2
    t.string "department"
    t.bigint "state_id"
    t.bigint "city_id"
    t.bigint "client_id"
    t.string "provider", limit: 50, default: "", null: false
    t.string "uid", limit: 500, default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "registration"
    t.boolean "optante_simples", default: false
    t.boolean "needs_km", default: false
    t.boolean "require_vehicle_photos", default: false, null: false
    t.index ["city_id"], name: "index_users_on_city_id"
    t.index ["client_id"], name: "index_users_on_client_id"
    t.index ["person_type_id"], name: "index_users_on_person_type_id"
    t.index ["profile_id"], name: "index_users_on_profile_id"
    t.index ["sex_id"], name: "index_users_on_sex_id"
    t.index ["state_id"], name: "index_users_on_state_id"
    t.index ["user_status_id"], name: "index_users_on_user_status_id"
  end

  create_table "vehicle_models", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "vehicle_type_id"
    t.string "brand", null: false
    t.string "model", null: false
    t.string "version"
    t.string "full_name"
    t.text "aliases"
    t.string "code_cilia"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_vehicle_models_on_active"
    t.index ["brand"], name: "index_vehicle_models_on_brand"
    t.index ["code_cilia"], name: "index_vehicle_models_on_code_cilia"
    t.index ["model"], name: "index_vehicle_models_on_model"
    t.index ["vehicle_type_id"], name: "index_vehicle_models_on_vehicle_type_id"
  end

  create_table "vehicle_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vehicles", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "cost_center_id"
    t.bigint "sub_unit_id"
    t.string "board"
    t.string "brand"
    t.string "model"
    t.string "year"
    t.string "color"
    t.string "renavam"
    t.string "chassi"
    t.decimal "market_value", precision: 15, scale: 2
    t.date "acquisition_date"
    t.bigint "vehicle_type_id"
    t.bigint "category_id"
    t.bigint "state_id"
    t.bigint "city_id"
    t.bigint "fuel_type_id"
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "model_year"
    t.string "current_owner_name"
    t.string "old_owner_name"
    t.string "current_owner_document"
    t.string "engine_displacement"
    t.string "gearbox_type"
    t.string "fipe_code"
    t.string "model_text"
    t.string "value_text"
    t.index ["category_id"], name: "index_vehicles_on_category_id"
    t.index ["city_id"], name: "index_vehicles_on_city_id"
    t.index ["client_id"], name: "index_vehicles_on_client_id"
    t.index ["cost_center_id"], name: "index_vehicles_on_cost_center_id"
    t.index ["fuel_type_id"], name: "index_vehicles_on_fuel_type_id"
    t.index ["state_id"], name: "index_vehicles_on_state_id"
    t.index ["sub_unit_id"], name: "index_vehicles_on_sub_unit_id"
    t.index ["vehicle_type_id"], name: "index_vehicles_on_vehicle_type_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addendum_commitments", "commitments"
  add_foreign_key "addendum_commitments", "contracts"
  add_foreign_key "addendum_contracts", "contracts"
  add_foreign_key "addresses", "address_areas"
  add_foreign_key "addresses", "address_types"
  add_foreign_key "addresses", "cities"
  add_foreign_key "addresses", "countries"
  add_foreign_key "addresses", "states"
  add_foreign_key "cancel_commitments", "commitments"
  add_foreign_key "categories", "category_types"
  add_foreign_key "cities", "countries"
  add_foreign_key "cities", "states"
  add_foreign_key "commitment_cost_centers", "commitments", name: "commitment_cost_centers_ibfk_1"
  add_foreign_key "commitment_cost_centers", "cost_centers", name: "commitment_cost_centers_ibfk_2"
  add_foreign_key "commitments", "categories"
  add_foreign_key "commitments", "contracts"
  add_foreign_key "commitments", "cost_centers"
  add_foreign_key "commitments", "sub_units"
  add_foreign_key "commitments", "users", column: "client_id"
  add_foreign_key "contracts", "users", column: "client_id"
  add_foreign_key "cost_centers", "budget_types"
  add_foreign_key "cost_centers", "states", column: "invoice_state_id"
  add_foreign_key "cost_centers", "users", column: "client_id"
  add_foreign_key "data_banks", "banks"
  add_foreign_key "data_banks", "data_bank_types"
  add_foreign_key "notifications", "profiles"
  add_foreign_key "order_service_directed_providers", "order_services"
  add_foreign_key "order_service_directed_providers", "users", column: "provider_id"
  add_foreign_key "order_service_invoices", "order_service_invoice_types"
  add_foreign_key "order_service_invoices", "order_service_proposals"
  add_foreign_key "order_service_proposal_items", "order_service_proposals"
  add_foreign_key "order_service_proposal_items", "services"
  add_foreign_key "order_service_proposals", "order_service_proposal_statuses"
  add_foreign_key "order_service_proposals", "order_services"
  add_foreign_key "order_service_proposals", "users", column: "approved_by_additional_id"
  add_foreign_key "order_service_proposals", "users", column: "authorized_by_additional_id"
  add_foreign_key "order_service_proposals", "users", column: "provider_id"
  add_foreign_key "order_services", "commitments"
  add_foreign_key "order_services", "commitments", column: "commitment_parts_id"
  add_foreign_key "order_services", "commitments", column: "commitment_services_id"
  add_foreign_key "order_services", "maintenance_plans"
  add_foreign_key "order_services", "order_service_statuses"
  add_foreign_key "order_services", "order_service_types"
  add_foreign_key "order_services", "provider_service_types"
  add_foreign_key "order_services", "users", column: "client_id"
  add_foreign_key "order_services", "users", column: "manager_id"
  add_foreign_key "order_services", "users", column: "provider_id"
  add_foreign_key "order_services", "vehicles"
  add_foreign_key "part_service_order_services", "order_services"
  add_foreign_key "part_service_order_services", "services"
  add_foreign_key "provider_service_temps", "categories"
  add_foreign_key "provider_service_temps", "order_service_proposals"
  add_foreign_key "provider_service_temps", "services"
  add_foreign_key "reference_prices", "services", name: "fk_rails_reference_prices_services"
  add_foreign_key "reference_prices", "vehicle_models", name: "fk_rails_reference_prices_vehicle_models"
  add_foreign_key "rejected_order_services_providers", "order_services"
  add_foreign_key "rejected_order_services_providers", "users", column: "provider_id"
  add_foreign_key "service_group_items", "service_groups"
  add_foreign_key "service_group_items", "services"
  add_foreign_key "services", "categories"
  add_foreign_key "services", "users", column: "provider_id"
  add_foreign_key "site_contacts", "site_contact_subjects"
  add_foreign_key "site_contacts", "users"
  add_foreign_key "states", "countries"
  add_foreign_key "sub_categories", "categories"
  add_foreign_key "sub_units", "budget_types"
  add_foreign_key "sub_units", "cost_centers"
  add_foreign_key "users", "cities"
  add_foreign_key "users", "person_types"
  add_foreign_key "users", "profiles"
  add_foreign_key "users", "sexes"
  add_foreign_key "users", "states"
  add_foreign_key "users", "user_statuses"
  add_foreign_key "users", "users", column: "client_id"
  add_foreign_key "vehicle_models", "vehicle_types", name: "fk_rails_vehicle_models_vehicle_types"
  add_foreign_key "vehicles", "categories"
  add_foreign_key "vehicles", "cities"
  add_foreign_key "vehicles", "cost_centers"
  add_foreign_key "vehicles", "fuel_types"
  add_foreign_key "vehicles", "states"
  add_foreign_key "vehicles", "sub_units"
  add_foreign_key "vehicles", "users", column: "client_id"
  add_foreign_key "vehicles", "vehicle_types"
end
