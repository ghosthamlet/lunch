When(/^I click on the reports link in the header$/) do
  page.find('.page-header .secondary-nav a', text: I18n.t('reports.title')).click
end

Then(/^I should see "(.*?)" as the report page's main title$/) do |title|
  page.assert_selector('h1', text: title)
end

Then(/^I should see a table of "(.*?)" reports$/) do |title|
  page.assert_selector('.reports-table th', text: title)
end

Given(/^I don't see the reports dropdown$/) do
  page.find('.logo').hover # make sure the mouse isn't left on top of the reports dropdown from a different test
  report_menu = page.find('.nav-menu', text: I18n.t('reports.title'))
  report_menu.parent.assert_selector('.nav-dropdown', visible: :hidden)
end

When(/^I hover on the reports link in the header$/) do
  page.find('.nav-menu', text: I18n.t('reports.title')).hover
end

Then(/^I should see the reports dropdown$/) do
  report_menu = page.find('.nav-menu', text: I18n.t('reports.title'))
  report_menu.parent.assert_selector('.nav-dropdown', visible: true)
end

Given(/^I am on the reports summary page$/) do
  visit "/reports"
end

When(/^I select "(.*?)" from the reports dropdown$/) do |report|
  step 'I don\'t see the reports dropdown'
  step 'I hover on the reports link in the header'
  page.click_link(report)
end

Then(/^I should see report summary data$/) do
  page.assert_selector('.report-summary-data', visible: true)
end

Then(/^I should see a report table with multiple data rows$/) do
  page.assert_selector('.report-table')
  expect(page.all('.report-table tbody tr').length).to be > 0
end

Given(/^I am on the Capital Stock Activity Statement page$/) do
  sleep_if_close_to_midnight
  @today = Time.zone.now.to_date
  visit '/reports/capital-stock-activity'
end

Given(/^I am on the Settlement Transaction Account Statement page$/) do
  sleep_if_close_to_midnight
  @today = Time.zone.now.to_date
  visit '/reports/settlement-transaction-account'
end

Given(/^I am on the Advances Detail page$/) do
  sleep_if_close_to_midnight
  @today = Time.zone.now.to_date
  visit '/reports/advances-detail'
end

Given(/I am on the Borrowing Capacity Statement page$/) do
  visit '/reports/borrowing-capacity'
end

When(/^I click the Certificate Sequence column heading$/) do
  page.find('th', text: I18n.t('reports.pages.capital_stock_activity.certificate_sequence')).click
end

When(/^I click the Trade Date column heading$/) do
  page.find('th', text: I18n.t('reports.pages.advances_detail.trade_date')).click
end

When(/^I click the Date column heading$/) do
  page.find('th', text: I18n.t('global.date')).click
end

Then(/^I should see a "(.*?)" for the current month to date$/) do |report_type|
  start_date = @today.beginning_of_month.strftime('%B %-d, %Y')
  end_date = @today.strftime('%B %-d, %Y')
  step %{I should see a "#{report_type}" starting on "#{start_date}" and ending on "#{end_date}"}
end

Then(/^I should see a "(.*?)" for the last month$/) do |report_type|
  last_month = (@today.beginning_of_month - 1.months)
  start_date = last_month.strftime('%B %-d, %Y')
  end_date = last_month.end_of_month.strftime('%B %-d, %Y')
  step %{I should see a "#{report_type}" starting on "#{start_date}" and ending on "#{end_date}"}
end

Then(/^I should see a "(.*?)" for the (\d+)(?:st|rd|th) through the (\d+)(?:st|rd|th) of this month$/) do |report_type, start_day, end_day|
  start_date = Date.new(@today.year, @today.month, start_day.to_i).strftime('%B %-d, %Y')
  end_date = Date.new(@today.year, @today.month, end_day.to_i).strftime('%B %-d, %Y')
  step %{I should see a "#{report_type}" starting on "#{start_date}" and ending on "#{end_date}"}
end

Then(/^I should see a "(.*?)" starting on "(.*?)" and ending on "(.*?)"$/) do |report_type, start_date, end_date|
  case report_type
    when "Settlement Transaction Account Statement"
      opening_balance = I18n.t('reports.pages.settlement_transaction_account.opening_balance_heading', date: start_date)
      closing_balance = I18n.t('reports.pages.settlement_transaction_account.closing_balance_heading', date: end_date)
    when "Capital Stock Activity Statement"
      opening_balance = I18n.t('reports.pages.capital_stock_activity.opening_balance_heading', date: start_date)
      closing_balance = I18n.t('reports.pages.capital_stock_activity.closing_balance_heading', date: end_date)
    else raise "unknown report type"
  end
  expect(page.find(".datepicker-trigger input").value).to eq("#{start_date} - #{end_date}")
  step %{I should see "#{opening_balance}"}
  step %{I should see "#{closing_balance}"}
  start_date_obj = start_date.to_date
  end_date_obj = end_date.to_date
  report_dates_in_range?(start_date_obj, end_date_obj)
end

Then(/^I should see a "(.*?)" with data for dates between the (\d+)(?:st|rd|th) through the (\d+)(?:st|rd|th) of (this|last) month$/) do |report_type, start_day, end_day, month|
  if month == 'this'
    start_date_obj = Date.new(@today.year, @today.month, start_day.to_i)
    end_date_obj = Date.new(@today.year, @today.month, end_day.to_i)
  elsif month == 'last'
    start_date_obj = (Date.new(@today.year, @today.month, start_day.to_i) - 1.month)
    end_date_obj = (Date.new(@today.year, @today.month, end_day.to_i) - 1.month)
  end
  step %{I should see a "Settlement Transaction Account Statement" with dates between "#{start_date_obj}" and "#{end_date_obj}"}
end

Then(/^I should see a "(.*?)" with dates between "(.*?)" and "(.*?)"$/) do |report_type, start_date, end_date|
  # TODO add a null check for the case where no data is returned at all
  start_date_obj = start_date.to_date
  end_date_obj = end_date.to_date
  case report_type
    when "Settlement Transaction Account Statement"
      opening_balance = I18n.t('reports.pages.settlement_transaction_account.opening_balance_heading', date: nil)
      closing_balance = I18n.t('reports.pages.settlement_transaction_account.closing_balance_heading', date: nil)
    when "Capital Stock Activity Statement"
      opening_balance = I18n.t('reports.pages.capital_stock_activity.opening_balance_heading', date: nil)
      closing_balance = I18n.t('reports.pages.capital_stock_activity.closing_balance_heading', date: nil)
    else raise "unknown report type"
  end
  expect(page.find(".datepicker-trigger input").value).to eq("#{start_date_obj.strftime('%B %-d, %Y')} - #{end_date_obj.strftime('%B %-d, %Y')}")
  returned_start_date = page.find('.report-summary-data:nth-child(1) h3').text.gsub(opening_balance, '').to_date
  returned_end_date = page.find('.report-summary-data:nth-child(2) h3').text.gsub(closing_balance, '').to_date
  expect(start_date_obj).to be <= returned_start_date
  expect(end_date_obj).to be >= returned_end_date
  report_dates_in_range?(start_date_obj, end_date_obj)
end

Given(/^I'm showing Settlement Transaction Account activities from the last year$/) do
  start_date = (Time.zone.now.to_date - 1.year).strftime('%B %-d, %Y')
  end_date = Time.zone.now.to_date.strftime('%B %-d, %Y')
  sleep_if_close_to_midnight
  step 'I click the datepicker field'
  step 'I select all of last year including today'
  step 'I click the datepicker apply button'
  step %{I should see a "Settlement Transaction Account Statement" with dates between "#{start_date}" and "#{end_date}"}
end

When(/^I filter the Settlement Transaction Account Statement by "(.*?)"$/) do |text|
  page.find('.dropdown-selection').click
  page.find('li', text: text).click
end

Then(/^I should only see "(.*?)" rows in the Settlement Transaction Account Statement table$/) do |text|
  page.assert_selector('.report-table thead th', text: text)
  column_index = page.evaluate_script("$('.report-table thead th:contains(#{text})').index()") + 1
  if !page.find(".report-table tbody tr:first-child td:first-child")['class'].split(' ').include?('dataTables_empty')
    page.all(".report-table tbody tr:not(.beginning-balance-row) td:nth-child(#{column_index})").each_with_index do |element, index|
      next if index == 0 # this is a hack to get around Capybara's inability to handle tr:not(.beginning-balance-row, .ending-balance-row). Apparently, Capybara can only handle one `not` selector
      expect(element.text.gsub(/\D/,'').to_f).to be > 0
    end
  end
end

def sleep_if_close_to_midnight
  now = DateTime.now
  seconds_till_tomorrow = (now.tomorrow.beginning_of_day - now) * 1.days
  if seconds_till_tomorrow <= 30
    sleep(seconds_till_tomorrow + 1)
  end
end

def report_dates_in_range? (start_date, end_date, date_format="%m/%d/%Y")
  page.all('.report-table tbody td:first-child').each do |element|
    if element['class'].split(' ').include?('dataTables_empty')
      next
    end
    date = Date.strptime(element.text, date_format)
    raise Capybara::ExpectationNotMet, "date #{date} out of range [#{start_date}, #{end_date}]" unless date >= start_date && date <= end_date
  end
end
