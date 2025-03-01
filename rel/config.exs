# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Distillery.Releases.Config,
  # This sets the default release built by `mix distillery.release`
  default_release: :default,
  # This sets the default environment used by `mix distillery.release`
  default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html

# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment Mix.env() do
  set include_erts: true
  set include_src: false
  set vm_args: "rel/vm.args"
  set pre_configure_hooks: "rel/pre_configure"

  set config_providers: [
    {Distillery.Releases.Config.Providers.Elixir, ["${REL_DIR}/runtime_config.exs"]}
  ]

  set overlays: [
    {:copy, "config/#{Mix.env()}.exs", "releases/<%= release_version %>/runtime_config.exs"},
  ]

  set commands: [
    regression_test: "rel/commands/regression_test",
    validate: "rel/commands/validate"
  ]

  plugin Distillery.Releases.Plugin.CookieLoader
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix distillery.release`, the first release in the file
# will be used by default

release :archethic_node do
  set version: current_version(:archethic)

  set applications: [
    :runtime_tools,
    :observer_cli,
    archethic: :permanent
  ]

  set appup_transforms: [
    {Archethic.Release.TransformPurge, []},
    {Archethic.Release.RestartTelemetry, []},
    {Archethic.Release.CallMigrateScript, []}
  ]
end
