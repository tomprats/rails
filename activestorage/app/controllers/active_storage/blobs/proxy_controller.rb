# frozen_string_literal: true

# Proxy files through application. This avoids having a redirect and makes files easier to cache.
class ActiveStorage::Blobs::ProxyController < ActiveStorage::BaseController
  include ActiveStorage::SetBlob
  include ActiveStorage::SetHeaders

  def show
    if request.headers["HTTP_RANGE"].present?
      set_content_headers_from @blob
      stream_chunk @blob
    else
      http_cache_forever public: true do
        set_content_headers_from @blob
        stream @blob
      end
    end
  end
end
