# frozen_string_literal: true

require "rails_helper"

# Comprehensive tests for ErrorsController
# Tests cover 404 handling, logging, and response formats
RSpec.describe ErrorsController, type: :controller do
  describe "GET #not_found" do
    context "with HTML format" do
      it "returns 404 status" do
        get :not_found, params: { path: "invalid/path" }
        expect(response).to have_http_status(:not_found)
      end

      it "renders the not_found template" do
        get :not_found, params: { path: "invalid/path" }
        expect(response).to render_template(:not_found)
      end

      it "uses application layout" do
        get :not_found, params: { path: "invalid/path" }
        expect(response).to render_template(layout: "application")
      end

      it "logs the 404 error" do
        allow(Rails.logger).to receive(:warn)
        get :not_found, params: { path: "invalid/path" }
        expect(Rails.logger).to have_received(:warn).with(
          /404 Not Found: GET \/invalid\/path/
        )
      end

      it "does not log health check paths" do
        allow(Rails.logger).to receive(:warn)
        get :not_found, params: { path: "up" }
        expect(Rails.logger).not_to have_received(:warn)
      end

      it "does not log favicon requests" do
        allow(Rails.logger).to receive(:warn)
        get :not_found, params: { path: "favicon.ico" }
        expect(Rails.logger).not_to have_received(:warn)
      end

      it "does not log robots.txt requests" do
        allow(Rails.logger).to receive(:warn)
        get :not_found, params: { path: "robots.txt" }
        expect(Rails.logger).not_to have_received(:warn)
      end
    end

    context "with JSON format" do
      it "returns 404 status" do
        get :not_found, params: { path: "invalid/path" }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it "returns JSON error response" do
        get :not_found, params: { path: "invalid/path" }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Not found")
      end
    end

    context "with other formats" do
      it "returns 404 status with empty body" do
        get :not_found, params: { path: "invalid/path" }, format: :xml
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end
end
