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