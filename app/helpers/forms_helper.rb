# Form markup matching the mockup field component (label, hint, control, inline error)
# plus the error summary. Client validation (validation_controller.js) uses the same messages.
module FormsHelper
  def field_error_id(id) = "#{id}-error"

  def error_text(id, message)
    tag.p(id: field_error_id(id), class: "error-text", hidden: message.blank?) do
      message.present? ? icon(:alert) + tag.span(message) : ""
    end
  end

  def required_mark
    tag.span("*", class: "req", aria: { hidden: true })
  end

  # errors: [[field_id, message], ...]
  def error_summary(errors)
    tag.div(data: { validation_target: "summary" }) do
      next "" if errors.blank?
      title = errors.size == 1 ? "There’s 1 problem to fix" : "There are #{errors.size} problems to fix"
      tag.div(class: "error-summary", role: "alert", tabindex: "-1", data: { controller: "autofocus" }) do
        tag.h2(title, class: "error-summary-title") +
          tag.ul { safe_join(errors.map { |id, msg| tag.li(link_to(msg, "##{id}", data: { action: "validation#focusField", field: id })) }) }
      end
    end
  end

  # Generic text/email/password/textarea field.
  # rules: data attributes consumed by validation_controller.js
  def form_field(id:, name:, label:, value: nil, type: :text, error: nil, hint: nil, aside: nil, required: true,
                 autocomplete: nil, maxlength: nil, rows: 4, rules: {}, input_data: {})
    described = [ (hint ? "#{id}-hint" : nil), field_error_id(id) ].compact.join(" ")
    label_html = label_tag(id, safe_join([ label, (required ? " ".html_safe + required_mark : nil) ].compact), class: "label")
    head = aside ? tag.div(label_html + aside, class: "label-row") : label_html
    attrs = { id: id, required: required, aria: { required: (required || nil), describedby: described, invalid: (error.present? ? "true" : nil) },
              autocomplete: autocomplete, maxlength: maxlength, data: input_data.merge(validation_target: "input", rules: rules.to_json) }
    control =
      case type
      when :textarea
        text_area_tag(name, value, attrs.merge(class: "textarea", rows: rows))
      when :password
        tag.div(class: "input-wrap", data: { controller: "password-toggle" }) do
          password_field_tag(name, nil, attrs.merge(class: "input", data: attrs[:data].merge(password_toggle_target: "input"))) +
            tag.button("Show", class: "pw-toggle", type: "button", aria: { pressed: "false", label: "Show password" },
                       data: { action: "password-toggle#toggle", password_toggle_target: "button" })
        end
      else
        tag.input(**attrs.merge(type: type, name: name, value: value, class: "input"))
      end
    tag.div(class: [ "field", ("is-invalid" if error.present?) ].compact.join(" "), data: { field: id }) do
      safe_join([ head, (tag.p(hint, class: "hint", id: "#{id}-hint") if hint), control, error_text(id, error) ].compact)
    end
  end
end
