class Customer < ApplicationRecord
  attr_accessor :remember_token, :activation_token, :reset_token
  has_many :jobs, dependent: :destroy
  #attr_accessor :remember_token, :activation_token
  before_save   :downcase_email
  before_create :create_activation_digest

	before_save { self.userName = userName.downcase }
  	validates :lastName,  presence: true, length: { maximum: 50 }
 	  validates :firstName,  presence: true, length: { maximum: 50 }
  	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  	validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX }, uniqueness: true
    has_secure_password
    validates :userName, presence: true, length: { maximum: 255},
    				uniqueness: true
    validates :password, presence: true, length: { minimum: 6 }, allow_nil: true


            # Returns the hash digest of the given string.
  def Customer.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end
    # Returns true if the given token matches the digest.


  # Returns a random token.
  def Customer.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = Customer.new_token
    update_attribute(:remember_digest, Customer.digest(remember_token))
  end

    def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

    # Activates an account.
  def activate
    update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end

    # Sends activation email.
  def send_activation_email
    CustomerMailer.customer_account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = Customer.new_token
    update_attribute(:reset_digest,  Customer.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  # Sends password reset email.
  def send_password_reset_email
    CustomerMailer.customer_password_reset(self).deliver_now
  end
  
  # Returns true if a password reset has expired.
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end
  
  # Defines a proto-feed.
  # See "Following users" for the full implementation.
  def feed
    Job.where("customer_id = ?", id)
  end

  private

    # Converts email to all lower-case.
    def downcase_email
      self.email = email.downcase
    end

    # Creates and assigns the activation token and digest.
    def create_activation_digest
      self.activation_token  = Customer.new_token
      self.activation_digest = Customer.digest(activation_token)
    end
end
