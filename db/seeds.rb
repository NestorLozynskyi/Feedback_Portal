# Development / demo seeds. Idempotent: users and categories are upserted by email/name;
# demo suggestions, comments and votes are created only when there are no suggestions yet.
# Reset everything with `bin/rails db:seed:replant`.
#
# The single admin comes from ADMIN_EMAIL / ADMIN_PASSWORD / ADMIN_NAME
# (defaults: alex.kim@example.com / password123 / Alex Kim). See README.

PASSWORD = ENV.fetch("SEED_PASSWORD", "password123")

def seed_user(email:, name:, joined:, hue:, password: PASSWORD, admin: false, blocked: false)
  user = User.find_or_initialize_by(email_address: email.downcase)
  user.assign_attributes(name: name, admin: admin, blocked: blocked, avatar_hue: hue)
  user.password = password if user.new_record?
  user.created_at = Time.zone.parse(joined) if user.new_record?
  user.save!
  user
end

admin_email = ENV.fetch("ADMIN_EMAIL", "alex.kim@example.com").strip.downcase
# Only one admin: a changed ADMIN_EMAIL takes the role over.
User.where(admin: true).where.not(email_address: admin_email).update_all(admin: false)
admin = seed_user(
  email: admin_email,
  name: ENV.fetch("ADMIN_NAME", "Alex Kim"),
  password: ENV.fetch("ADMIN_PASSWORD", PASSWORD),
  joined: "2025-11-02", hue: 4, admin: true
)
users = {
  admin: admin,
  maya: seed_user(email: "maya.chen@example.com", name: "Maya Chen", joined: "2026-02-14", hue: 0),
  priya: seed_user(email: "priya.nair@example.com", name: "Priya Nair", joined: "2026-01-09", hue: 3),
  sam: seed_user(email: "sam.patel@example.com", name: "Sam Patel", joined: "2026-03-21", hue: 1),
  jordan: seed_user(email: "jordan.lee@example.com", name: "Jordan Lee", joined: "2026-04-02", hue: 2, blocked: true),
  elena: seed_user(email: "elena.rossi@example.com", name: "Elena Rossi", joined: "2026-05-17", hue: 5),
  tom: seed_user(email: "tom.becker@example.com", name: "Tom Becker", joined: "2026-03-30", hue: 1),
  aiko: seed_user(email: "aiko.tanaka@example.com", name: "Aiko Tanaka", joined: "2026-06-08", hue: 3)
}

categories = %w[UI/UX Performance Security Integrations].to_h do |name|
  [ name, Category.where("lower(name) = ?", name.downcase).first || Category.create!(name: name) ]
end

