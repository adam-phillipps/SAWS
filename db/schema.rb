# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150415215031) do

  create_table "contracts", force: :cascade do |t|
    t.integer  "smash_client_id", limit: 4
    t.string   "name",            limit: 255
    t.string   "instance_id",     limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "instance_type",   limit: 255
  end

  add_index "contracts", ["instance_type"], name: "index_contracts_on_instance_type", using: :btree
  add_index "contracts", ["smash_client_id"], name: "index_contracts_on_smash_client_id", using: :btree

  create_table "smash_clients", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "user",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "password",               limit: 255
    t.string   "email",                  limit: 255
    t.string   "user_name",              limit: 255
  end

  add_index "users", ["name"], name: "index_users_on_name", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["user_name"], name: "index_users_on_user_name", unique: true, using: :btree

end
