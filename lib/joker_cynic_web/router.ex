defmodule JokerCynicWeb.Router do
  use JokerCynicWeb, :router

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

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; script-src-elem 'self'; connect-src 'self'; img-src 'self' data: blob:; frame-src 'self';"
    }
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

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", JokerCynicWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", JokerCynicWeb do
  #   pipe_through :api
  # end

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
