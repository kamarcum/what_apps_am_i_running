require 'nokogiri'

class InfoDocument < Nokogiri::XML::SAX::Document
  attr_reader :version
  def initialize
    @in_key = false
    @in_value = false
    @in_version = false
    @cf_bundle_version = nil
    @cf_bundle_short_version_string = nil
  end
  def start_element(name, attributes=[])
    case name
    when "key"
      @in_key = true
    when "string"
      @in_value = true
    end
  end
  def end_element(name, attributes=[])
    case name
    when "key"
      @in_key = false
    when "string"
      @in_value = false
    end
  end
  def characters(characters)
    if @in_key
      if characters == "CFBundleVersion" || characters == "CFBundleShortVersionString"
        @in_version = characters
      end
    elsif @in_value && @in_version
      if @in_version == "CFBundleVersion"
        @cf_bundle_version = characters
        @in_version = false
      elsif @in_version == "CFBundleShortVersionString"
        @cf_bundle_short_version_string = characters
        @in_version = false
      end
    end
  end
  def version
    @cf_bundle_version || @cf_bundle_short_version_string
  end
end

def find_app_versions_for(base_path)
  results = {}
  Dir.foreach(base_path) do |path|
    total_path = "#{base_path}/#{path}"
    if path =~ /\.app$/
      relevant_plists = [total_path + "/Contents/Info.plist", total_path + "/Contents/version.plist"]
      relevant_plists.each do |info_plist|
        if File.exists? info_plist
          info = File.read info_plist
          document = InfoDocument.new
          parser = Nokogiri::XML::SAX::Parser.new(document)
          parser.parse info
          if document.version
            results[path] = document.version
            break
          end
        end
      end
    elsif path != "." && path != ".." && Dir.exists?(total_path)
      results.merge find_app_versions_for total_path
    end
  end
  results
end

results = find_app_versions_for "/Applications"
user_apps_dir = "#{ENV['HOME']}/Applications"
if Dir.exists? user_apps_dir
  results.merge find_app_versions_for "#{ENV['HOME']}/Applications"
end
results.each_pair do |key, value|
  puts "#{key} => #{value}"
end
