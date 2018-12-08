class Customer < ApplicationRecord
  attr_accessor :remember_token, :activation_token, :reset_token
  has_many :microposts
  #attr_accessor :remember_token, :activation_token
  before_save   :downcase_email
  before_create :create_activation_digest

	before_save { self.userName = userName.downcase }
  	validates :lastName,  presence: true, length: { maximum: 50 }
 	validates :firstName,  presence: true, length: { maximum: 50 }
  	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  	validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX }
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
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Returns a random token.
  def Customer.new_token
    SecureRandom.urlsafe_base64
  end

  # Activates an account.
  def activate
    update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
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
