defmodule ChoiceContext.MixProject do
  use Mix.Project

  def project do
    [
      app: :choice_context,
      version: "0.1.5",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "ChoiceContext"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp description do
    """
    This is a GenServer-ish implementation of a Choice Context.
    That is a process that accepts a value during the specified period of time and refuses to do so after the timeout has elapsed.
    """
  end

  defp package do
    [
      name: "choice_context",
      maintainers: ["Dmitry A. Pyatkov"],
      licenses: ["Apache 2.0"],
      files: ["lib", "mix.exs"],
      links: %{"HexDocs.pm" => "https://hexdocs.pm"}
    ]
  end
end
