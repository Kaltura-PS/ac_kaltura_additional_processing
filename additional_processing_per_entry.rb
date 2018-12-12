#!/usr/bin/ruby
require 'kaltura'
require_relative 'kaltura_additional_processing'

include Kaltura

def init_client(base_endpoint, partner_id, secret)
    config = KalturaConfiguration.new
    config.service_url = base_endpoint
    client = KalturaClient.new(config)
    client.ks = client.session_service.start(
      secret,
      nil,
      Kaltura::KalturaSessionType::ADMIN,
      partner_id,
      nil,
      'disableentitlement'
    )

    return client
end

if ARGV.length < 2
  puts 'Usage: ' + __FILE__ + ' <entry_id sco_id>'
  exit 1
end

@logger = Logger.new(STDOUT)
@logger.level = Logger::INFO
@logger.formatter = proc do |severity, datetime, _progname, msg|
      fileLine = ''
      caller.each do |clr|
        unless /\/logger.rb:/ =~ clr
          fileLine = clr
          break
        end
      end
      fileLine = fileLine.split(':in `', 2)[0]
      fileLine.sub!(/:(\d)/, '(\1')
      "#{datetime}: #{severity} #{fileLine}): #{msg}\n"
end

client = init_client(ENV['KALTURA_BASE_ENDPOINT'], ENV['KALTURA_PARTNER_ID'], ENV['KALTURA_PARTNER_SECRET'])

# use a single input file and iterate over each line in order to process all entries
entry_id = ARGV[0]
sco_id = ARGV[1]
basedir = File.dirname(__FILE__)

@logger.info('Handling entry ' + entry_id)
begin
    entry = client.media_service.get(entry_id)
rescue Kaltura::KalturaAPIError => e
    @logger.error("Exception Class: #{e.class.name}")
    @logger.error("Exception Message: #{e.message}")
    exit 1
end

meeting_id = entry.tags
# call sh script to download the zip
@logger.info(basedir + '/get_recording_files.sh ' + meeting_id)
system basedir + '/get_recording_files.sh ' + meeting_id

out_dir = ENV['OUTDIR'] ? ENV['OUTDIR'] : "/tmp"
dir_name = File.join(out_dir, meeting_id)

process_weblinks_and_hosts(client, entry, dir_name)
process_related_files(client, entry, dir_name)


