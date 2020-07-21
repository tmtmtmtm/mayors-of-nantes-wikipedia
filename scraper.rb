#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'pry'
require 'scraped'
require 'wikidata_ids_decorator'

require_relative 'lib/unspan_all_tables'
require_relative 'lib/remove_notes'

class String
  def present?
    not tidy.empty?
  end
end

# The Wikipedia page with a list of officeholders
class ListPage < Scraped::HTML
  decorator RemoveNotes
  decorator WikidataIdsDecorator::Links

  field :officeholders do
    list.xpath('.//tr[td[3]]').map { |td| fragment(td => HolderItem).to_h }
  end

  private

  def list
    noko.xpath('.//table[.//th[contains(., "Étiquette")]]').first
  end
end

# Each officeholder in the list
class HolderItem < Scraped::HTML
  field :id do
    return 'Q3427041' if name == 'René de Cornulier-Lucinière'
    tds[2].css('a/@wikidata').map(&:text).first
  end

  field :name do
    tds[2].css('a').map(&:text).last.tidy
  end

  field :start_date do
    [tds[0].css('time/@datetime').text, tds[0].css('a').map(&:text).first.to_s.tidy].select(&:present?).first
  end

  field :end_date do
    [tds[1].css('time/@datetime').text, tds[1].css('a').map(&:text).first.to_s.tidy, start_date].select(&:present?).first
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
