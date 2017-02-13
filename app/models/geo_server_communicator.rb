class GeoServerCommunicator
  attr_reader :request

  def initialize
    @username, @password = ENV["ACCESS_CREDENTIALS"].split(':')
    @request = nil
  end

  def get_resource(url:, path_to_collection: nil)
    perform_http_request(url: url) do |request|
      request.perform
      json = JSON.parse(request.body)
      path_to_collection ? json[path_to_collection] : json
    end
  end

  def post_resource(url: , data: )
    perform_http_request(url: url) do |request|
      request.http_post(JSON.pretty_generate(data))
      request
    end
  end

  def delete_resource(url: )
    perform_http_request(url: url) do |request|
      request.http_delete
      request
    end
  end

  private

  def perform_http_request(url:)
    request = create_request(url)
    configured_request = setup_request(request)
    yield configured_request
  rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
    log_error_info(error: e, url: url)
    Curl::Easy.new
  end

  def create_request(url)
    @request = Curl::Easy.new(url)
  end

  def setup_request(request)
    request.headers['Accept'] = 'application/json'
    request.headers['Content-Type'] = 'application/json'
    request.http_auth_types = :basic
    request.username = @username
    request.password = @password
    request
  end

  def log_error_info(error:, url:)
    Rails::logger.error(error.message)
    Rails::logger.error(error.backtrace.join("\n"))
    Resque::logger.error(url)
    Resque::logger.error(error.message)
  end
end
