require "postcodes_io"
require "csv"
require "open-uri"
require "nokogiri"

def parse_links(url)
  doc = Nokogiri::HTML(URI.open(url))
  doc.xpath("//div/div/ul/li/h2/a").map do |node|
    href = node["href"].split("/").last
    [href, node.text]
  end.to_h
end

pio = Postcodes::IO.new

links = {}

CSV.open("centers.csv", headers: true) do |csv|
  csv.each do |row|
    ps = row["Postcode"].gsub(/\s+/, "")
    postcode = pio.lookup(ps)
    next unless postcode
    lon = postcode.longitude
    lat = postcode.latitude

    url = "https://www.nhs.uk/service-search/find-a-walk-in-coronavirus-covid-19-vaccination-site/results?Query=#{ps}&Latitude=#{lat}&Longitude=#{lon}"

    puts "requesting #{ps}"

    links.merge!(parse_links(url))
  end
end

CSV.open("centers-code.csv", "w") do |csv|
  csv << %w[code name]
  links.each do |code, name|
    csv << [code, name]
  end
end
