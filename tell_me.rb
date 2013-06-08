require 'nokogiri'

class InfoDocument < Nokogiri::XML::SAX::Document
  attr_reader :version
  def initialize
    @in_key = false
    @in_value = false
    @in_version = false
    @version = nil
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
        @in_version = true
      end
    elsif @in_value && @in_version
      @version = characters
      @in_version = false
    end
  end
end

def print_app_versions_for(base_path)
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
            puts "#{path} is version #{document.version}"
            break
          end
        end
      end
    elsif path != "." && path != ".." && Dir.exists?(total_path)
      print_app_versions_for total_path
    end
  end
end

print_app_versions_for "/Applications"
print_app_versions_for "/Users/keith/Applications"
