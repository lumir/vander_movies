class MoviesController < ApplicationController
  # GET /movies
  # GET /movies.json
  def index
    @movies = Movie.all

    render json: @movies
  end

  # GET /movies/1
  # GET /movies/1.json
  def show
    @movie = Movie.find_by_imdb_id(params[:id])    
    render json: @movie
  end

  def search
    @movies = Movie.search(params[:q])    
    render json: @movies
  end

end
