using Test
using PkgTemplatesShikiPlugin
using PkgTemplates

# Import specific types to avoid ambiguity
using PkgTemplatesShikiPlugin: NoDeploy

@testset "PkgTemplatesShikiPlugin.jl" begin
    @testset "Plugin Instantiation" begin
        # Test default constructor
        p1 = DocumenterShiki()
        @test p1 isa DocumenterShiki{PkgTemplatesShikiPlugin.NoDeploy}
        @test p1.theme == "github-light"
        @test p1.dark_theme == "github-dark"
        @test p1.languages == ["julia", "javascript", "python", "bash", "json", "yaml", "toml"]
        @test p1.cdn_url == "https://esm.sh"

        # Test explicit type parameter
        p2 = DocumenterShiki{PkgTemplates.GitHubActions}()
        @test p2 isa DocumenterShiki{PkgTemplates.GitHubActions}

        # Test with custom options
        p3 = DocumenterShiki(theme="catppuccin-mocha", dark_theme="catppuccin-latte")
        @test p3.theme == "catppuccin-mocha"
        @test p3.dark_theme == "catppuccin-latte"

        # Test with custom languages
        p4 = DocumenterShiki(languages=["julia", "rust", "python"])
        @test p4.languages == ["julia", "rust", "python"]
    end

    @testset "Validation - Documenter Conflict" begin
        # Test that having both Documenter and DocumenterShiki throws error
        # Note: validation happens during Template construction
        @test_throws ArgumentError Template(;
            dir=mktempdir(),
            user="TestUser",
            plugins=[
                PkgTemplates.Documenter{PkgTemplates.GitHubActions}(),
                DocumenterShiki{PkgTemplates.GitHubActions}(),
            ]
        )
    end

    @testset "Validation - Missing CI Plugin" begin
        # Test GitHubActions requirement (explicitly remove GitHubActions from defaults)
        @test_throws ArgumentError Template(;
            dir=mktempdir(),
            user="TestUser",
            plugins=[
                !PkgTemplates.GitHubActions,
                DocumenterShiki{PkgTemplates.GitHubActions}()
            ]
        )

        # Test TravisCI requirement
        @test_throws ArgumentError Template(;
            dir=mktempdir(),
            user="TestUser",
            plugins=[
                DocumenterShiki{PkgTemplates.TravisCI}()
            ]
        )

        # Test GitLabCI requirement
        @test_throws ArgumentError Template(;
            dir=mktempdir(),
            user="TestUser",
            plugins=[
                DocumenterShiki{PkgTemplates.GitLabCI}()
            ]
        )
    end

    @testset "Validation - Valid Configurations" begin
        # NoDeploy should not require CI plugin
        t1 = Template(;
            dir=mktempdir(),
            user="TestUser",
            plugins=[DocumenterShiki()]
        )
        p1 = DocumenterShiki()
        @test PkgTemplates.validate(p1, t1) === nothing

        # GitHubActions with required CI plugin should be valid
        t2 = Template(;
            dir=mktempdir(),
            user="TestUser",
            plugins=[
                PkgTemplates.GitHubActions(),
                DocumenterShiki{PkgTemplates.GitHubActions}()
            ]
        )
        p2 = DocumenterShiki{PkgTemplates.GitHubActions}()
        @test PkgTemplates.validate(p2, t2) === nothing
    end

    @testset "Badges" begin
        # NoDeploy should return empty badges
        p1 = DocumenterShiki()
        @test PkgTemplates.badges(p1) == []

        # GitHubActions should return 2 badges (Stable and Dev)
        p2 = DocumenterShiki{PkgTemplates.GitHubActions}()
        badges2 = PkgTemplates.badges(p2)
        @test length(badges2) == 2
        @test badges2[1] isa PkgTemplates.Badge
        @test badges2[2] isa PkgTemplates.Badge

        # TravisCI should also return 2 badges
        p3 = DocumenterShiki{PkgTemplates.TravisCI}()
        badges3 = PkgTemplates.badges(p3)
        @test length(badges3) == 2

        # GitLabCI should return 1 badge
        p4 = DocumenterShiki{PkgTemplates.GitLabCI}()
        badges4 = PkgTemplates.badges(p4)
        @test badges4 isa PkgTemplates.Badge
    end

    @testset "View Variables" begin
        t = Template(;
            dir=mktempdir(),
            user="TestUser",
            authors=["Test Author"],
            plugins=[DocumenterShiki()]
        )
        p = DocumenterShiki(theme="github-dark", dark_theme="github-light")

        vars = PkgTemplates.view(p, t, "TestPkg")

        # Check standard variables
        @test vars["PKG"] == "TestPkg"
        @test vars["AUTHORS"] == "Test Author"
        @test haskey(vars, "REPO")
        @test haskey(vars, "DEVBRANCH")

        # Check Shiki-specific variables
        @test vars["SHIKI_THEME"] == "github-dark"
        @test vars["SHIKI_DARK_THEME"] == "github-light"
        @test vars["SHIKI_CDN_URL"] == "https://esm.sh"
        @test haskey(vars, "SHIKI_LANGUAGES")

        # Check deployment flag
        @test vars["HAS_DEPLOY"] == false
    end

    @testset "File Generation" begin
        mktempdir() do dir
            t = Template(;
                dir=dir,
                user="TestUser",
                authors=["Test Author"],
                plugins=[DocumenterShiki()]
            )

            # Generate a test package
            PkgTemplates.generate("TestPkg", t)

            pkg_dir = joinpath(dir, "TestPkg")

            # Check that package directory was created
            @test isdir(pkg_dir)

            # Check generated documentation files
            @test isfile(joinpath(pkg_dir, "docs", "ShikiHighlighter.jl"))
            @test isfile(joinpath(pkg_dir, "docs", "make.jl"))
            @test isfile(joinpath(pkg_dir, "docs", "src", "index.md"))

            # Check Node.js files
            @test isfile(joinpath(pkg_dir, "package.json"))
            @test isfile(joinpath(pkg_dir, "build-shiki.js"))

            # Verify make.jl contains expected content
            make_content = read(joinpath(pkg_dir, "docs", "make.jl"), String)
            @test occursin("using Documenter", make_content)
            @test occursin("ShikiHighlighter", make_content)
            @test occursin("TestPkg", make_content)

            # Verify ShikiHighlighter.jl contains expected content
            shiki_content = read(joinpath(pkg_dir, "docs", "ShikiHighlighter.jl"), String)
            @test occursin("module ShikiHighlighter", shiki_content)
            @test occursin("shiki_html", shiki_content)
            @test occursin("github-light", shiki_content)

            # Verify index.md contains package name
            index_content = read(joinpath(pkg_dir, "docs", "src", "index.md"), String)
            @test occursin("# TestPkg", index_content)

            # Verify package.json is valid JSON-like
            pkg_json = read(joinpath(pkg_dir, "package.json"), String)
            @test occursin("documenter-shiki", pkg_json)
            @test occursin("shiki", pkg_json)
        end
    end
end
