require 'pdf/writer'
require 'pdf/simpletable'
require 'spreadsheet/excel'
include Spreadsheet

class ChargePeriodsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  
  def new
    @charge_period = ChargePeriod.new
  end

  def create
    @charge_period = ChargePeriod.new(params[:charge_period])
    if @charge_period.save
      flash[:notice] = 'ChargePeriod was successfully created.'
      redirect_to :controller => 'charge_sets', :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @charge_period = ChargePeriod.find(params[:id])
  end

  def update
    @charge_period = ChargePeriod.find(params[:id])
    
    begin
      if @charge_period.update_attributes(params[:charge_period])
        flash[:notice] = 'ChargePeriod was successfully updated.'
        redirect_to :controller => 'charge_sets', :action => 'list'
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this charge period."
      @charge_period = ChargePeriod.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    begin
      ChargePeriod.find(params[:id]).destroy
    rescue
      flash[:warning] = "Cannot delete charge period due to association " +
                        "with one or more charge sets."
    end
    redirect_to :controller => 'charge_sets', :action => 'list'
  end
  
  def pdf
    period = ChargePeriod.find(params[:id])
  
    _pdf = PDF::Writer.new()
    _pdf.select_font "Helvetica"
    _pdf.font_size = 16
    _pdf.text "\n\n" + SiteConfig.facility_name + " Charges For Period: " + 
              period.name + "\n\n", :justification => :center
    
    ###############
    # SUMMARY PAGE
    ###############
        
    table = PDF::SimpleTable.new
    table.width = 536
    table.position = :right
    table.orientation = :left
    table.font_size = 8
    table.heading_font_size = 8
    charge_sets = ChargeSet.find(:all, :conditions => [ "charge_period_id = ?", period.id ],
		                         :order => "name ASC")
    grand_total = 0
    for set in charge_sets
      set_total = set.total_cost
      grand_total += set_total
      table.data << {"Charge Set" => set.name, "Budget/PO" => set.budget,
                     "Cost" => fmt_dollars(set_total)}
    end
    
    # show grand totals
    table.data << {"Charge Set" => "TOTALS", "Budget/PO" => "",
                   "Cost" => fmt_dollars(grand_total)}
    
    table.column_order = [ "Charge Set", "Budget/PO", "Cost" ]
    table.render_on(_pdf)
    
    ############### 
    # DETAIL PAGES
    ###############
    
    for set in charge_sets
      _pdf.start_new_page
      
      # print heading and charge set / project info
      _pdf.font_size = 16
      _pdf.text "\n<b>" + SiteConfig.organization_name + "</b>", :justification => :center
      _pdf.text "<b>" + SiteConfig.facility_name + "</b>\n", :justification => :center

      if FileTest.exists?("public/images/organization_logo.jpg")
        # add logo if one exists
        _pdf.add_image_from_file "public/images/organization_logo.jpg", 450, 685, 120
      end
      
      _pdf.font_size = 10
      _pdf.text "\n\n" +
                "Project: " + set.name
      if set.charge_method == "internal"
        _pdf.text "Org Key: " + set.budget + "\n" +
                  "Budget Manager: " + set.budget_manager + "\n\n" +
                  "Budget Manager Approval: _________________________________"
      else
        _pdf.text "P.O. Number: " + set.budget
      end
      _pdf.text "\n\n"
      
      # print charge table, if there are any charges
      charges = Charge.find(:all, :conditions => ["charge_set_id = ?", set.id], :order => "date ASC")
      total = 0;
      
      if charges.size > 0
        table = PDF::SimpleTable.new
        table.width = 536
        table.position = :right
        table.orientation = :left
        table.font_size = 8
        table.heading_font_size = 8
        
        for charge in charges
          total = total + charge.cost
          table.data << { "Date" => charge.date, "Description" => charge.description,
                       "Cost" => fmt_dollars(charge.cost) }
        end
        table.column_order = [ "Date", "Description", "Cost" ]
        table.columns["Cost"] = PDF::SimpleTable::Column.new("Cost") { |col|
          col.width = 60
        }      
        table.render_on(_pdf)
      end

      _pdf.text "\n\n"
    
      # totals table
      table = PDF::SimpleTable.new
      table.position = :right
      table.orientation = :left
      table.font_size = 8
      table.heading_font_size = 8
      table.data = [ { "name" => "<b>TOTAL</b>", "content" => "<b>" + fmt_dollars(total).to_s + "</b>" }]
      table.column_order = [ "name", "content" ]
      table.columns["name"] = PDF::SimpleTable::Column.new("name") { |col|
        col.width = 60
      }
      table.columns["content"] = PDF::SimpleTable::Column.new("content") { |col|
        col.width = 60
      }  
      table.show_headings = false
      table.shade_rows = :none
      table.render_on(_pdf)
    end
    
    ########
    # DONE!
    ########
    
    pdf_file_name = "charges_" + period.name + ".pdf"
    send_data _pdf.render, :filename => pdf_file_name,
                           :type => "application/pdf"
  end
    
  def excel
    @period = ChargePeriod.find(params[:id])
  
    puts "VERSION: " + Excel::VERSION
    
    workbook_name = "#{RAILS_ROOT}/tmp/excel/charges_" + @period.name + ".xls"
    workbook = Excel.new(workbook_name)
    # doing each side individually, since :border => 1 is giving an error
    bordered = Format.new( :bottom => 1,
                           :top => 1,
                           :left => 1,
                           :right => 1 )
    bordered_bold = Format.new( :bottom => 1,
                                :top => 1,
                                :left => 1,
                                :right => 1,
                                :bold => true )
    workbook.add_format(bordered)
    workbook.add_format(bordered_bold)
       
    ###############
    # SUMMARY PAGE
    ###############

    summary = workbook.add_worksheet("summary")

    current_row = 0
    summary.write_row current_row+=1, 1, [ "Charge Set", "Budget/PO", "Cost" ], bordered
    charge_sets = ChargeSet.find(:all, :conditions => [ "charge_period_id = ?", @period.id ],
		                         :order => "name ASC")
    grand_total = 0
    for set in charge_sets
      grand_total = set.total_cost
      summary.write_row current_row+=1, 1, [ set.name, set.budget,
        fmt_dollars(set.total_cost) ], bordered
    end
    
    # totals
    summary.write_row current_row+=2, 2, [ "TOTALS",
      fmt_dollars(grand_total) ], bordered_bold
    
    ############### 
    # DETAIL PAGES
    ###############

    detail = Hash.new(0)
    for set in charge_sets
      detail[set.name] = workbook.add_worksheet(set.name)
      
      # print heading and charge set / project info
      row = 2
      detail[set.name].write row+=1, 1, SiteConfig.organization_name
      detail[set.name].write row+=1, 1, SiteConfig.facility_name

      detail[set.name].write row+=3, 1, "Project: " + set.name
      if set.charge_method == "internal"
        detail[set.name].write row+=1, 1, "Org Key: " + set.budget
        detail[set.name].write row+=1, 1, "Budget Manager: " + set.budget_manager
        detail[set.name].write row+=1, 1, "Budget Manager Approval: _________________________________"
      else
        detail[set.name].write row+=1, 1, "P.O. Number: " + set.budget
      end
      
      # charge headings
      detail[set.name].write row+=3, 1, [ "Date", "Description", "Cost" ], bordered
                     
      # print line item charges      
      charges = Charge.find(:all, :conditions => ["charge_set_id = ?", set.id], :order => "date ASC")     
      total = 0;
      for charge in charges
        total = total + charge.cost
        detail[set.name].write row+=1, 1, [ charge.date.to_s, charge.description,
          fmt_dollars(charge.cost) ], bordered
      end
    
      # totals
      detail[set.name].write row+=1, 2, [ "TOTAL", fmt_dollars(total) ], bordered_bold
    end
    workbook.close
    
    send_file workbook_name
  end
  
  private
  def fmt_dollars(amt)
    sprintf("$%0.2f", amt)
  end
end
