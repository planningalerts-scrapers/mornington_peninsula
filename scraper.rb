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

totalpages = page.search('div.seamless-pagination-info')
totalpages = totalpages.text.strip.split(" ")[3].to_i

for i in 1..totalpages
  puts "Checking page #{i} of #{totalpages}"
  form = page.form_with(:name => 'mainForm')
  form.field_with(:class => 'scSearchInputBox').options[i-1].click
  page = form.submit(form.button_with(:value=>'Go'))

  list = page.search('div.list-container')
  list.search('a').each do |a|
    begin
      detail_page = agent.get(a[:href].strip)

      council_reference = detail_page.at('meta[property="og:title"]')[:content].squeeze.strip
      address           = detail_page.at('meta[property="og:description"]')[:content] + ', VIC'

      description = detail_page.at('div#main-content').text.split("Proposal:")

      if ( description.size == 2 )
        description = description[1].split("Application No:")[0].strip
        description = description.gsub(/\A\p{Space}*/, '').capitalize.squeeze.strip
      else
        description = nil
      end

    rescue
      puts "Skipping due to error getting info page or its data"
    else
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
#           puts record
          ScraperWiki.save_sqlite(['council_reference'], record)
        else
          puts "Skipping already saved record " + record['council_reference']
        end
      else
      	puts "Something not right here: #{record}"
      end
    end
  end
end
