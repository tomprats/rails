# frozen_string_literal: true

# The base class for all Active Storage controllers.
class ActiveStorage::BaseController < ActionController::Base
  include ActiveStorage::SetCurrent

  protect_from_forgery with: :exception

  self.etag_with_template_digest = false

  private
    def stream_chunk(blob)
      ranges = Rack::Utils.get_byte_ranges(request.headers["HTTP_RANGE"], blob.byte_size)

      if ranges.all?(&:blank?)
        response.status = 416
      elsif ranges.length == 1
        range = ranges.first
        chunk = blob.download_chunk(range)

        response.headers["Content-Length"] = chunk.length
        response.headers["Content-Range"] = "bytes #{range.begin}-#{range.end}/#{blob.byte_size}"
        response.status = 206
        response.stream.write chunk
      else
        boundary = "3d6b6a416f9b5"
        content_length = 0

        response.headers["Content-Type"] = "Content-Type: multipart/byteranges; boundary=#{boundary}"
        response.status = 206

        ranges.compact.each do |range|
          chunk = blob.download_chunk(range)
          content_length += chunk.length

          response.stream.write "--#{boundary}"
          response.stream.write "Content-Type: #{blob.content_type_for_serving}"
          response.stream.write "Content-Range: bytes #{range.begin}-#{range.end}/#{blob.byte_size}"
          response.stream.write chunk
        end

        response.stream.write "--#{boundary}--"
        response.headers["Content-Length"] = content_length
      end
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
