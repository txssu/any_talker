defmodule JokerCynicWeb.Router do
  use JokerCynicWeb, :router

  import JokerCynicWeb.AuthPlug

  alias JokerCynicWeb.CSPNoncePlug

  @nonce 10
         |> :crypto.strong_rand_bytes()
         |> Base.url_encode64(padding: false)

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JokerCynicWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :fetch_current_user

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; script-src-elem 'self' https://telegram.org; connect-src 'self'; img-src 'self' data: blob: https://t.me; style-src 'self' https://fonts.googleapis.com; font-src https://fonts.gstatic.com;"
    }
  end

  pipeline :webapp do
    plug :put_root_layout, html: :webapp
  end

  pipeline :dev_dashboard do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug CSPNoncePlug, nonce: @nonce
    plug :put_secure_browser_headers, %{"content-security-policy" => "style-src 'self' 'nonce-#{@nonce}'"}
  end

  pipeline :mailbox do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers, %{"content-security-policy" => "style-src 'unsafe-inline'"}
  end

  scope "/", JokerCynicWeb do
    pipe_through :browser

    get "/log_in/via_webapp", AuthController, :via_webapp
  end

  scope "/", JokerCynicWeb do
    pipe_through [:browser, :webapp, :redirect_if_user_is_authenticated]

    get "/webapp/log_in", AuthController, :webapp
  end

  scope "/webapp", JokerCynicWeb.WebApp do
    pipe_through [:browser, :webapp, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{JokerCynicWeb.AuthPlug, :ensure_authenticated}] do
      live "/", MenuLive
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:joker_cynic, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev/dashboard" do
      pipe_through :dev_dashboard
      live_dashboard "/", metrics: JokerCynicWeb.Telemetry, csp_nonce_assign_key: :csp_nonce
    end

    scope "/dev/mailbox" do
      pipe_through :mailbox
      forward "/", Plug.Swoosh.MailboxPreview
    end
  end
end
