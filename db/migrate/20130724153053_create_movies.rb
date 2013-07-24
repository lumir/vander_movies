class CreateMovies < ActiveRecord::Migration
  def change
    create_table :movies do |t|
      t.string  :title  
      t.string  :genres    
      t.string  :poster  
      t.string  :trailer
      t.string  :director
      t.text  :synopsis
      t.string  :score        
      t.string  :imdb_id
      t.string  :time_duration   
      t.string  :year
      t.string  :actors
      t.string  :title    
      t.timestamps
    end
  end
end
