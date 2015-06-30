CarrierWave.configure do |config|
  config.storage = :fog
  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => 'AKIAJNM33Z5GZXUPRGQQ',
    :aws_secret_access_key  => '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'
  }
  config.fog_directory  = 'usebento'
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