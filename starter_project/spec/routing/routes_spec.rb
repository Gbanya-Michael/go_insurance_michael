# frozen_string_literal: true

require "rails_helper"

# Comprehensive routing tests
# Tests cover valid routes, 404 handling, and error scenarios
RSpec.describe "Routes", type: :routing do
  describe "Valid Routes" do
    it "routes root to quotes#new" do
      expect(get: "/").to route_to("quotes#new")
    end

    it "routes GET /quotes/new to quotes#new" do
      expect(get: "/quotes/new").to route_to("quotes#new")
    end

    it "routes POST /quotes to quotes#create" do
      expect(post: "/quotes").to route_to("quotes#create")
    end

    it "routes GET /quotes/:id to quotes#show" do
      expect(get: "/quotes/1").to route_to("quotes#show", id: "1")
    end

    it "routes PATCH /quotes/:id to quotes#update" do
      expect(patch: "/quotes/1").to route_to("quotes#update", id: "1")
    end

    it "routes PUT /quotes/:id to quotes#update" do
      expect(put: "/quotes/1").to route_to("quotes#update", id: "1")
    end

    it "routes GET /up to rails/health#show" do
      expect(get: "/up").to route_to("rails/health#show")
    end
  end

  describe "Invalid Routes - 404 Handling" do
    it "routes invalid paths to errors#not_found" do
      expect(get: "/invalid/path").to route_to("errors#not_found", path: "invalid/path")
    end

    it "routes typos in quotes path to errors#not_found" do
      expect(get: "/quotttes/20").to route_to("errors#not_found", path: "quotttes/20")
    end

    it "routes invalid quote paths to errors#not_found" do
      expect(get: "/quotes/invalid/extra").to route_to("errors#not_found", path: "quotes/invalid/extra")
    end

    it "routes POST to invalid paths to errors#not_found" do
      expect(post: "/invalid/path").to route_to("errors#not_found", path: "invalid/path")
    end

    it "routes PATCH to invalid paths to errors#not_found" do
      expect(patch: "/invalid/path").to route_to("errors#not_found", path: "invalid/path")
    end

    it "routes DELETE to invalid paths to errors#not_found" do
      expect(delete: "/invalid/path").to route_to("errors#not_found", path: "invalid/path")
    end
  end
end
