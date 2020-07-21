#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'pry'
require 'scraped'
require 'wikidata_ids_decorator'

require_relative 'lib/unspan_all_tables'

# The Wikipedia page with a list of officeholders
class ListPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :officeholders do
    list.xpath('.//tr[td]').map { |td| fragment(td => HolderItem).to_h }
  end

  private

  def list
    noko.xpath('.//table[.//th[contains(., "Gouvernement")]]').first
  end
end

# Each officeholder in the list
class HolderItem < Scraped::HTML
  field :id do
    tds[2].css('a/@wikidata').map(&:text).first
  end

  field :name do
    tds[2].text.tidy
  end

  field :start_date do
    tds[0].css('time/@datetime').text
  end

  field :end_date do
    tds[1].css('time/@datetime').text
  end

  field :replaces do
  end

  field :replaced_by do
  end

  private

  def tds
    noko.css('td,th')
  end
end

url = ARGV.first || abort("Usage: #{$0} <url to scrape>")
data = Scraped::Scraper.new(url => ListPage).scraper.officeholders

data.each_cons(2) do |prev, cur|
  cur[:replaces] = prev[:id]
  prev[:replaced_by] = cur[:id]
end

header = data[1].keys.to_csv
rows = data.map { |row| row.values.to_csv }
puts header + rows.join
