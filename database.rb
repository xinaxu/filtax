require 'active_record'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = :info
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'data.db'
)

ActiveRecord::Schema.define do
  break if table_exists? :messages
  create_table :messages, if_not_exists: true do |table|
    table.integer :height
    table.string :cid
    table.string :from
    table.string :to
    table.string :method
    table.string :value
    table.string :nonce
  end

  create_table :blocks, if_not_exists: true do |table|
    table.integer :height
    table.string :cid
    table.string :miner
    table.string :reward
  end

  create_table :transfers, if_not_exists: true do |table|
    table.integer :height
    table.string :message_cid
    table.string :from
    table.string :to
    table.string :type
    table.string :value
  end

  add_index :messages, :cid, unique: true
  add_index :blocks, :cid, unique: true
  add_index :transfers, :height, unique: true
end

class Message < ActiveRecord::Base
end
class Block < ActiveRecord::Base
end
class Transfer < ActiveRecord::Base
end
