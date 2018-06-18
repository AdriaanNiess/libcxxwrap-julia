using BinaryBuilder

# Collection of sources required to build Ogg
sources = [
    "JuliaInterop"
]

# Bash recipe for building across all platforms
function getscript(version)
    shortversion = version[1:3]
    return """
    Julia_ROOT=/usr/local

    apk add p7zip

    # Download julia
    cd /usr/local
    if [ "\$target" = "x86_64-linux-gnu" ]; then
        curl -L 'https://julialang-s3.julialang.org/bin/linux/x64/$shortversion/julia-$version-linux-x86_64.tar.gz' | tar -zx --strip-components=1
    elif [ "\$target" = "i686-linux-gnu" ]; then
        curl -L 'https://julialang-s3.julialang.org/bin/linux/x86/$shortversion/julia-$version-linux-i686.tar.gz' | tar -zx --strip-components=1
    elif [ "\$target" = "aarch64-linux-gnu" ]; then
        curl -L 'https://julialang-s3.julialang.org/bin/linux/aarch64/$shortversion/julia-$version-linux-aarch64.tar.gz' | tar -zx --strip-components=1
    elif [ "\$target" == "x86_64-apple-darwin14" ]; then
        curl -L -o julia.dmg 'https://julialang-s3.julialang.org/bin/mac/x64/$shortversion/julia-$version-mac64.dmg'
        7z x julia.dmg
        Julia_ROOT=\$(ls -d \$PWD/Julia-*/Julia*.app/Contents/Resources/julia)
    elif [ "\$target" = "x86_64-w64-mingw32" ]; then
        curl -L -o julia.exe 'https://julialang-s3.julialang.org/bin/winnt/x64/$shortversion/julia-$version-win64.exe'
    elif [ "\$target" = "i686-w64-mingw32" ]; then
        curl -L -o julia.exe 'https://julialang-s3.julialang.org/bin/winnt/x86/$shortversion/julia-$version-win32.exe'
    fi

    if [ \$target = "x86_64-w64-mingw32" ] || [ \$target = "i686-w64-mingw32" ]; then
        7z x julia.exe
        7z x julia-installer.exe
    fi

    # Build libcxxwrap
    cd \$WORKSPACE/srcdir/libcxxwrap-julia*
    mkdir build && cd build
    cmake -DJulia_ROOT=\$Julia_ROOT -DCMAKE_TOOLCHAIN_FILE=/opt/\$target/\$target.toolchain -DCMAKE_INSTALL_PREFIX=\${prefix} ..
    VERBOSE=ON cmake --build . --config Release --target install
    if [[ "\$target" == "x86_64-linux-gnu" ]]; then
        ctest -V
    fi
    """
end

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms06 = [
    Linux(:x86_64),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

platforms07 = [
    Linux(:x86_64)
]

# The products that we will ensure are always built
products = prefix -> [
    LibraryProduct(prefix, "libcxxwrap", :libcxxwrap),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
println("0.6 products:")
download_info_06 = build_tarballs(ARGS, "libcxxwrap-julia-0.6", sources, getscript("0.6.3"), platforms06, products, dependencies)
@show download_info_06
download_info_07 = build_tarballs(ARGS, "libcxxwrap-julia-0.7", sources, getscript("0.7.0-alpha"), platforms07, products, dependencies)
@show download_info_07
