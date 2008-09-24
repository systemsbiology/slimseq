class AddBioanalyzerPdf < ActiveRecord::Migration
  def self.up
    add_column :bioanalyzer_runs, :pdf_path, :string
  end

  def self.down
    remove_column :bioanalyzer_runs, :pdf_path
  end
end
