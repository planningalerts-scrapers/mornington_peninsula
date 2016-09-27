require 'scraperwiki'
require 'mechanize'

init_url = 'http://www.mornpen.vic.gov.au/Building-Planning/Planning/Advertised-Planning-Applications'
comment_url = 'mailto:planning.submission@mornpen.vic.gov.au'

agent = Mechanize.new

page = agent.get(init_url)

table = page.search('table')
table.search('a').each do |a|
  detail_page = agent.get(a[:href])

  description = detail_page.at('div#main-content p').text
  description.slice! ("Proposal:")
  description = description.gsub(/\A\p{Space}*/, '').capitalize

  record = {
    'council_reference' => detail_page.search('div#main-content h1')[0].text.lstrip.rstrip,
    'description'       => description,
    'address'           => detail_page.search('div#main-content h1')[1].text.split.map(&:capitalize).join(' ') + ', VIC',
    'info_url'          => a[:href],
    'comment_url'       => comment_url,
    'date_scraped'      => Date.today.to_s
  }

  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    puts "Saving record " + record['council_reference'] + " - " + record['address']
    # puts record
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
     puts "Skipping already saved record " + record['council_reference']
  end
end
