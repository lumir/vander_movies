require "open-uri"
namespace :movie do
  desc "feed movies"
  task :get_movies => :environment do
    counter = 0
    ["A","B","C","D","E","F","G","H","I","J-K","L","M","N-O","P","Q-R","S","T","U-W","X-Z"].each do |letter|
      url = "http://wikipedia.org/wiki/List_of_films:_#{letter}"
      doc = Nokogiri::HTML(open(url))
      doc.css(".mw-redirect").each do |movie_link|
        p movie_link.text
        counter += 1
        p counter
      end
    end
  end
end