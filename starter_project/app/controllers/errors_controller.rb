# frozen_string_literal: true

# Controller for handling application errors (404, 500, etc.)
class ErrorsController < ApplicationController
  # Skip CSRF token verification for error pages
  skip_before_action :verify_authenticity_token

  def not_found
    # Log 404 errors for monitoring (but don't log health checks or common bot paths)
    unless request.path.start_with?("/up", "/favicon", "/robots", "/assets")
      Rails.logger.warn("404 Not Found: #{request.method} #{request.path} from #{request.remote_ip}")
    end

    respond_to do |format|
      format.html { render status: :not_found, layout: "application" }
      format.json { render json: { error: "Not found" }, status: :not_found }
      format.all { render status: :not_found, body: nil }
    end
  end
end
