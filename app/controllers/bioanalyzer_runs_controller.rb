class BioanalyzerRunsController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    lab_group_ids = current_user.get_lab_group_ids
  
    # get the traces that the user has access to
    traces = QualityTrace.find( :all, :conditions => ["lab_group_id IN (?)", lab_group_ids] )

    # get unique bioanalyzer run ids from all traces
    bioanalyzer_run_ids = Array.new
    for trace in traces
      if( !bioanalyzer_run_ids.include?(trace.bioanalyzer_run_id) )
        bioanalyzer_run_ids << trace.bioanalyzer_run_id
      end
    end
    bioanalyzer_run_ids.flatten

    @bioanalyzer_run_pages, @bioanalyzer_runs = paginate :bioanalyzer_runs, 
                                                :per_page => 10, :order => "date DESC",
                                                :conditions => ["id IN (?)", bioanalyzer_run_ids]
  end

  def show
    @bioanalyzer_run = BioanalyzerRun.find(params[:id])
    
    
    @quality_traces = QualityTrace.find( :all, :conditions => ["bioanalyzer_run_id = ?", @bioanalyzer_run.id],
                                         :order => "number ASC" )
  end

  def pdf
    @bioanalyzer_run = BioanalyzerRun.find(params[:id])
    
    @quality_traces = QualityTrace.find( :all, :conditions => ["bioanalyzer_run_id = ?", @bioanalyzer_run.id],
                                         :order => "number ASC" )

    # create the PDF document  
    _pdf = PDF::Writer.new()

    # print page heading
    _pdf.select_font "Helvetica"
    _pdf.font_size = 16
    _pdf.text "Bioanalyzer Results, page 1\n\n", :justification => :center
    _pdf.font_size = 12
    _pdf.text "Name: " + @bioanalyzer_run.name + "\n" +
              "Date: " + @bioanalyzer_run.date.to_s + "\n\n", :justification => :left

    # go to two columns for traces
    _pdf.start_columns(2)
    _pdf.font_size = 10

    # going until size-2 keeps ladder from being shown
    for i in 0..@quality_traces.size-2
      # print page heading for new pages
      if(i==6)
        _pdf.stop_columns
        _pdf.start_new_page
            _pdf.select_font "Helvetica"
            _pdf.font_size = 16
            _pdf.text "Bioanalyzer Results, page 2\n\n", :justification => :center
            _pdf.font_size = 12
            _pdf.text "Name: " + @bioanalyzer_run.name + "\n" +
                      "Date: " + @bioanalyzer_run.date.to_s + "\n\n", :justification => :left
        _pdf.start_columns(2)
      end
     
      # output trace image
      image_file_path = "#{RAILS_ROOT}/public/" + @quality_traces[i].image_path
      _pdf.image image_file_path
      
      # output sample info
      sample_text = "Concentration =" + @quality_traces[i].concentration.to_i.to_s + "ng/uL\n"                    
      if( @quality_traces[i].sample_type == "total" )
        sample_text += "RIN=" + round_to(@quality_traces[i].quality_rating.to_f,2).to_s + "\n" +
                       "28S/18S ratio=" + round_to(@quality_traces[i].ribosomal_ratio.to_f,2).to_s + "\n"
      else
        sample_text += "\n\n"
      end

      _pdf.text sample_text, :justification => :center
    end
    
    # send file to browser
    pdf_file_name = @bioanalyzer_run.name + ".pdf"
    send_data _pdf.render, :filename => pdf_file_name,
                           :type => "application/pdf"
  end

  def destroy
    BioanalyzerRun.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  private
  def round_to(n,x)
    (n * 10**x).round.to_f / 10**x
  end
end
