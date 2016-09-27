require 'scraperwiki'
require 'mechanize'

class Hash
  def has_blank?
    self.values.any?{|v| v.nil? || v.length == 0}
  end
end

init_url = 'http://www.mornpen.vic.gov.au/Building-Planning/Planning/Advertised-Planning-Applications'
comment_url = 'mailto:planning.submission@mornpen.vic.gov.au'

agent = Mechanize.new

page = agent.get(init_url)

table = page.search('table')
table.search('a').each do |a|
  begin
    detail_page = agent.get(a[:href])
  rescue Mechanize::ResponseCodeError => e
    puts "Skipping due to error getting info page: #{e}"
  else
    textlines = detail_page.at('div#main-content').text.split("\r")

    council_reference = textlines[0].strip

    description = textlines[4].strip
    description.slice!("Proposal:")
    description = description.gsub(/\A\p{Space}*/, '').capitalize

    address = textlines[3].strip.split.map(&:capitalize).join(' ') + ', VIC'

    record = {
      'council_reference' => council_reference,
      'description'       => description,
      'address'           => address,
      'info_url'          => a[:href],
      'comment_url'       => comment_url,
      'date_scraped'      => Date.today.to_s
    }

  unless record.has_blank?
      if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
        puts "Saving record " + record['council_reference'] + " - " + record['address']
#         puts record
        ScraperWiki.save_sqlite(['council_reference'], record)
      else
         puts "Skipping already saved record " + record['council_reference']
      end
    end
  end
end
