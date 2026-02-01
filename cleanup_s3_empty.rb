#!/usr/bin/env ruby
# Deletar objetos vazios do S3

require 'aws-sdk-s3'

s3_client = Aws::S3::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: ENV['AWS_REGION']
)

bucket = ENV['AWS_BUCKET']

puts "Listando objetos vazios..."
all_objects = []
continuation_token = nil

loop do
  params = { bucket: bucket, max_keys: 1000 }
  params[:continuation_token] = continuation_token if continuation_token
  
  response = s3_client.list_objects_v2(params)
  all_objects.concat(response.contents)
  
  break unless response.is_truncated
  continuation_token = response.next_continuation_token
end

empty_objects = all_objects.select { |obj| obj.size == 0 }

puts "Encontrados #{empty_objects.count} objetos vazios"
puts "Deletando..."

deleted = 0
empty_objects.each do |obj|
  s3_client.delete_object(bucket: bucket, key: obj.key)
  deleted += 1
  puts "Deletado: #{obj.key}" if deleted % 100 == 0
end

puts "✓ #{deleted} objetos vazios deletados"
