# Product name shown in the UI (header, page titles, auth texts).
# The real name is not decided yet; override with PRODUCT_NAME.
Rails.application.config.x.product_name = ENV.fetch("PRODUCT_NAME", "Feedback Portal").presence || "Feedback Portal"
