FactoryGirl.define do
  
  factory(:contact, :class => Testing::Contact) do
    sequence(:id){|n| n }
    firstname { ["Jobn", "Bob", "Raymond", "Juliet", "Lucy"].sample }
    lastname { ["Urgo", "Damon", "Marius", "Ton"].sample }
    etag{ SecureRandom.hex(8) }
  end
  
end
