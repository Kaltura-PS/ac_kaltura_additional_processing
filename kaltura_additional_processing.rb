#!/usr/bin/ruby
require 'kaltura'
require 'logger'
require 'nokogiri'

include Kaltura

def process_weblinks_and_hosts(client, entry, recording_path, use_html = true)
    # retrieve ftulrpush* files from the recording_path and grab the URLs
    pattern = File.join(recording_path,'fturlpush*.xml')
    files = Dir.glob(pattern)
    if files.empty?
        @logger.info('No relevant files were found! Skipping')
        return
    end

    web_links = ''
    for file in files do
        xml = Nokogiri::XML(open(file))
        xml.xpath('/root/Message[String/text()="setUrlInfoSo"]/Array/Object/newValue').each do |node|
            if node.at_xpath('url')
                if use_html
                    web_links += "<div>\n<a href=\"" + node.xpath('url').text + "\" >" + node.at_xpath('urlName').text + "</a>\n</div>\n"
                else
                    web_links += node.xpath('url').text + "\n"
                end
            end
        end
    end

    if (!web_links.empty? && use_html)
        web_links = "<div>\n" + web_links + "</div>"
    end

    update = KalturaMediaEntry.new()
    update.description = (entry.description ? entry.description : '') + "\n" + web_links

    #retrieve list of host users from the recording indexstream.xml and save them as entry co-editors
    entitled_users_edit = entry.entitled_users_edit ? entry.entitled_users_edit.split(',') : []
    pattern = File.join(recording_path,'indexstream*.xml')
    files = Dir.glob(pattern)
    if files.empty?
        @logger.info('No relevant files were found! Skipping')
        return
    end

    for file in files do
        xml = Nokogiri::XML(open(file))
        xml.xpath('/root/Message/Object/users/Object[role/text()="owner"]/email').each do |node|
           entitled_users_edit.push(node.text)
        end
    end

    @logger.info('Adding the following users to entry co-editors: ' + entitled_users_edit.join(','))
    update.entitled_users_edit = entitled_users_edit.join(',')
    begin
        result = client.media_service.update(entry.id, update);
    rescue Kaltura::KalturaAPIError => e
        @logger.error("Exception Class: #{e.class.name}")
        @logger.error("Exception Message: #{e.message}")
    end
end


def process_related_files(client, entry, recording_path)
    #retrieve list of related files from the recording indexstream.xml and save them as entry co-editors
    pattern = File.join(recording_path,'ftfileshare*.xml')
    files = Dir.glob(pattern)
    if files.empty?
        @logger.info('No relevant files were found! Skipping')
        return
    end

    for file in files do
        xml = Nokogiri::XML(open(file))
        xml.xpath('/root/Message[String/text()="setfileInfo_so"]/Array/Object/newValue').each do |node|
            ['downloadUrl', 'playbackFileName'].each do |node_name|
                if (node.xpath(node_name).empty?)
                    # no relevant URL found
                    next
                end
               url = ENV['AC_ENDPOINT'] + node.xpath(node_name).text.gsub('system/download?download-url=/_a7/','').gsub("&name=", '') + '?download=true'
               puts url

               create_attachment_asset(client, entry.id, node.xpath('name').text, url)
             end
        end
    end
end

def create_attachment_asset (client, entry_id, name, url)
    begin
       asset = KalturaAttachmentAsset.new()
       asset.filename = name
       asset.title = name
       result = client.attachment_asset_service.add(entry_id, asset)

       url_resource = KalturaUrlResource.new()
       url_resource.url = url
       result = client.attachment_asset_service.set_content(result.id, url_resource)
   rescue Kaltura::KalturaAPIError => e
       @logger.error("Exception Class: #{e.class.name}")
       @logger.error("Exception Message: #{e.message}")
   end
end
