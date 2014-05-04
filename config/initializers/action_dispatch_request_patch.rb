module ActionDispatch
  class Request

    def original_request_url( username=nil, password=nil )
      logger.info { "Original URL was <#{ original_url }>." }
      # Split fullpath to remove querystring
      temp_path = original_url.include?('?') ? original_url.split('?')[0] : original_url
      
      # Add query string
      temp_path += '?' + query_parameters.to_hash unless query_parameters.empty?
      
      # Add username and password if they are defined
      unless username.blank?
        auth_string = username
        auth_string += ':'+password unless password.blank?
        temp_path.gsub!( /(https?:\/\/)/, '\1' + auth_string + '@' )
      end
      
      return temp_path
    end

  end
end