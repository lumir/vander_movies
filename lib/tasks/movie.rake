require "open-uri"
require 'uri'


namespace :movie do
  desc "feed movies"
  task :get_movies => :environment do    
    s3 = AWS::S3.new(:access_key_id => 'AKIAJINPR4ZEXQU2C5TA',:secret_access_key => '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')
    bucket = s3.buckets['modwedding']
    movies = []
    ["A","B","C","D","E","F","G","H","I","J-K","L","M","N-O","P","Q-R","S","T","U-W","X-Z"].each do |letter|
    #["A"].each_with_index do |letter, index|      
      url = "http://wikipedia.org/wiki/List_of_films:_#{letter}"
      doc = Nokogiri::HTML(open(url))
      doc.css('ul li i a').each_with_index do |movie_link, index|
        movies << movie_link.text# if index < 10
      end      
    end

    p movies

    imdb_ids = []
    found_movies = []
    movies.uniq.each do |movie|
      unless movie.blank?          
        unless found_movies.include?(movie)
          formated_name = movie.gsub(" ", "+").gsub("&", "%26")
          p "searching for... #{formated_name}"
          url = "http://imdbapi.org/?title=#{formated_name}&type=json&plot=full&episode=1&limit=1&yg=0&mt=none&lang=en-US&offset=&aka=simple&release=simple&business=0&tech=0"
          if valid?(url)
            response = HTTParty.get(url)        
            movie_data = JSON.parse(response.body).first                       
            if movie_data.class != Array && movie_data["year"].to_s == Date.today.year.to_s   
              p " match found!"
              imdb_ids << {movie_title: movie, source_id: movie_data["imdb_id"]}          
              found_movies << movie
            end
          end
          url = "http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=wpu84pt7hmm27y3qtw4734yq&q=#{formated_name}&page_limit=1"
          if valid?(url)
            response = HTTParty.get(url)        
            movie_data = JSON.parse(response.body)                        
            unless movie_data["total"] == 0 || movie_data["movies"].first["alternate_ids"].blank?
              p " match found!"
              imdb_ids << {movie_title: movie, source_id: "tt#{movie_data["movies"].first["alternate_ids"]["imdb"]}"}             
              found_movies << movie
            end
          end
          
        end
      end
    end
    existing_movies = Movie.all.collect(&:imdb_id)
    imdb_ids.uniq.each do |movie_package|
      url = "http://www.imdb.com/title/#{movie_package[:source_id]}/"
      doc = Nokogiri::HTML(open(url))      
      
      name = ""
      year = ""
      #name
      name = movie_package[:movie_title]
      doc.css(".header").each do |header_container|         
        #year        
        year = header_container.xpath('//span[@class="nobr"]/a').text        
      end
      p "parsing #{name} ..."
      #score
      score = ""
      doc.css(".star-box-giga-star").each do |start_container| 
        score = start_container.text        
        p score        
      end

      #poster
      poster = ""
      doc.css(".image").each do |image_container| 
        poster = image_container.xpath('//img[@itemprop="image"]/@src').first.value                
      end

      #director
      director = doc.xpath('//div[@itemprop="director"]/a/span').text      

      #synopsis
      sinopsis = doc.xpath('//div[@itemprop="description"]/p').text      

      #duration
      duration = doc.xpath('//time[@itemprop="duration"]').text

      #genre
      genre = doc.xpath('//span[@itemprop="genre"]').first.text              


      #resumen
      p "name : #{name}"
      p "director = #{director}"
      p "year : #{year}"
      p "score : #{score}"
      p "genre : #{genre}"
      p "poster  : #{poster}"
      # youtube_url = "http://www.youtube.com/results?search_query=trailer+#{name.gsub(" ", "+").gsub("&", "%26")}"
      # doc = Nokogiri::HTML(open(youtube_url))            
      # video_id = doc.xpath('//ol[@id="search-results"]/li/@data-context-item-id').first.value
      # trailer_url ="http://www.youtube.com/embed/#{video_id}"

      # p "trailer: #{trailer_url}"

      current_movie = Movie.find_by_imdb_id(movie_package[:source_id])
      if current_movie.blank?
        unless existing_movies.include?(movie_package[:source_id])

          p "saving... #{name}"
          current_movie = Movie.new()
          current_movie.title = name
          current_movie.genres = genre          
          current_movie.time_duration = "#{duration.split("min").last.to_i} min"
          current_movie.director = director
          current_movie.imdb_id = movie_package[:source_id]
          current_movie.year = year
          current_movie.score = score
          current_movie.synopsis = sinopsis        
          youtube_url = "http://www.youtube.com/results?search_query=trailer+#{current_movie.title.gsub(" ", "+").gsub("&", "%26")}"
          doc = Nokogiri::HTML(open(youtube_url))            
          video_id = doc.xpath('//ol[@id="search-results"]/li/@data-context-item-id').first.value
          trailer_url ="http://www.youtube.com/embed/#{video_id}"
          current_movie.trailer = trailer_url
          
          unless poster.blank?
            poster_url = poster
            source_image = open(poster_url)
            temp_image = Tempfile.new("tem_poster_#{name}")
            File.open(temp_image.path, 'wb') do |f|
              f.write source_image.read
            end
            s3_name = "fseat/#{name}.#{poster_url.split('.').last}"
            bucket.objects.create(s3_name, temp_image.read).acl = :public_read
            current_movie.poster = "http://s3.amazonaws.com/modwedding/#{s3_name}"
          end

          current_movie.save 
        end
      end
    end
  end
end


def valid?(url)
  uri = URI.parse(url)
  uri.kind_of?(URI::HTTP)
rescue URI::InvalidURIError
  false
end