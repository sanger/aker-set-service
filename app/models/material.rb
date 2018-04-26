class Material

  def self.site
    Faraday.new(url: Rails.configuration.materials_service_url) do |faraday|
      ENV['HTTP_PROXY'] = nil
      ENV['http_proxy'] = nil
      ENV['https_proxy'] = nil
      faraday.proxy ''
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
      faraday.use ::RequestIdMiddleware
      if Rails.env.production? || Rails.env.staging?
        faraday.use ZipkinTracer::FaradayHandler, 'Materials service'
      end
    end
  end

  def self.valid?(uuids)
    puts "****** Validating materials:\n#{uuids}"
    response = Material.site.post do |req|
      req.url 'materials/validate'
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
      req.body = { materials: uuids }.to_json
    end

    puts "****** Material Validation Response: #{response.inspect}"
    response.body == 'ok'
  end

end
