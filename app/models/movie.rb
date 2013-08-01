class Movie < ActiveRecord::Base
  attr_accessible :title
  scope :by_title, lambda{ |b| where("movies.title ILIKE ?", "%#{b}%") }
  scope :by_director, lambda{ |b| where("movies.director ILIKE ?", "%#{b}%") }
  scope :by_genres, lambda{ |b| where("movies.genres ILIKE ?", "%#{b}%") }
  scope :by_year, lambda{ |b| where("movies.year ILIKE ?", "%#{b}%") }
  
  def self.search(search)
    movies = Movie.scoped
    movies = movies.by_title(search)
    # movies = movies.by_director(search)
    # movies = movies.by_genres(search)
    # movies = movies.by_year(search)
    movies
  end
end
