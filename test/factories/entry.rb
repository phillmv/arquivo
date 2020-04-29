FactoryBot.define do
  factory :entry do
    body { Faker::Lorem.paragraphs.join("\n\n") }
    occurred_at { (rand * 10).to_i.minutes.ago }
  end
end
