class ArticlesController < ApplicationController
  before_action :require_owner!, only: %i[new create edit update destroy]
  before_action :set_owned_article, only: %i[edit update destroy]

  def index
    @articles = Article.includes(:owner).order(created_at: :desc)
  end

  def show
    @article = Article.includes(:owner).find(params[:id])
  end

  def new
    @article = Article.new
  end

  def create
    @article = current_owner.articles.new(article_params)

    if @article.save
      redirect_to @article, notice: t("articles.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @article.update(article_params)
      redirect_to @article, notice: t("articles.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy!
    redirect_to articles_path, notice: t("articles.destroy.success")
  end

  private

  def article_params
    params.require(:article).permit(:title, :content, :image_url, :image)
  end

  def require_owner!
    return if owner_signed_in?

    if user_signed_in?
      flash[:alert] = t("shared.authorization.not_authorized")
      redirect_to root_path
    else
      flash[:alert] = t("shared.authorization.unauthenticated")
      redirect_to login_path
    end
  end

  def set_owned_article
    @article = current_owner.articles.find_by(id: params[:id])
    return if @article

    flash[:alert] = t("shared.authorization.not_authorized")
    redirect_to articles_path
  end
end
