#!/usr/bin/ruby
require_relative 'filfox'
require_relative 'database'
require_relative 'util'
require 'slop'
require 'csv'

opts = Slop::Options.new
opts.banner = "Usage: ./filtax.rb [options]"
opts.array '-a', '--address', 'Wallet or miner addresses'
opts.string '-f', '--file', 'A file listing all addresses on each line'
opts.string '-o', '--output-prefix', 'The prefix of the output file, by default "output"'
opts.on '-h', '--help', 'print help' do
  puts opts
  exit
end
parser = Slop::Parser.new(opts)
begin
  @options = parser.parse(ARGV)
rescue
  puts opts
  exit
end

def update_address(address)
=begin
  max_height = Message.where(['"from" = ? or "to" = ?', address, address]).maximum(:height) || 0
  FilFox.get_messages(address, max_height).each do |message|
    Message.create_with(
      height: message['height'], 
      cid: message['cid'],
      from: message['from'],
      to: message['to'],
      method: message['method'],
      value: message['value'],
      nonce: message['nonce']
    ).find_or_create_by(cid: message['cid'])
  end
  max_height = Block.where(['"from" = ? or "to" = ?', address, address]).maximum(:height) || 0
  FilFox.get_blocks(address, max_height).each do |message|
    Block.create_with(
      height: message['height'], 
      cid: message['cid'],
      miner: address,
      reward: message['reward']
    ).find_or_create_by(cid: message['cid'])
  end
=end
  max_height = Transfer.where(['"from" = ? or "to" = ?', address, address]).maximum(:height) || 0
  FilFox.get_transfers(address, max_height) do |message|
    next unless [message['from'], message['to']].include? address
    Transfer.create_with(
      height: message['height'],
      message_cid: message['message'],
      from: message['from'],
      to: message['to'],
      type: message['type'],
      value: message['value']
    ).find_or_create_by(
      height: message['height'],
      from: message['from'],
      to: message['to'],
      type: message['type'],
      value: message['value']
    )
  end
end

addresses = []
if @options[:address]
  addresses << @options[:address]
end
if @options[:file]
  addresses << File.read(@options[:file]).lines.map {|line| line.strip}.reject {|line| line.empty?}
end

addresses = addresses.flatten
puts "== Processing Below Addresses =="
addresses.each do |address|
  puts "  #{address}"
end

puts "== Updating Addresses =="
addresses.each do |address|
  update_address(address)
end

prefix = @options[:output_prefix] || 'output'
incoming = CSV.open("#{prefix}.incoming.csv", "wb")
outgoing = CSV.open("#{prefix}.outgoing.csv", "wb")

Transfer.where(['"from" in (?) or "to" in (?)', addresses, addresses]).each do |transfer|
  from, to, type, value = transfer['from'], transfer['to'], transfer['type'], transfer['value'].to_i
  # Skip internal transfer
  next if addresses.include?(from) && addresses.include?(to)
  if addresses.include? to
    csv = incoming
    csv << ["Coin Symbol", "Amount", "Timestamp", "Incoming Type"]
  else
    csv = outgoing
    csv << ["Coin Symbol", "Amount", "Timestamp", "Outgoing Type"]
  end

  case type
  when 'receive'
    type = 'Income'
  when 'burn', 'burn-fee', 'miner-fee'
    type = 'Network Fee'
  when 'reward'
    type = 'Mining'
  else
    puts "Unknown type #{type}"
    p transfer
    exit
  end
end
