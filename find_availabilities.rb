require "postcodes_io"
require "csv"
require "open-uri"
require "nokogiri"

TYPES = [
  "AstraZeneca - Dose 1",
  "AstraZeneca - Dose 2",
  "Pfizer - Dose 1",
  "Pfizer - Dose 2",
  "Moderna - Dose 1",
  "Moderna - Dose 2"
]

CenterInfo = Struct.new(:address, :availabilities, keyword_init: true)

def parse_url(url)
  doc = Nokogiri::HTML(URI.open(url))

  address_node = doc.xpath('//*[@id="main-content"]/div/div/p[1]')
  address = address_node.text
  table = doc.at(".nhsuk-table")

  availabilities = TYPES.map { |v| [v, false] }.to_h
  table&.search("tr")&.each do |tr|
    cells = tr.search("td")
    next unless cells.any?
    vaccine_type = cells[0].text.strip

    available = cells[1].text.strip === "Available"
    availabilities[vaccine_type] = available
  end

  CenterInfo.new(address: address, availabilities: availabilities)
end

CSV.open("centers-availabilities.csv", "w") do |output|
  CSV.open("centers-code.csv", headers: true) do |csv|
    output << %w[name address] + TYPES

    csv.each do |row|
      code = row["code"]
      url = "https://www.nhs.uk/service-search/find-a-walk-in-coronavirus-covid-19-vaccination-site/profile/#{code}"
      info = parse_url(url)

      output << [row["name"], info.address] + info.availabilities.values_at(*TYPES)
    end
  end
end
