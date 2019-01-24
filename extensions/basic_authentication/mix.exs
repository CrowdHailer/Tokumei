defmodule BasicAuthentication.MixProject do
  use Mix.Project

  def project do
    [
      app: :basic_authentication,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:raxx, github: "crowdhailer/raxx", branch: "release-1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
