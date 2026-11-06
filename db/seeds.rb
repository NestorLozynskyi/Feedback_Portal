# Idempotent development seeds. Credentials are documented in README.md.
User.find_or_create_by!(email_address: "test@example.com") do |user|
  user.password = "password123"
end
