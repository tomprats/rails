# frozen_string_literal: true

module ActiveStorage::SetHeaders #:nodoc:
  extend ActiveSupport::Concern

  private
    def set_content_headers_from(blob)
      response.headers["Accept-Ranges"] = "bytes"
      response.headers["Content-Type"] = blob.content_type_for_serving
      response.headers["Content-Length"] = blob.byte_size
      response.headers["Content-Disposition"] = ActionDispatch::Http::ContentDisposition.format \
        disposition: blob.forced_disposition_for_serving || params[:disposition] || "inline", filename: blob.filename.sanitized
    end
end
