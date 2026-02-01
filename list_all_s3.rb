#!/usr/bin/env ruby
# Listar TODOS os objetos do S3

require 'aws-sdk-s3'

s3_client = Aws::S3::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: ENV['AWS_REGION']
)

bucket = ENV['AWS_BUCKET']

puts "Listando TODOS os objetos..."
all_objects = []
continuation_token = nil

loop do
  params = {
    bucket: bucket,
    max_keys: 1000
  }
  params[:continuation_token] = continuation_token if continuation_token
  
  response = s3_client.list_objects_v2(params)
  all_objects.concat(response.contents)
  
  break unless response.is_truncated
  continuation_token = response.next_continuation_token
end

total = all_objects.count
with_content = all_objects.select { |obj| obj.size > 0 }.count
total_size = all_objects.sum(&:size)

puts "Total de objetos: #{total}"
puts "Com conteúdo: #{with_content}"
puts "Vazios: #{total - with_content}"
puts "Tamanho total: #{(total_size / 1024.0 / 1024.0).round(2)} MB"
