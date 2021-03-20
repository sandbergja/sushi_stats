# frozen_string_literal: true

require 'dotenv/load'
require 'thor'
require 'net/http'
require 'json'

BOOK_REPORTS = {
  cambridge: 'http://counter5.cambridge.org/reports/tr_b1?'\
  "customer_id=#{ENV['CAMBRIDGE_CUSTOMER_ID']}&requestor_id=#{ENV['CAMBRIDGE_REQUESTOR_ID']}",
  ebookcentral: 'https://pqbi.prod.proquest.com/release/sushi/ebooks/r5/'\
                 "reports/tr_b1?requestor_id=#{ENV['EBOOK_CENTRAL_REQUESTOR_ID']}&"\
                 "customer_id=#{ENV['EBOOK_CENTRAL_CUSTOMER_ID']}",
  ebsco: 'https://sushi.ebscohost.com/R5/reports/tr_b1?'\
            "requestor_id=#{ENV['EBSCO_REQUESTOR_ID']}&customer_id=#{ENV['EBSCO_CUSTOMER_ID']}",
  gale: 'https://sushi5.galegroup.com/sushi/reports/tr_b1?'\
        "requestor_id=#{ENV['GALE_REQUESTOR_ID']}&customer_id=#{ENV['GALE_CUSTOMER_ID']}"
}.freeze

JOURNAL_REPORTS = {
  ebsco: 'https://sushi.ebscohost.com/R5/reports/tr_j1?'\
         "requestor_id=#{ENV['EBSCO_REQUESTOR_ID']}&customer_id=#{ENV['EBSCO_CUSTOMER_ID']}",
  gale: 'https://sushi5.galegroup.com/sushi/reports/tr_j1?'\
        "requestor_id=#{ENV['GALE_REQUESTOR_ID']}&customer_id=#{ENV['GALE_CUSTOMER_ID']}",
  jstor: 'https://www.jstor.org/sushi/reports/tr_j1?'\
         "requestor_id=#{ENV['JSTOR_REQUESTOR_ID']}&customer_id=#{ENV['JSTOR_CUSTOMER_ID']}",
  newsbank: 'https://stats.newsbank.com/sushi_r5/servlet/reports/tr_j1?'\
            "requestor_id=#{ENV['NEWSBANK_REQUESTOR_ID']}&customer_id=#{ENV['NEWSBANK_CUSTOMER_ID']}"
}.freeze

MULTIMEDIA_REPORTS = {
  alexander_street: 'https://pqbi.prod.proquest.com/release/sushi/asp/sushi/reports/ir_m1?'\
                    "requestor_id=#{ENV['ALEXANDER_STREET_REQUESTOR_ID']}&"\
                    "customer_id=#{ENV['ALEXANDER_STREET_CUSTOMER_ID']}",
  artstor: 'https://www.jstor.org/sushi/reports/ir_m1?'\
           "requestor_id=#{ENV['JSTOR_REQUESTOR_ID']}&customer_id=#{ENV['JSTOR_CUSTOMER_ID']}",
  bloomsbury: 'https://api-fivestar.highwire.org/sushi/reports/ir_m1?'\
              "requestor_id=#{ENV['BLOOMSBURY_REQUESTOR_ID']}&"\
              "customer_id=#{ENV['BLOOMSBURY_CUSTOMER_ID']}&"\
              "api_key=#{ENV['BLOOMSBURY_API_KEY']}&"\
              "platform=#{ENV['BLOOMSBURY_PLATFORM']}"\
}.freeze

# A class for pulling some stats via SUSHI
class SushiStats < Thor
  desc 'books BEGIN_DATE END_DATE', 'Book stats between the two dates'
  def books(begin_date, end_date)
    BOOK_REPORTS.each do |source, url_base|
      fetch_and_process_report source: source, url_base: url_base,
                               begin_date: begin_date, end_date: end_date
    end
  end

  desc 'journals BEGIN_DATE END_DATE', 'Journal stats between the two dates'
  def journals(begin_date, end_date)
    JOURNAL_REPORTS.each do |source, url_base|
      fetch_and_process_report source: source, url_base: url_base,
                               begin_date: begin_date, end_date: end_date
    end
  end

  desc 'multimedia BEGIN_DATE END_DATE', 'Journal stats between the two dates'
  def multimedia(begin_date, end_date)
    MULTIMEDIA_REPORTS.each do |source, url_base|
      fetch_and_process_report source: source, url_base: url_base,
                               begin_date: begin_date, end_date: end_date
    end
  end

  private

  def fetch_and_process_report(source:, url_base:, begin_date:, end_date:)
    json = fetch_stats url_base: url_base, begin_date: begin_date, end_date: end_date
    if stats_found?(json)
      puts "#{source}: #{stats_sum(json)}"
    else
      puts "#{source}: no stats found for this period"
    end
  end

  def fetch_stats(url_base:, begin_date:, end_date:)
    uri = URI("#{url_base}&begin_date=#{begin_date}&end_date=#{end_date}")
    response = Net::HTTP.get uri
    begin
      JSON.parse(response)
    rescue JSON::ParserError
      puts uri
      puts response
      nil
    end
  end

  def stats_sum(response)
    response['Report_Items'].sum do |item|
      matching_items = item['Performance'].select do |performance|
        performance['Instance'].first['Metric_Type'] == 'Total_Item_Requests'
      end
      matching_items.sum { |performance| performance['Instance'].first['Count'] }
    end
  end

  def stats_found?(response)
    response && response['Report_Items']
  end
end

SushiStats.start(ARGV)
