require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 

module LoginEngine
  module AuthenticatedUser

    def self.included(base)
      base.class_eval do

        # use the table name given
        set_table_name LoginEngine.config(:user_table)

        attr_accessor :new_password
      
        validates_presence_of :login
        validates_length_of :login, :within => 3..40
        validates_uniqueness_of :login
        validates_uniqueness_of :email
        validates_format_of :email, :with => /^[^@]+@.+$/

		# Disable requirement for a password. Lack of a password
		# indicates that LDAP should be used for authentication
        # validates_presence_of :password, :if => :validate_password?
        validates_confirmation_of :password, :if => :validate_password?
        # validates_length_of :password, { :minimum => 5, :if => :validate_password? }
        validates_length_of :password, { :maximum => 40, :if => :validate_password? }
  
        protected 
      
        attr_accessor :password, :password_confirmation
      
        after_save :falsify_new_password
        after_validation :crypt_password

      end
      base.extend(ClassMethods)
    end

    module ClassMethods
    
      # new authentication method to handle LDAP + salted login
      def authenticate(login, password)

        return nil if login.to_s.size == 0
        return nil if password.to_s.size == 0
    
        # look to see if this login exists
        user = find(:first, :conditions => ["login = ? AND verified = 1 AND deleted = 0", login])
        return nil if user.nil?
        
        # if a salted password exists, use it
        if user.salted_password.size > 0
          user = find(:first, :conditions => ["login = ? AND salted_password = ? AND verified = 1", 
                   login, AuthenticatedUser.salted_password(user.salt, AuthenticatedUser.hashed(password))])
          return user
        # if there's no salted password, try for LDAP
        elsif SiteConfig.use_LDAP?
          return authenticate_using_ldap(user, password)
        else   
          return nil
        end
      end

      def authenticate_using_ldap(user, password)
        # return nil (authentication failed) if ldap can't be loaded
        begin
          require 'ldap'
        rescue LoadError
          # TODO: Should do something here to let the user know
          # LDAP isn't working
        end

        # if login exists, grab first and last name for LDAP table
        full_name = "#{user.firstname} #{user.lastname}"
        
        # Try to find use in LDAP
        conn = LDAP::Conn.new(SiteConfig.LDAP_server, 389)
        conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
        begin
          full_dn = "cn=#{full_name}," + SiteConfig.LDAP_DN
          conn.bind(full_dn, password)
        rescue
          return nil
        end
    
        return user
      end
      
    end
  

    protected
    
      def self.hashed(str)
        # check if a salt has been set...
        if LoginEngine.config(:salt) == nil
          raise "You must define a :salt value in the configuration for the LoginEngine module."
        end
  
        return Digest::SHA1.hexdigest("#{LoginEngine.config(:salt)}--#{str}--}")[0..39]
      end
    
      def self.salted_password(salt, hashed_password)
        hashed(salt + hashed_password)
      end
    
    public
  
    # hmmm, how does this interact with the developer's own User model initialize?
    # We would have to *insist* that the User.initialize method called 'super'
    #
    def initialize(attributes = nil)
      super
      @new_password = false
    end

    def token_expired?
      self.security_token and self.token_expiry and (Time.now > self.token_expiry)
    end

    def update_expiry
      write_attribute('token_expiry', [self.token_expiry, Time.at(Time.now.to_i + 600 * 1000)].min)
      write_attribute('authenticated_by_token', true)
      write_attribute("verified", 1)
      update_without_callbacks
    end

    def generate_security_token(hours = nil)
      if not hours.nil? or self.security_token.nil? or self.token_expiry.nil? or 
          (Time.now.to_i + token_lifetime / 2) >= self.token_expiry.to_i
        return new_security_token(hours)
      else
        return self.security_token
      end
    end

    def set_delete_after
      hours = LoginEngine.config(:delayed_delete_days) * 24
      write_attribute('deleted', 1)
      write_attribute('delete_after', Time.at(Time.now.to_i + hours * 60 * 60))

      # Generate and return a token here, so that it expires at
      # the same time that the account deletion takes effect.
      return generate_security_token(hours)
    end

    def change_password(pass, confirm = nil)
      self.password = pass
      self.password_confirmation = confirm.nil? ? pass : confirm
      @new_password = true
    end
    
    protected

    def validate_password?
      @new_password
    end


    def crypt_password
      # only add salt if this is a new password that is not blank
      # blank password fields should be left alone, as these indicate that LDAP should be used to authenticate
      if @new_password && @password.size > 0
        write_attribute("salt", AuthenticatedUser.hashed("salt-#{Time.now}"))
        write_attribute("salted_password", AuthenticatedUser.salted_password(salt, AuthenticatedUser.hashed(@password)))
      end
    end

    def falsify_new_password
      @new_password = false
      true
    end

    def new_security_token(hours = nil)
      write_attribute('security_token', AuthenticatedUser.hashed(self.salted_password + Time.now.to_i.to_s + rand.to_s))
      write_attribute('token_expiry', Time.at(Time.now.to_i + token_lifetime(hours)))
      update_without_callbacks
      return self.security_token
    end

    def token_lifetime(hours = nil)
      if hours.nil?
        LoginEngine.config(:security_token_life_hours) * 60 * 60
      else
        hours * 60 * 60
      end
    end

  end
end
  
