defmodule Web.Router do
  use Web, :router

  @report_errors Keyword.get(Application.compile_env(:ex_venture, :errors, []), :report)

  if @report_errors do
    use Plug.ErrorHandler
    use Sentry.Plug
  end

  pipeline :accepts_browser do
    plug(:accepts, ["html", "json"])
  end

  pipeline :accepts_api do
    plug(:accepts, ["html", "json", "hal", "siren", "collection", "mason", "jsonapi"])
  end

  pipeline :browser do
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :public do
    plug(Web.Plug.LoadUser)
    plug(Web.Plug.LoadCharacter)
  end

  pipeline :public_2fa do
    plug(Web.Plug.LoadUser, verify: false)
    plug(Web.Plug.LoadCharacter)
  end

  scope "/", Web, as: :public do
    pipe_through([:accepts_browser, :browser, :public_2fa])

    get("/account/twofactor/verify", AccountTwoFactorController, :verify)
    post("/account/twofactor/verify", AccountTwoFactorController, :verify_token)
  end

  scope "/", Web, as: :public do
    pipe_through([:accepts_api, :browser, :public])

    get("/", PageController, :index)

    resources("/classes", ClassController, only: [:index, :show])
    resources("/races", RaceController, only: [:index, :show])
    resources("/skills", SkillController, only: [:index, :show])
    resources("/who", WhoController, only: [:index])
  end

  # Public Routes: manifest.json, css, mudlet_package, etc.
  scope "/", Web, as: :public do
    pipe_through([:accepts_browser, :browser, :public])

    get("/manifest.json", PageController, :manifest)
    get("/css/colors.css", ColorController, :index)
    get("/clients/mudlet/ex_venture.xml", PageController, :mudlet_package)
    get("/clients/map.xml", PageController, :map)

    get("/version", PageController, :version)

    get("/account", AccountController, :show)
    put("/account", AccountController, :update)

    resources("/account/characters", CharacterController, only: [:new, :create])
    post("/account/characters/swap", CharacterController, :swap)

    get("/account/twofactor/start", AccountTwoFactorController, :start)
    get("/account/twofactor/qr.png", AccountTwoFactorController, :qr)
    post("/account/twofactor", AccountTwoFactorController, :validate)
    delete("/account/twofactor", AccountTwoFactorController, :clear)

    resources("/account/mail", MailController, only: [:index, :show, :new, :create])

    get("/announcements/atom", AnnouncementController, :feed)
    resources("/announcements", AnnouncementController, only: [:show])

    get("/chat", ChatController, :show)
    get("/connection/authorize", ConnectionController, :authorize)
    post("/connection/authorize", ConnectionController, :connect)

    get("/help/commands", HelpController, :commands)
    get("/help/commands/:command", HelpController, :command)
    resources("/help", HelpController, only: [:index, :show])

    get("/play", PlayController, :show)

    if Mix.env() == :dev do
      get("/play-react", PlayController, :show_react)
    end

    get("/register/reset", RegistrationResetController, :new)
    post("/register/reset", RegistrationResetController, :create)

    get("/register/reset/verify", RegistrationResetController, :edit)
    post("/register/reset/verify", RegistrationResetController, :update)

    resources("/register", RegistrationController, only: [:new, :create])
    get("/register/finalize", RegistrationController, :finalize)
    post("/register/finalize", RegistrationController, :update)

    delete("/sessions", SessionController, :delete)
    resources("/sessions", SessionController, only: [:new, :create])

    get("/auth/:provider", AuthController, :request)
    get("/auth/:provider/callback", AuthController, :callback)
    post("/auth/:provider/callback", AuthController, :callback)
  end

  # Admin Routes
  scope "/admin", Web.Admin do
    pipe_through([:accepts_browser, :browser])

    get("/", DashboardController, :index)

    resources("/announcements", AnnouncementController, except: [:delete])

    resources("/bugs", BugController, only: [:index, :show]) do
      post("/complete", BugController, :complete, as: :complete)
    end

    resources("/channels", ChannelController, except: [:delete])

    resources("/classes", ClassController,
      only: [:index, :show, :new, :create, :edit, :update]
    ) do
      resources("/proficiencies", ClassProficiencyController,
        only: [:new, :create],
        as: :proficiency
      )

      resources("/skills", ClassSkillController, only: [:new, :create], as: :skill)
    end

    # Example: Replaced Routes helpers with Verified Routes
    get("/rooms/:id/overworld/exits", ZoneOverworldController, :exits)
    post("/rooms/:id/overworld/exits", ZoneOverworldController, :create_exit)
    delete("/rooms/:id/overworld/exits/:exit_id", ZoneOverworldController, :delete_exit)
  end

  # If in dev, forward emails
  if Mix.env() == :dev do
    forward("/emails/sent", Bamboo.SentEmailViewerPlug)
  end
end
