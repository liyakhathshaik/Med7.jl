using Documenter, Med7

makedocs(
    sitename = "MediSeven.jl",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", "false") == "true"),
    modules = [Med7],
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
        "Examples" => "examples.md",
        "Developer Guide" => "devguide.md"
    ]
)

deploydocs(
    repo = "github.com/YOUR_GITHUB_USERNAME/MediSeven.jl.git",
    devbranch = "main"
)