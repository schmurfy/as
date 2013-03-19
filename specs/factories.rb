FactoryGirl.define do
  
  factory(:contact, :class => Testing::Contact) do
    sequence(:id){|n| n }
    firstname { ["John", "Bob", "Raymond", "Juliet", "Lucy"].sample }
    lastname { ["Urgo", "Damon", "Marius", "Ton"].sample }
    company_name { ["TestCorp", "DummyCorp", "Test Inc."].sample }
    etag{ SecureRandom.hex(8) }
  end
  
end