if Suggestion.none?
  # Stable ids for demo content (suggestion 1..12 in the order below).
  %w[suggestions comments votes].each { |t| ActiveRecord::Base.connection.reset_pk_sequence!(t) }
  at = ->(date) { Time.zone.parse("#{date} 10:00") }
  data = [
    [ :s1, "Dark mode for the mobile app", "feature", "UI/UX", "planned", :priya, "2026-09-14", false, 7, %i[sam jordan],
      "The desktop app already has a dark theme, but the iOS and Android apps are always light. I review boards late in the evening and the bright screen is hard on the eyes.\n\nIdeally the mobile app would follow the system appearance setting, with a manual override in Settings." ],
    [ :s2, "Two-way sync with Google Calendar", "feature", "Integrations", "in_progress", :elena, "2026-08-30", false, 6, %i[maya],
      "Tasks with due dates should appear in Google Calendar, and moving an event in the calendar should update the task’s due date.\n\nToday we copy dates by hand, so the two drift apart within a week." ],
    [ :s3, "Keyboard shortcuts for moving tasks between columns", "idea", "UI/UX", "under_review", :maya, "2026-10-29", false, 3, %i[priya],
      "When triaging a board I move dozens of tasks, and dragging each card is slow. Shortcuts like Shift + → to move the selected task to the next column would make triage much faster.\n\nA shortcut cheat sheet behind the ? key would help people discover them." ],
    [ :s4, "Board takes 8–10 seconds to load with about 500 tasks", "bug", "Performance", "in_progress", :sam, "2026-10-02", false, 6, %i[maya admin],
      "Steps: open a board with roughly 500 tasks across 6 columns.\n\nExpected: the board is usable within a couple of seconds. Actual: the board stays blank for 8–10 seconds in Chrome on a 2023 MacBook Air. Smaller boards load quickly." ],
    [ :s5, "Require two-factor authentication for workspace admins", "feature", "Security", "completed", :jordan, "2026-06-18", false, 5, [],
      "Workspace owners should be able to make two-factor authentication mandatory for everyone with admin rights. Our security review requires it." ],
    [ :s6, "Slack notification when a task is assigned to me", "feature", "Integrations", "completed", :tom, "2026-05-22", false, 5, %i[jordan],
      "I live in Slack during the day. A direct message when someone assigns me a task would mean I stop missing new work." ],
    [ :s7, "Pin a comment to the top of a task", "idea", "UI/UX", "under_review", :maya, "2026-11-03", true, 1, [],
      "Long discussions bury the final decision. Pinning one comment to the top of a task would keep the outcome visible to everyone who opens it later." ],
    [ :s8, "Export a board to CSV", "feature", "Integrations", "planned", :aiko, "2026-09-05", false, 4, [],
      "We report progress to clients in spreadsheets. A CSV export with title, column, assignee, due date and labels would save us an hour every week." ],
    [ :s9, "Session expires while writing a long comment", "bug", "Security", "under_review", :elena, "2026-10-21", false, 2, [],
      "If I spend more than about 30 minutes writing a comment, I’m signed out when I press Save and the text is lost.\n\nKeeping a local draft, or refreshing the session while I type, would fix it." ],
    [ :s10, "Offline mode for the desktop app", "idea", "Performance", "declined", :tom, "2026-04-11", false, 4, [],
      "I often work on trains with patchy Wi-Fi. Being able to view and edit tasks offline, with changes syncing later, would help a lot." ],
    [ :s11, "Bulk edit due dates", "idea", "UI/UX", "planned", :priya, "2026-10-10", false, 3, [],
      "When a project slips, I have to change due dates one task at a time. Selecting several tasks and shifting their dates together would save a lot of clicks." ],
    [ :s12, "Single sign-on with Okta", "feature", "Security", "under_review", :aiko, "2026-10-25", false, 2, [],
      "Our IT team requires SSO for every tool we use. Okta support would let us roll it out to the whole company." ]
  ]
  fill_order = %i[admin maya priya sam elena tom aiko jordan]
  suggestions = {}
  data.each do |key, title, kind, cat, status, author, date, hidden, votes, voters, body|
    s = Suggestion.create!(title: title, kind: kind, category: categories.fetch(cat), status: status, author: users.fetch(author),
                           hidden: hidden, body: body, created_at: at.(date), updated_at: at.(date))
    chosen = voters.dup
    fill_order.each { |u| chosen << u if chosen.size < votes && !chosen.include?(u) && u != author && u != :maya }
    chosen.first(votes).each { |u| Vote.create!(user: users.fetch(u), suggestion: s, created_at: at.(date)) }
    suggestions[key] = s
  end

  [
    [ :s1, :sam, "2026-09-15", "Same here. Following the system setting would be perfect — my phone switches to dark mode at sunset.", false, false ],
    [ :s1, :admin, "2026-09-20", "Thanks for all the votes! This is planned for an upcoming mobile release. We’ll post an update here when it’s ready to try.", false, false ],
    [ :s1, :maya, "2026-09-22", "Please make sure label colors stay readable in dark mode — our team relies on them a lot.", false, false ],
    [ :s1, :jordan, "2026-09-25", "An option for true black backgrounds would be great on OLED screens.", false, false ],
    [ :s1, :tom, "2026-09-28", "Check out my productivity course, link in my profile!", true, false ],
    [ :s1, :maya, "2026-10-01", "Honestly, whoever approved a light-only mobile app never used it at night.", true, false ],
    [ :s3, :priya, "2026-10-30", "Yes please. J and K to move between tasks would be a nice bonus.", false, false ],
    [ :s3, :maya, "2026-10-31", "Good idea. Making shortcuts remappable would cover both styles.", false, true ],
    [ :s2, :admin, "2026-10-15", "We’ve started on this. First comes one-way sync of due dates into Google Calendar, then updates in both directions.", false, false ],
    [ :s5, :sam, "2026-07-01", "Turned it on for our workspace today. Thanks, team!", false, false ],
    [ :s7, :priya, "2026-11-04", "Isn’t this the same as highlighting the decision in a task?", false, false ],
    [ :s4, :maya, "2026-10-04", "Seeing the same with about 400 tasks in Safari.", false, false ],
    [ :s5, :jordan, "2026-07-02", "Thank you! This unblocked our security review.", false, false ]
  ].each do |key, author, date, body, hidden, edited|
    Comment.create!(suggestion: suggestions.fetch(key), author: users.fetch(author), body: body, hidden: hidden,
                    created_at: at.(date), updated_at: at.(date), edited_at: (edited ? at.(date) + 1.hour : nil))
  end
end

puts "Seeded #{User.count} users (admin: #{admin.email_address}), #{Category.count} categories, #{Suggestion.count} suggestions."
