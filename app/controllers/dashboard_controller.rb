class DashboardController < ApplicationController

  MEMBER_ID = 750 #this is the hard-coded fhlb client id number we're using for the time-being
  THRESHOLD_CAPACITY = 35 #this will be set by each client, probably with a default value of 35, and be stored in some as-yet-unnamed db

  def index
    @previous_activity = [
      [t('dashboard.previous_activity.overnight_vrc'), 44503000, DateTime.new(2014,9,3)],
      [t('dashboard.previous_activity.overnight_vrc'), 39097000, DateTime.new(2014,9,2)],
      [t('dashboard.previous_activity.overnight_vrc'), 37990040, DateTime.new(2014,8,12)],
      [t('dashboard.previous_activity.overnight_vrc'), 39282021, DateTime.new(2014,2,14)]
    ]

    @anticipated_activity = [
      [t('dashboard.anticipated_activity.dividend'), 44503, DateTime.new(2014,9,3), t('dashboard.anticipated_activity.estimated')],
      [t('dashboard.anticipated_activity.collateral_rebalancing'), nil, DateTime.new(2014,9,2), ''],
      [t('dashboard.anticipated_activity.stock_purchase'), -37990, DateTime.new(2014,8,12), t('dashboard.anticipated_activity.estimated')],
    ]

    @account_overview = [
      [t('dashboard.your_account.table.balance'), 1973179.93],
      [t('dashboard.your_account.table.credit_outstanding'), 105000000]
    ]

    remaining = [
      [t('dashboard.your_account.table.remaining.available'), 105000000],
      [t('dashboard.your_account.table.remaining.leverage'), 12400000]
    ]

    market_value = [
      [t('dashboard.your_account.table.market_value.agency'), 0],
      [t('dashboard.your_account.table.market_value.aaa'), 0],
      [t('dashboard.your_account.table.market_value.aa'), 0]
    ]

    borrowing_capacity = [
      [t('dashboard.your_account.table.borrowing_capacity.standard'), 65000000],
      [t('dashboard.your_account.table.borrowing_capacity.agency'), 0],
      [t('dashboard.your_account.table.borrowing_capacity.aaa'), 0],
      [t('dashboard.your_account.table.borrowing_capacity.aa'), 0]
    ]

    @sub_tables = {remaining: remaining, market_value: market_value, borrowing_capacity: borrowing_capacity}

    @market_overview = [{
      name: 'Test',
      data: RatesService.new.overnight_vrc
    }];

    client_balances = ClientBalanceService.new(MEMBER_ID)

    @pledged_collateral = client_balances.pledged_collateral
    @total_securities = client_balances.total_securities
    @effective_borrowing_capacity = client_balances.effective_borrowing_capacity.merge!({threshold_capacity: THRESHOLD_CAPACITY}) # we'll be pulling threshold capacity from a different source than the ClientBalanceService
    @total_maturing_today = 46500000

  end



end