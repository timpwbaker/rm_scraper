class SoldScraper
  attr_reader :listing

  def initialize(listing)
    @listing = listing
  end

  def scrape
    browser.visit listing.rightmove_url

    begin
    history_button = browser.find(:css, '#historyMarketTab a')
    rescue Capybara::ElementNotFound
      Rails.logger.debug "No market tab"
      set_last_scraped_date
      return
    end

    history_button.click

    begin Capybara::ElementNotFound
      table = browser.find(:css, 'table.similar-nearby-sold-history-table')
    rescue
      Rails.logger.debug "No history table"
      set_last_scraped_date
      return
    end

    rows = table.all(:css, 'tr.similar-nearby-sold-history-row-height')
    rows.each do |row|
      cells = row.all(:css, 'td')
      year = cells[0]['innerHTML'].gsub(/[^0-9+]/,'').to_i
      amount = cells[1]['innerHTML'].gsub(/[^0-9+]/,'').to_i

      begin
        SoldPrice.create(listing_id: listing.id, year: year, amount: amount)
      rescue ActiveRecord::RecordNotUnique
        Rails.logger.debug "Not unique"
      end
    end
    set_last_scraped_date
  end

  def set_last_scraped_date
    listing.update_attribute(:last_checked_sold_prices, DateTime.current)
  end

  def browser
    @_browser ||= Capybara.current_session
  end
end
