require 'spec_helper'

describe CustomFormattingHelper do
  describe '`fhlb_formatted_currency` method' do
    it 'converts a number into the approved FHLB currency format' do
      expect(helper.fhlb_formatted_currency(465465465)).to eq('$465,465,465')
    end
    it 'omits the dollar-sign if it is passed the number 0' do
      expect(helper.fhlb_formatted_currency(0)).to eq('0')
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
    end
  end

  describe '`fhlb_date_long_alpha` method' do
    let(:date) {Date.new(2015,1,2)}
    it 'converts a date into an alphanumeric string following the `Month d, YYYY` format' do
      expect(helper.fhlb_date_long_alpha(date)).to eq('January 2, 2015')
    end
  end
  
  describe '`fhlb_formatted_phone_number` method' do
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
  end
end