# frozen_string_literal: true

require "securerandom"

module ActiveStorage::Streaming
  DEFAULT_BLOB_STREAMING_DISPOSITION = "inline"

  include ActionController::Live

  private
    # Stream the blob from storage directly to the response. The disposition can be controlled by setting +disposition+.
    # The content type and filename is set directly from the +blob+.
    def send_blob_stream(blob, disposition: nil) #:doc:
      send_stream(
          filename: blob.filename.sanitized,
          disposition: blob.forced_disposition_for_serving || disposition || DEFAULT_BLOB_STREAMING_DISPOSITION,
          type: blob.content_type_for_serving) do |stream|
        blob.download do |chunk|
          stream.write chunk
        end
      end
    end

    # Stream the blob in byte ranges specified through the header
    def send_ranged_blob_stream(blob, range_header, disposition: nil) #:doc:
      send_stream(
          filename: blob.filename.sanitized,
          disposition: blob.forced_disposition_for_serving || disposition || DEFAULT_BLOB_STREAMING_DISPOSITION,
          type: blob.content_type_for_serving) do |stream|
        ranges = Rack::Utils.get_byte_ranges(range_header, blob.byte_size)

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
          boundary = SecureRandom.hex
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
      end
    end
end
