# coding: utf-8
class User
  module OmniauthCallbacks
    ['weibo', 'douban'].each do |provider|
      define_method "find_or_create_for_#{provider}" do |response|
        uid = response["uid"]
        data = response["info"]
        credentials = response['credentials']

        if user = User.where("authorizations.provider" => provider , "authorizations.uid" => uid).first
          user
        elsif data['email'].present? and user = User.find_by_email(data["email"])
          user.bind_service(response)
          user
        else
          user = User.new_from_provider_data(provider, uid, data)

          if user.save(:validate => false)
            user.authorizations << Authorization.new(:provider => provider, :uid => uid,
                                                     :token => credentials['token'],
                                                     :secret => credentials['secret'])
            return user
          else
            Rails.logger.warn("User.create_from_hash 失败，#{user.errors.inspect}")
            return nil
          end
        end
      end
    end

    def new_from_provider_data(provider, uid, data)
      User.new do |user|
        user.email = data["email"] || "#{provider}+#{uid}@example.com"
        user.name = data['name']
        user.login = data["nickname"].gsub(/[^#{User::LOGIN_FORMATTING}]/, "_")

        if User.where(:login => user.login).count > 0 || user.login.blank?
          user.login = "u#{Time.now.to_i}" # TODO: possibly duplicated user login here. What should we do?
        end

        user.remote_avatar_url = convert_image_url(provider, data['image'])
        user.password = Devise.friendly_token[0, 20]
        user.location = data["location"]
        user.tagline = data["description"]
      end
    end

    private

      # hack image size from 50x50 to the large one(180x180)
      def convert_image_url(provider, url)
        if provider == 'weibo'
          url && url.gsub!(/\/50\//, '/180/') << '.jpg'
        elsif provider == 'douban'
          url && url.gsub!(/\/icon\/u/, '/icon/ul')
        end
        url
      end

  end
end
