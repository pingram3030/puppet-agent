component "cpp-hocon" do |pkg, settings, platform|
  pkg.load_from_json('configs/components/cpp-hocon.json')

  pkg.build_requires('leatherman')

  make = platform[:make]
  boost_static_flag = ""

  # cmake on OSX is provided by brew
  # a toolchain is not currently required for OSX since we're building with clang.
  if platform.is_macos?
    toolchain = ""
    cmake = "/usr/local/bin/cmake"
    boost_static_flag = "-DBOOST_STATIC=OFF"
    if platform.name =~ /osx-10.14/ #apple's clang 10 complains about delete-non-virtual-destructor
      special_flags = "-DCMAKE_CXX_FLAGS='#{settings[:cflags]} -Wno-delete-non-virtual-dtor'"
    else
      special_flags = "-DCMAKE_CXX_FLAGS='#{settings[:cflags]}'"
    end
  elsif platform.is_cross_compiled_linux?
    toolchain = "-DCMAKE_TOOLCHAIN_FILE=/opt/pl-build-tools/#{settings[:platform_triple]}/pl-build-toolchain.cmake"
    cmake = "/opt/pl-build-tools/bin/cmake"
  elsif platform.is_solaris?
    toolchain = "-DCMAKE_TOOLCHAIN_FILE=/opt/pl-build-tools/#{settings[:platform_triple]}/pl-build-toolchain.cmake"
    cmake = "/opt/pl-build-tools/i386-pc-solaris2.#{platform.os_version}/bin/cmake"

    # FACT-1156: If we build with -O3, solaris segfaults due to something in std::vector
    special_flags = "-DCMAKE_CXX_FLAGS_RELEASE='-O2 -DNDEBUG'"
  elsif platform.is_windows?
    make = "#{settings[:gcc_bindir]}/mingw32-make"
    pkg.environment "PATH", "$(shell cygpath -u #{settings[:prefix]}/lib):$(shell cygpath -u #{settings[:gcc_bindir]}):$(shell cygpath -u #{settings[:bindir]}):/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0"
    pkg.environment "CYGWIN", settings[:cygwin]

    cmake = "C:/ProgramData/chocolatey/bin/cmake.exe -G \"MinGW Makefiles\""
    toolchain = "-DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/pl-build-toolchain.cmake"
  elsif platform.name =~ /sles-15|fedora-29|el-8|debian-10/
    # These platforms use the default OS toolchain, rather than pl-build-tools
    cmake = "cmake"
    toolchain = ""
    boost_static_flag = "-DBOOST_STATIC=OFF"
    special_flags = "-DCMAKE_CXX_FLAGS='-Wno-error=address -Wno-error=nonnull-compare'" if platform.name =~ /fedora-29|debian-10/
    special_flags = " -DENABLE_CXX_WERROR=OFF " if platform.name =~ /el-8|fedora-29|debian-10/
  else
    toolchain = "-DCMAKE_TOOLCHAIN_FILE=/opt/pl-build-tools/pl-build-toolchain.cmake"
    cmake = "/opt/pl-build-tools/bin/cmake"

    if platform.is_cisco_wrlinux?
      special_flags = "-DLEATHERMAN_USE_LOCALES=OFF"
    end
  end

  # Until we build our own gettext packages, disable using locales.
  # gettext 0.17 is required to compile .mo files with msgctxt.
  pkg.configure do
    ["#{cmake} \
        #{toolchain} \
        -DCMAKE_VERBOSE_MAKEFILE=ON \
        -DCMAKE_PREFIX_PATH=#{settings[:prefix]} \
        -DCMAKE_INSTALL_PREFIX=#{settings[:prefix]} \
        #{special_flags} \
        #{boost_static_flag} \
        ."]
  end

  # Make test will explode horribly in a cross-compile situation
  # Tests will be skipped on AIX until they are expected to pass
  if platform.is_cross_compiled? || platform.is_aix?
    test = "/bin/true"
  else
    test = "#{make} test ARGS=-V"
  end

  if platform.is_solaris? && platform.architecture != 'sparc'
    test = "LANG=C LC_ALL=C #{test}"
  end

  pkg.build do
    # Until a `check` target exists, run tests are part of the build.
    [
      "#{make} -j$(shell expr $(shell #{platform[:num_cores]}) + 1)",
      "#{test}"
    ]
  end

  pkg.install do
    ["#{make} -j$(shell expr $(shell #{platform[:num_cores]}) + 1) install"]
  end
end
