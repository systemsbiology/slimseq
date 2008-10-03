require 'digest/sha1'

class User < ActiveRecord::Base

  #########################
  # RESTful authentication
  #########################
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password
  attr_accessor :password_confirmation

  validates_presence_of     :login, :email, :firstname, :lastname
  validates_presence_of     :password_confirmation,      :if => :password_present?
  validates_confirmation_of :password,                   :if => :password_present?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  validate :unique_combination_of_firstname_and_lastname
  before_save :encrypt_password, :set_role
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation,
    :role, :firstname, :lastname

  def unique_combination_of_firstname_and_lastname
    same_name_users = User.find(:all,
                      :conditions => ["firstname = ? AND lastname = ?",
                      firstname, lastname])
    # don't count the current user
    if( same_name_users.include?(self) )
      same_name_users.delete(self)
    end
    if( same_name_users.size > 0 )
      errors.add("This name is already in use")
    end
  end
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    if( u && u.authenticated?(password) )
      return u
    elsif(u)
      # if regular authentication failed, try via LDAP if that's an option
      if(SiteConfig.use_LDAP? && u.authenticated_LDAP?(password))
        return u
      end
    else
      return nil
    end
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    # make this the same as with LoginEngine so that existing crypted passwords
    # are preserved
    hashed_password = Digest::SHA1.hexdigest("#{AUTHENTICATION_SALT}--#{password}--}")[0..39]
    Digest::SHA1.hexdigest("#{AUTHENTICATION_SALT}--#{salt+hashed_password}--}")[0..39]
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def authenticated_LDAP?(password)
    begin
      require 'ldap'
    rescue LoadError
      # TODO: Should do something here to let the user know
      # LDAP isn't working
    end

    # if login exists, grab first and last name for LDAP table
    full_name = "#{firstname} #{lastname}"

    # Try to find use in LDAP
    conn = LDAP::Conn.new(SiteConfig.LDAP_server, 389)
    conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
    begin
      full_dn = "cn=#{full_name}," + SiteConfig.LDAP_DN
      conn.bind(full_dn, password)
      return true
    rescue
      return false
    end
  end
  
  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def set_role
      if(self.role == nil)
        self.role = 'customer'
      end
    end
       
    def password_required?
      crypted_password.blank? || !password.blank?
    end
    
    def password_present?
      !password.blank?
    end

  #########################
  # SLIMseq-specific
  #########################

public
    
  has_many :lab_memberships, :dependent => :destroy
  has_many :lab_groups, :through => :lab_memberships
  has_many :samples, :foreign_key => "submitted_by_id"
  belongs_to :naming_scheme, :foreign_key => "current_naming_scheme_id"

  # Returns the full name of this user.
  def fullname
    "#{self.firstname} #{self.lastname}"
  end
  
  def staff_or_admin?
    role == "staff" || role == "admin"
  end
  
  def admin?
    role == "admin"
  end
  
  # Returns an Array of the ids of quality traces the user has access to
  def get_lab_group_ids
    @lab_groups = accessible_lab_groups
    
    # gather ids of user's lab groups
    lab_group_ids = Array.new
    for lab_group in @lab_groups
      lab_group_ids << lab_group.id
    end
    lab_group_ids.flatten
    
    return lab_group_ids
  end
  
  def accessible_lab_groups
    # Administrators and staff can see all projects, otherwise users
    # are restricted to seeing only projects for lab groups they belong to
    if(self.staff_or_admin?)
      return LabGroup.find(:all, :order => "name ASC")
    else
      return self.lab_groups
    end
  end  
end