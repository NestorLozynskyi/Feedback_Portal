module Admin
  class BaseController < ApplicationController
    allow_unauthenticated_access
    before_action :require_admin
  end
end
