module ApplicationHelper
  def product_name
    Rails.configuration.x.product_name
  end

  def current_user
    Current.user
  end

  def page_title(title = nil)
    [ title, product_name ].compact.join(" — ")
  end

  def fmt_date(time)
    time&.strftime("%b %-d, %Y")
  end

  def plural_count(count, singular, plural = nil)
    "#{count} #{count == 1 ? singular : (plural || singular.pluralize)}"
  end

  def avatar(user, extra = nil)
    tag.span(user.initials, class: [ "avatar", "av-#{user.avatar_hue}", extra ].compact.join(" "), aria: { hidden: true })
  end

  def status_badge(status, big: false)
    info = Suggestion::STATUSES.fetch(status.to_s)
    tag.span(class: [ "badge", "status--#{info[:css]}", ("badge-lg" if big) ].compact.join(" ")) do
      tag.span(class: "dot", aria: { hidden: true }) + info[:label]
    end
  end

  def kind_chip(suggestion)
    tag.span(icon(suggestion.kind_icon) + suggestion.kind_label, class: "chip")
  end

  def category_chip(suggestion)
    tag.span(icon(:tag) + suggestion.category_name, class: "chip")
  end

  def hidden_badge
    tag.span(icon(:eye_off) + "Hidden by moderator", class: "badge badge-hidden")
  end

  def paragraphs(text_parts)
    safe_join(text_parts.map { |p| tag.p(p) })
  end

  # Sign-in link that explains why (vote|comment|create|admin) and returns here afterwards.
  def signin_path_for(reason, return_to: request.fullpath)
    new_session_path(reason: reason, return_to: return_to)
  end

  def signup_path_with_return(return_to: request.fullpath)
    new_registration_path(return_to: return_to)
  end

  def restricted?
    current_user&.blocked?
  end

  def restricted_describedby
    restricted? ? "restricted-text" : nil
  end

  def nav_link(label, path, active)
    link_to label, path, class: "nav-link", aria: { current: (active ? "page" : nil) }
  end

  def empty_state(icon_name, title, text, heading: :h2, &block)
    tag.div(class: "empty-state") do
      safe_join([
        tag.div(icon(icon_name), class: "empty-icon"),
        content_tag(heading, title, class: "empty-title"),
        tag.p(text, class: "empty-text"),
        (capture(&block) if block)
      ].compact)
    end
  end
end
