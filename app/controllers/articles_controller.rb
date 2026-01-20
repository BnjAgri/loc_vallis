class ArticlesController < ApplicationController
  def index
    @articles = Article.includes(:owner).order(created_at: :desc)
  end

  def show
    @article = Article.includes(:owner).find(params[:id])
  end
end
