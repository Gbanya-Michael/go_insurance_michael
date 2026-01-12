# frozen_string_literal: true

require "rails_helper"

# Request-level routing tests
# Tests actual HTTP requests to ensure routes work correctly
RSpec.describe "Route Requests", type: :request do
  describe "Valid Routes" do
    it "GET / returns 200" do
      get "/"
      expect(response).to have_http_status(:success)
    end

    it "GET /quotes redirects to root" do
      get "/quotes"
      expect(response).to redirect_to("/")
    end

    it "GET /quotes/new returns 200" do
      get "/quotes/new"
      expect(response).to have_http_status(:success)
    end

    it "GET /up returns 200" do
      get "/up"
      expect(response).to have_http_status(:success)
    end
  end

  describe "Invalid Routes - 404 Handling" do
    it "GET /invalid/path returns 404" do
      get "/invalid/path"
      expect(response).to have_http_status(:not_found)
    end

    it "GET /quotttes/20 returns 404" do
      get "/quotttes/20"
      expect(response).to have_http_status(:not_found)
    end

    it "POST /invalid/path returns 404" do
      post "/invalid/path"
      expect(response).to have_http_status(:not_found)
    end

    it "PATCH /invalid/path returns 404" do
      patch "/invalid/path"
      expect(response).to have_http_status(:not_found)
    end

    it "DELETE /invalid/path returns 404" do
      delete "/invalid/path"
      expect(response).to have_http_status(:not_found)
    end

    it "renders errors/not_found template for invalid routes" do
      get "/invalid/path"
      expect(response).to render_template("errors/not_found")
    end

    it "includes error message in response body" do
      get "/invalid/path"
      expect(response.body).to include("Page Not Found")
    end
  end

  describe "Quote Not Found" do
    it "GET /quotes/99999 returns 404" do
      get "/quotes/99999"
      expect(response).to have_http_status(:not_found)
    end

    it "renders errors/not_found template for non-existent quote" do
      get "/quotes/99999"
      expect(response).to render_template("errors/not_found")
    end

    it "PATCH /quotes/99999 returns 404" do
      patch "/quotes/99999", params: { quote: { cruise: true } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "JSON Format" do
    it "returns JSON error for invalid route" do
      get "/invalid/path", headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Not found")
    end
  end
end
