require 'active_record'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = :info
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'data.db'
)

ActiveRecord::Schema.define do
  create_table :addresses, if_not_exists: true do |table|
    table.string :address
  end

  create_table :messages, if_not_exists: true do |table|
    table.string :cid
    table.string :from
    table.string :to
    table.integer :height
    table.string :method
    table.integer :nonce
    table.string :exit_code
    table.integer :timestamp
    table.string :value
  end

  create_table :blocks, if_not_exists: true do |table|
    table.string :address
    table.string :cid
    table.integer :height
    table.integer :message_count
    table.string :penalty
    table.string :reward
    table.integer :size
    table.integer :timestamp
    table.int :win_count
  end

  create_table :transfers, if_not_exists: true do |table|
    table.string :from
    table.integer :height
    table.integer :timestamp
    table.string :to
    table.string :type
    table.string :value
    table.string :cid
  end

  add_index :addresses, :address, unique: true
  add_index :messages, :cid, unique: true
  add_foreign_key :messages, :addresses, column: :from, primary_key: :address
  add_foreign_key :messages, :addresses, column: :to, primary_key: :address
  add_foreign_key :blocks, :addresses, column: :address, primary_key: :address
  add_foreign_key :transfers, :addresses, column: :from, primary_key: :address
  add_foreign_key :transfers, :addresses, column: :to, primary_key: :address
end

class Address < ActiveRecord::Base
  has_many :from_messages, class_name: :Message, foreign_key: :from, primary_key: :address
  has_many :to_messages, class_name: :Message, foreign_key: :to, primary_key: :address
  has_many :from_transfers, class_name: :Transfer, foreign_key: :from, primary_key: :address
  has_many :to_transfers, class_name: :Transfer, foreign_key: :to, primary_key: :address
  has_many :blocks, class_name: :Block, foreign_key: :address, primary_key: :address
end

class Message < ActiveRecord::Base
end
class Block < ActiveRecord::Base
end
class Transfer < ActiveRecord::Base
end
