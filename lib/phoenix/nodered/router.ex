defmodule Phoenix.NodeRed.Router do
  defmacro nodered(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      scoped_path =
        Phoenix.Router.scoped_path(__MODULE__, path)
        |> IO.inspect(label: "Path")

      pipeline :static do
        plug(Plug.Static,
          at: "/#{path}",
          from: {:phoenix_nodered, "priv/static/assets/node-red/public"},
          gzip: false
        )
      end

      scope path, alias: false, as: false do
        # TODO: only import function which are needed
        import Phoenix.Router

        pipe_through(:static)

        get("/", Phoenix.NodeRedWeb.NodeRedController, :home)
        get("/comms", Phoenix.WebsocketUpgrade, Phoenix.NodeRedWeb.CommsSocket)

        # get "/auth/login", Phoenix.NodeRedController, :login
        # post /auth/token", Phoenix.NodeRedController :credeitnals
        # post /auth/revoke, Phoenix.NodeRedController, :revoke
        get("/settings", Phoenix.NodeRedWeb.NodeRedController, :settings)
        get("/diagnostics", Phoenix.NodeRedWeb.NodeRedController, :diagnostics)
        get("/flows", Phoenix.NodeRedWeb.NodeRedController, :flows)
        get("/flows/state", Phoenix.NodeRedWeb.NodeRedController, :flows_state)
        post("/flows", Phoenix.NodeRedWeb.NodeRedController, :new_flow)
        post("/flows/state", Phoenix.NodeRedWeb.NodeRedController, :set_runtime_state)
        post("/flow", Phoenix.NodeRedWeb.NodeRedController, :add_flow)
        get("/flow/:id", Phoenix.NodeRedWeb.NodeRedController, :get_flow)
        put("/flow/:id", Phoenix.NodeRedWeb.NodeRedController, :update_flow)
        delete("/flow/:id", Phoenix.NodeRedWeb.NodeRedController, :delete_flow)
        get("/nodes", Phoenix.NodeRedWeb.NodeRedController, :nodes)
        post("/nodes", Phoenix.NodeRedWeb.NodeRedController, :new_nodes)
        get("/nodes/messages", Phoenix.NodeRedWeb.NodeRedController, :messages)
        get("/nodes/:module", Phoenix.NodeRedWeb.NodeRedController, :get_node_module)
        put("/nodes/:module", Phoenix.NodeRedWeb.NodeRedController, :set_node_module)
        delete("/nodes/:module", Phoenix.NodeRedWeb.NodeRedController, :remove_node_module)
        get("/nodes/:module/:set", Phoenix.NodeRedWeb.NodeRedController, :get_node_set)
        put("/nodes/:module/:set", Phoenix.NodeRedWeb.NodeRedController, :set_node_set)

        get("/locales/:file", Phoenix.NodeRedWeb.NodeRedController, :locales)
        get("/theme", Phoenix.NodeRedWeb.NodeRedController, :theme)
        get("/settings", Phoenix.NodeRedWeb.NodeRedController, :settings)
        get("/settings/user", Phoenix.NodeRedWeb.NodeRedController, :user)
        post("/settings/user", Phoenix.NodeRedWeb.NodeRedController, :new_user)
        get("/plugins", Phoenix.NodeRedWeb.NodeRedController, :plugins)
        get("/plugins/messages", Phoenix.NodeRedWeb.NodeRedController, :messages)
        get("/nodes", Phoenix.NodeRedWeb.NodeRedController, :nodes)
        get("/icons", Phoenix.NodeRedWeb.NodeRedController, :icons)

        match(:*, "/*path", Phoenix.NodeRedWeb.ErrorController, :notfound)
      end
    end
  end
end
