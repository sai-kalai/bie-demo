using Pkg

const ROOT = normpath(joinpath(@__DIR__, ".."))
const BUILD_PROJECT = joinpath(ROOT, "build")
const SYSIMAGE_PATH = joinpath(ROOT, "DemoWebsiteSysimage.so")

# Activate the isolated build environment containing PackageCompiler.
Pkg.activate(BUILD_PROJECT)
Pkg.instantiate()

using PackageCompiler

@info "Building DemoWebsite sysimage" project=ROOT output=SYSIMAGE_PATH

PackageCompiler.create_sysimage(
    :DemoWebsite;
    project=ROOT,
    sysimage_path=SYSIMAGE_PATH,
    cpu_target="generic",
)

@info "Sysimage build completed" output=SYSIMAGE_PATH
