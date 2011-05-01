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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110501003825) do

  create_table "relays", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "url"
    t.integer  "dollarsraised_goal"
    t.integer  "participants_goal"
    t.integer  "teams_goal"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "relays", ["user_id"], :name => "index_relays_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
