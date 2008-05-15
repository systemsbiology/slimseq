require File.dirname(__FILE__) + '/../test_helper'
require 'parseexcel'

class SampleTest < Test::Unit::TestCase
  fixtures :all

  def test_to_excel
    excel_file = Sample.to_excel
    
    workbook = Spreadsheet::ParseExcel.parse(excel_file)
    
    #################################
    # check unschemed samples
    #################################
    
    worksheet = workbook.worksheet(0)

    # heading
    assert_row_equal([
      "Sample ID",
      "Submission Date",
      "Short Sample Name",
      "Sample Name",
      "Sample Group Name",
      "Chip Type",
      "Organism",
      "SBEAMS User",
      "Project",
      "Status"
    ], worksheet.row(0))
    
    # samples
    assert_row_equal([
      "1.0",
      "2006-02-10",
      "yng",
      "Young",
      "Young",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
      "submitted"
    ], worksheet.row(1))
    
    assert_row_equal([
      "2.0",
      "2006-02-10",
      "old",
      "Old",
      "Old",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
      "hybridized"
    ], worksheet.row(2))
    
    assert_row_equal([
      "3.0",
      "2006-02-10",
      "vold",
      "Very Old",
      "Old",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
      "submitted"
    ], worksheet.row(3))
    
    assert_row_equal([
      "4.0",
      "2006-02-10",
      "vvold",
      "Very Very Old",
      "Old",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "MouseGroup",
      "hybridized"
    ], worksheet.row(4))
    
    assert_row_equal([
      "5.0",
      "2006-09-10",
      "bb",
      "Bob B",
      "Bob",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "Bob's Stuff",
      "submitted"
    ], worksheet.row(5))
  
    #################################
    # check schemed samples
    #################################
    
    worksheet = workbook.worksheet(2)
    assert_row_equal([
      "Sample ID",
      "Submission Date",
      "Short Sample Name",
      "Sample Name",
      "Sample Group Name",
      "Chip Type",
      "Organism",
      "SBEAMS User",
      "Project",
      "Status",
      "Strain",
      "Perturbation",
      "Perturbation Time",
      "Replicate",
      "Subject Number",
    ], worksheet.row(0))
    
    assert_row_equal([
      "6.0",
      "2007-05-31",
      "a1",
      "wt_HT_024_B_32234",
      "wt_HT_024",
      "Alligator 670 2.0",
      "Mouse",
      "bob",
      "Bob's Stuff",
      "submitted",
      "wild-type",
      "heat",
      "024",
      "B",
      "32234"      
    ], worksheet.row(1))
  end
  
  def assert_row_equal(expected, row)
    column = 0
    expected.each do |cell|
      assert_equal cell, row.at(column).to_s
      column += 1
    end
  end
end
