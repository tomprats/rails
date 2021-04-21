# frozen_string_literal: true

# Proxy files through application. This avoids having a redirect and makes files easier to cache.
class ActiveStorage::Blobs::ProxyController < ActiveStorage::BaseController
  include ActiveStorage::SetBlob

  def show
    if request.headers["HTTP_RANGE"].present?
      response.headers["Accept-Ranges"] = "bytes"
      response.headers["Content-Length"] = @blob.byte_size

      send_ranged_blob_stream @blob, request.headers["HTTP_RANGE"]
    else
      http_cache_forever public: true do
        response.headers["Accept-Ranges"] = "bytes"
        response.headers["Content-Length"] = @blob.byte_size

        send_blob_stream @blob
      end
    end
  end
end
