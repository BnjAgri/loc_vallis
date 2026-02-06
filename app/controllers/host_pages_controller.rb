class HostPagesController < ApplicationController
  before_action :require_owner!, only: %i[edit update]

  DEFAULT_IMAGE_URL = "https://static.mediapart.fr/etmagine/article_google_discover/files/2024/10/14/portrait-de-ric-zemmour-avril-2022.jpg".freeze

  def show
    @host_page = HostPage.first
  end

  def edit
    @host_page = HostPage.first || build_default_host_page
  end

  def update
    @host_page = HostPage.first || HostPage.new

    if @host_page.update(host_page_params)
      redirect_to host_path, notice: t("host_page.update.success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def host_page_params
    params.require(:host_page).permit(:title, :content, :image_url, :image)
  end

  def build_default_host_page
    HostPage.new(
      title: t("pages.host.title"),
      content: [
        t("pages.host.body.p1"),
        t("pages.host.body.p2"),
        t("pages.host.body.p3"),
        t("pages.host.body.p4")
      ].join("\n\n"),
      image_url: DEFAULT_IMAGE_URL
    )
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
end
