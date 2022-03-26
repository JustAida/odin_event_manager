require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "time"
require "date"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislator_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number = phone_number.chars.select { |num| num.to_i.to_s == num }.join("")

  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == "1"
    phone_number[1..-1]
  else
    "Invalid phone number."
  end
end

def most_register_times(counter)
  highest_count = counter.sort_by { |_, v| v }.reverse[0][1]
  most_register_times = counter.select { |_, v| v == highest_count }
  most_register_times.map { |time| time[0] }
end

puts "EventManager Initialized."

contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol
)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter
hours_counter = Hash.new(0)
days_counter = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislator_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  # Assignment: Clean Phone Numbers
  phone_number = clean_phone_number(row[:homephone])
  puts "#{name} #{phone_number}"

  register_time = Time.strptime(row[:regdate], "%D %H:%M")
  register_hour = register_time.hour
  hours_counter[register_hour] += 1

  register_date = Date.strptime(row[:regdate].split[0], "%D")
  # 0 is Sunday.
  day_of_the_week = register_date.wday
  days_counter[day_of_the_week] += 1
end

# Assignment: Time Targeting
most_register_hours = most_register_times(hours_counter)
puts "We should run more ads during these hours: #{most_register_hours.join(", ")}."

# Assignment: Day of the Week Targeting
most_register_days = most_register_times(days_counter).map do |day|
  Date::DAYNAMES[day.to_i]
end
puts "We should run more ads during these days: #{most_register_days.join(", ")}."
