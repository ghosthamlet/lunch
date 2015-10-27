require 'rails_helper'

describe CustomFormattingHelper do
  describe '`fhlb_formatted_currency` method' do
    it 'converts a number into the approved FHLB currency format' do
      expect(helper.fhlb_formatted_currency(465465465, html: false)).to eq('$465,465,465.00')
    end
    it 'omits the dollar-sign and decimals if it is passed the number 0' do
      expect(helper.fhlb_formatted_currency(0, html: false)).to eq('0')
    end
    it 'shows the dollar-sign if it is passed the number 0 and force_unit is true' do
      expect(helper.fhlb_formatted_currency(0, html: false, force_unit: true)).to eq('$0.00')
    end
    it 'accepts an optional precision value' do
      expect(helper.fhlb_formatted_currency(465465465, precision: 0, html: false)).to eq('$465,465,465')
    end
    it 'wraps negative numbers in paranthesis' do
      expect(helper.fhlb_formatted_currency(-123456789, html: false)).to eq('$(123,456,789.00)')
    end
    it 'wraps the formatted currency in a span with a class indicating the sign if requested' do
      expect(helper.fhlb_formatted_currency(-123456789, html: true)).to eq('<span class="number-negative">$(123,456,789.00)</span>')
      expect(helper.fhlb_formatted_currency(123456789, html: true)).to eq('<span class="number-positive">$123,456,789.00</span>')
    end
    it 'defaults to HTML output' do
      expect(helper.fhlb_formatted_currency(123)).to eq('<span class="number-positive">$123.00</span>')
    end
    it 'returns nil if passed nil and the option `optional_number`' do
      expect(helper.fhlb_formatted_currency(nil, optional_number: true)).to be_nil
    end
    it 'returns the `missing_value` I18n value if passed nil' do
      expect(helper.fhlb_formatted_currency(nil)).to eq(I18n.t('global.missing_value'))
    end
  end

  describe '`fhlb_formatted_currency_whole` method' do
    it 'calls fhlb_formatted_currency with a default precision of 0' do
      number = double('Number')
      expect(helper).to receive(:fhlb_formatted_currency).with(number, {precision: 0})
      helper.fhlb_formatted_currency_whole(number)
    end
    it 'returns the `missing_value` I18n value if passed nil' do
      expect(helper.fhlb_formatted_currency_whole(nil)).to eq(I18n.t('global.missing_value'))
    end
  end

  describe '`fhlb_formatted_number` method' do
    it 'adds delimiters to the number' do
      expect(helper.fhlb_formatted_number(123456789, html: false)).to eq('123,456,789')
    end
    it 'wraps negative numbers in paranthesis' do
      expect(helper.fhlb_formatted_number(-123456789, html: false)).to eq('(123,456,789)')
    end
    it 'wraps the formatted currency in a span with a class indicating the sign if requested' do
      expect(helper.fhlb_formatted_number(-123456789, html: true)).to eq('<span class="number-negative">(123,456,789)</span>')
      expect(helper.fhlb_formatted_number(123456789, html: true)).to eq('<span class="number-positive">123,456,789</span>')
    end
    it 'defaults to HTML output' do
      expect(helper.fhlb_formatted_number(123)).to eq('<span class="number-positive">123</span>')
    end
    it 'returns nil if passed nil and the option `optional_number`' do
      expect(helper.fhlb_formatted_number(nil, optional_number: true)).to be_nil
    end
    it 'returns the `missing_value` I18n value if passed nil' do
      expect(helper.fhlb_formatted_number(nil)).to eq(I18n.t('global.missing_value'))
    end
  end

  describe '`fhlb_date_standard_numeric` method' do
    describe 'converting a date in to a string following the MM/DD/YYYY convention' do
      it 'should handle single digit months and days' do
        expect(helper.fhlb_date_standard_numeric(Date.new(2015,1,2))).to eq('01/02/2015')
      end
      it 'should handle double digit months and days' do
        expect(helper.fhlb_date_standard_numeric(Date.new(2015,11,20))).to eq('11/20/2015')
      end
      it 'returns the I18n value for `missing_value` if passed nil' do
        expect(helper.fhlb_date_standard_numeric(nil)).to eq(I18n.t('global.missing_value'))
      end
    end
  end

  describe '`fhlb_report_date_numeric` method' do
    describe 'converting a date in to a string following the MM-DD-YYYY convention' do
      it 'should remove leading zeros from single digit months and days' do
        expect(helper.fhlb_report_date_numeric(Date.new(2015,1,2))).to eq('1-2-2015')
      end
      it 'should handle double digit months and days' do
        expect(helper.fhlb_report_date_numeric(Date.new(2015,11,20))).to eq('11-20-2015')
      end
      it 'returns the I18n value for `missing_value` if passed nil' do
        expect(helper.fhlb_report_date_numeric(nil)).to eq(I18n.t('global.missing_value'))
      end
    end
  end

  describe '`fhlb_datetime_standard_numeric` method' do
    let(:date) {DateTime.new(2015,1,2, 10, 12, 13)}
    it 'converts a datetime into a string following the `Time MM/DD/YYYY` format' do
      expect(helper.fhlb_datetime_standard_numeric(date)).to eq('10:12 am 01/02/2015')
    end
    it 'returns the I18n value for `missing_value` if passed nil' do
      expect(helper.fhlb_datetime_standard_numeric(nil)).to eq(I18n.t('global.missing_value'))
    end
  end

  describe '`fhlb_date_long_alpha` method' do
    let(:date) {Date.new(2015,1,2)}
    it 'converts a date into an alphanumeric string following the `Month d, YYYY` format' do
      expect(helper.fhlb_date_long_alpha(date)).to eq('January 2, 2015')
    end
    it 'returns the I18n value for `missing_value` if passed nil' do
      expect(helper.fhlb_date_long_alpha(nil)).to eq(I18n.t('global.missing_value'))
    end
  end

  describe '`fhlb_date_short_alpha` method' do
    it 'converts a date into an alphanumeric string following the `Month YYYY` format' do
      [Date.new(2015,1,1), Date.new(2015,1,31), Date.new(2015,1,15)].each do |date|
        expect(helper.fhlb_date_short_alpha(date)).to eq('January 2015')
      end
    end
    it 'returns the I18n value for `missing_value` if passed nil' do
      expect(helper.fhlb_date_short_alpha(nil)).to eq(I18n.t('global.missing_value'))
    end
  end
  
  describe '`fhlb_formatted_phone_number` method' do
    it 'returns nil if it is not passed a phone number' do
      expect(helper.fhlb_formatted_phone_number(nil)).to be_nil
    end
    it 'converts a 10 digit phone number into the FHLB format' do
      expect(helper.fhlb_formatted_phone_number('1234567890')).to eq('(123) 456-7890')
    end
    it 'converts an 11 digit phone number into the FHLB format' do
      expect(helper.fhlb_formatted_phone_number('11234567890')).to eq('(123) 456-7890')
    end
    it 'approrpiately styles extentions if provided' do
      expect(helper.fhlb_formatted_phone_number('1234567890', '6789')).to eq('(123) 456-7890, ext. 6789')
    end
    it 'raises an exception if fewer than 10 digits are supplied' do
      expect {helper.fhlb_formatted_phone_number('123456789')}.to raise_error
    end
    it 'raises an exception if more than 11 digits are supplied' do
      expect {helper.fhlb_formatted_phone_number('123456789012')}.to raise_error
    end
    it 'raises an exception if 11 digits are supplied and the first is not a 1' do
      expect {helper.fhlb_formatted_phone_number('21234567890')}.to raise_error
    end
    it 'removes non-digit characters from the supplied string' do
      expect(helper.fhlb_formatted_phone_number('123-456 7890', '67a89')).to eq('(123) 456-7890, ext. 6789')
    end
    it 'does not include the ext section if a blank string was passed' do
      expect(helper.fhlb_formatted_phone_number('11234567890', '')).to eq('(123) 456-7890')
    end
    it 'does not include the ext section if a string without digits was passed' do
      expect(helper.fhlb_formatted_phone_number('11234567890', 'abc')).to eq('(123) 456-7890')
    end
  end

  describe '`fhlb_date_quarter` method' do
    [[1..3, 'First Quarter 2015'], [4..6, 'Second Quarter 2015'], [7..9, 'Third Quarter 2015'], [10..12, 'Fourth Quarter 2015']].each do |expectation|
      expectation.first.each do |month|
        it 'converts a date into its quarter representation' do
          expect(helper.fhlb_date_quarter(Date.new(2015, month, 2))).to eq(expectation.last)
        end
      end
    end
    it 'returns the I18n value for `missing_value` if passed nil' do
      expect(helper.fhlb_date_quarter(nil)).to eq(I18n.t('global.missing_value'))
    end
  end

  describe '`fhlb_add_unit_to_table_header` method' do
    it 'adds a (unit) to a string' do
      expect(helper.fhlb_add_unit_to_table_header('my header', '%')).to eq('my header (%)')
    end
  end

  describe '`fhlb_formatted_percentage` method' do
    it 'returns percentage with no precision' do
      expect(helper.fhlb_formatted_percentage(30.23)).to eq('30%')
    end
    it 'returns percentage with 2 precision' do
      expect(helper.fhlb_formatted_percentage(30.23, 2)).to eq('30.23%')
    end
    it 'returns the I18n value for `missing_value` if passed nil' do
      expect(helper.fhlb_formatted_percentage(nil)).to eq(I18n.t('global.missing_value'))
    end
  end

  describe '`fhlb_formated_currency_unit` method' do
    it 'returns two spans nested in a span with `$` as the default currency symbol and a currency with precision of 0' do
      expect(helper.fhlb_formated_currency_unit(30)).to eq("<span class=\"currency-alignment\"><span class=\"alignleft\">$</span><span class=\"alignright\"><span class=\"number-positive\">30</span></span></span>")
    end
    it 'returns two spans nested in a span with any passed in string as the currency symbol' do
      expect(helper.fhlb_formated_currency_unit(30, '£')).to eq("<span class=\"currency-alignment\"><span class=\"alignleft\">£</span><span class=\"alignright\"><span class=\"number-positive\">30</span></span></span>")
    end
    it 'returns currency with 2 precision and left/right align' do
      expect(helper.fhlb_formated_currency_unit(30, '$', 2)).to eq('<span class="currency-alignment"><span class="alignleft">$</span><span class="alignright"><span class="number-positive">30.00</span></span></span>')
    end
    it 'returns no currency span and a span with the I18n value for missing value when passed nil' do
      expect(helper.fhlb_formated_currency_unit(nil)).to eq("<span class=\"currency-alignment\"><span class=\"alignright\">#{I18n.t('global.missing_value')}</span></span>")
    end
  end

  describe '`mask_email`' do
    it 'returns nil if passed nil' do
      expect(helper.mask_email(nil)).to be_nil
    end
    it 'returns nil if passed a malformed email' do
      email = double('An Email')
      matches = double('MatchData', length: 5)
      allow(email).to receive(:match).and_return(matches)
      expect(helper.mask_email(email)).to be_nil
    end
    it 'should mask the email' do
      email = double('An Email')
      masked_email = double('MaskedEmail')
      matches = double('MatchData', length: 6)
      intermediary_1 = double('Masked Email Intermiedary 1')
      intermediary_2 = double('Masked Email Intermiedary 2')
      intermediary_3 = double('Masked Email Intermiedary 3')
      intermediary_4 = double('Masked Email Intermiedary 4')

      allow(matches).to receive(:[]).with(1).and_return(double('MatchData:1'))
      allow(matches).to receive(:[]).with(2).and_return(double('MatchData:2', length: rand(1..5)))
      allow(matches).to receive(:[]).with(3).and_return(double('MatchData:3'))
      allow(matches).to receive(:[]).with(4).and_return(double('MatchData:4', length: rand(1..5)))
      allow(matches).to receive(:[]).with(5).and_return(double('MatchData:5'))
      allow(matches[1]).to receive(:+).with('*' * matches[2].length).and_return(intermediary_1)
      allow(intermediary_1).to receive(:+).with('@').and_return(intermediary_2)
      allow(intermediary_2).to receive(:+).with(matches[3]).and_return(intermediary_3)
      allow(intermediary_3).to receive(:+).with('*' * matches[4].length).and_return(intermediary_4)
      allow(intermediary_4).to receive(:+).with(matches[5]).and_return(masked_email)
      allow(email).to receive(:match).and_return(matches)
      
      expect(helper.mask_email(email)).to be(masked_email)
    end
    describe 'with fixtures' do
      it 'returns nil if passed a malformed email' do
        ['foo', 'foo@bar', 'foo@bar%', '@foo.com'].each do |email|
          expect(helper.mask_email(email)).to be_nil
        end
      end
    end
    it 'should mask the email' do
      {
        'foo@example.com' => 'f**@e******.com',
        'monkey@example.co.bar' => 'm*****@e*********.bar'
      }.each do |input, output|
        expect(helper.mask_email(input)).to eq(output)
      end
    end
  end
  
  describe '`report_summary_with_date`' do
    let(:i18n_string) { double('an I18n key') }
    let(:date) { double('a date string') }
    let(:other_arg) { double('another I18n arg')}
    let(:other_arg_hash) { {foo: other_arg} }
    let(:response) { double('the interpolated string', html_safe: nil)}
    let(:call_method) { helper.report_summary_with_date(i18n_string, date) } 
    
    before { allow(I18n).to receive(:t).and_return(response) }
    
    it 'sends the given string to I18n interpolation with a `date` argument in a span with class `report-summary-date`' do
      expect(I18n).to receive(:t).with(i18n_string, {date: content_tag(:span, date, class: 'report-summary-date')}).and_return(response)
      call_method
    end
    it 'sends the given string to I18n interpolation with any other args that were passed' do
      expect(I18n).to receive(:t).with(i18n_string, hash_including(foo: other_arg)).and_return(response)
      helper.report_summary_with_date(i18n_string, date, other_arg_hash)
    end
    it 'returns an `html_safe` interpolated string' do
      expect(response).to receive(:html_safe)
      call_method
    end
  end

end