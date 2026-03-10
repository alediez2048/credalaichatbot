# frozen_string_literal: true

pin "application"
# After `bundle install`, run `bin/rails importmap:install` if turbo/stimulus pins are missing
pin "@hotwired/turbo-rails", to: "turbo.min.js"
