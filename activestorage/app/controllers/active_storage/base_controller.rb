# frozen_string_literal: true

# The base class for all Active Storage controllers.
class ActiveStorage::BaseController < ActionController::Base
  include ActiveStorage::SetCurrent

  protect_from_forgery with: :exception

  self.etag_with_template_digest = false

  private
    def stream_chunk(blob)
      range = Rack::Utils.get_byte_ranges(request.headers["HTTP_RANGE"], blob.byte_size).first
      chunk = blob.download_chunk range

      response.header["Content-Range"] = "bytes #{range.begin}-#{range.end}/#{blob.byte_size}"
      response.status = 206
      response.stream.write chunk
    ensure
      response.stream.close
    end

    def stream(blob)
      blob.download do |chunk|
        response.stream.write chunk
      end
    ensure
      response.stream.close
    end
end
