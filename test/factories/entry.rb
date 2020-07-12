FactoryBot.define do
  factory :entry do
    notebook { "test" }
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraphs.join("\n\n") }
    occurred_at { (rand * 10).to_i.minutes.ago }

    trait :calendar do
      kind { "calendar" }
    end

    trait :bookmark do
      url { Faker::Internet.url(host: "example.com") }
      kind { "pinboard" }
    end
  end
end
