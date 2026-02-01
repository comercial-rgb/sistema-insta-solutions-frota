#!/usr/bin/env ruby
# Verificar o que realmente está no S3

require 'aws-sdk-s3'

s3_client = Aws::S3::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: ENV['AWS_REGION']
)

bucket = ENV['AWS_BUCKET']

puts "Listando objetos no S3..."
response = s3_client.list_objects_v2(bucket: bucket, max_keys: 1000)

total = response.contents.count
total_size = response.contents.sum(&:size)
with_content = response.contents.select { |obj| obj.size > 0 }.count

puts "Total de objetos: #{total}"
puts "Com conteúdo (> 0 bytes): #{with_content}"
puts "Vazios (0 bytes): #{total - with_content}"
puts "Tamanho total: #{(total_size / 1024.0 / 1024.0).round(2)} MB"
