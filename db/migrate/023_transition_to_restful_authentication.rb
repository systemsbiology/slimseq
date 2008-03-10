class TransitionToRestfulAuthentication < ActiveRecord::Migration
  def self.up
    # change columns to match restful authentication controllers/models
    rename_column :users, :salted_password, :crypted_password
    rename_column :users, :security_token, :remember_token
    rename_column :users, :token_expiry, :remember_token_expires_at

    # get rid of unwanted columns
    remove_column :users, :verified
    remove_column :users, :logged_in_at
    remove_column :users, :deleted
    remove_column :users, :delete_after
    
    # add a column for a user's role
    add_column :users, :name, :string, :default => 'customer'
  end

  def self.down
    fail "Migration #23 is irreversible"
  end
end
