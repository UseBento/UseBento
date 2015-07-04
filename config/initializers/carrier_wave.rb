CarrierWave.configure do |config|
  config.storage = :fog
  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => 'AKIAJXAS6QC5PAV3OABA',
    :aws_secret_access_key  => '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'
    :region                 => 'us-west-2'
  }
  config.fog_directory  = 'usebento'
  config.fog_public = false
  config.fog_attributes = { 'Cache-Control' => "max-age=#{365.day.to_i}"}
end

# CarrierWave.configure do |config|
#   config.storage = :fog
#   config.fog_credentials = {
#     :provider               => 'AWS',
#     :aws_access_key_id      => 'AKIAJTDJKWWUJZD42BBA',
#     :aws_secret_access_key  => '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'
#   }
#   config.fog_directory  = 'subout-test'
# end